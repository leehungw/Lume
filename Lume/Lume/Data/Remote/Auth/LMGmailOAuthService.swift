import AuthenticationServices
import CryptoKit
import Foundation
import UIKit

@MainActor
final class LMGmailOAuthService: NSObject, ASWebAuthenticationPresentationContextProviding, Loggable {
    private let tokenStore: LMGoogleOAuthTokenStore
    private let urlSession: URLSession
    private var authenticationSession: ASWebAuthenticationSession?

    init(
        tokenStore: LMGoogleOAuthTokenStore = LMGoogleOAuthTokenStore(),
        urlSession: URLSession = .shared
    ) {
        self.tokenStore = tokenStore
        self.urlSession = urlSession
    }

    func storedCredential() throws -> LMGmailCredential? {
        try tokenStore.loadCredential()
    }

    func signIn() async throws -> LMGmailCredential {
        let configuration = try LMGoogleOAuthConfiguration.load()
        let codeVerifier = try makeSecureRandomString()
        let codeChallenge = makeCodeChallenge(for: codeVerifier)
        let state = try makeSecureRandomString()

        let callbackURL = try await requestAuthorization(
            configuration: configuration,
            codeChallenge: codeChallenge,
            state: state
        )
        let authorizationCode = try authorizationCode(from: callbackURL, expectedState: state)
        let credential = try await exchangeAuthorizationCode(
            authorizationCode,
            codeVerifier: codeVerifier,
            configuration: configuration
        )

        try tokenStore.saveCredential(credential)
        logInfo("Gmail OAuth sign-in completed")

        return credential
    }

    func validCredential() async throws -> LMGmailCredential? {
        guard let credential = try tokenStore.loadCredential() else { return nil }
        guard credential.isExpired else { return credential }
        return try await refreshCredential(credential)
    }

    func signOut() throws {
        try tokenStore.deleteCredential()
        logInfo("Gmail OAuth credential removed")
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let activeScene = scenes.first { $0.activationState == .foregroundActive }
        let windows = activeScene?.windows ?? scenes.first?.windows ?? []

        return windows.first { $0.isKeyWindow } ?? windows.first ?? ASPresentationAnchor()
    }

    private func requestAuthorization(
        configuration: LMGoogleOAuthConfiguration,
        codeChallenge: String,
        state: String
    ) async throws -> URL {
        guard let authorizationURL = makeAuthorizationURL(
            configuration: configuration,
            codeChallenge: codeChallenge,
            state: state
        ) else {
            throw LMGoogleOAuthError.invalidAuthorizationURL
        }

        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: authorizationURL,
                callbackURLScheme: configuration.redirectScheme
            ) { [weak self] callbackURL, error in
                Task { @MainActor in
                    self?.authenticationSession = nil

                    if let error {
                        continuation.resume(
                            throwing: LMGoogleOAuthError.authorizationFailed(error.localizedDescription)
                        )
                        return
                    }

                    guard let callbackURL else {
                        continuation.resume(throwing: LMGoogleOAuthError.invalidCallbackURL)
                        return
                    }

                    continuation.resume(returning: callbackURL)
                }
            }

            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            authenticationSession = session

            guard session.start() else {
                authenticationSession = nil
                continuation.resume(throwing: LMGoogleOAuthError.authorizationFailed("Unable to start Google sign-in."))
                return
            }
        }
    }

    private func makeAuthorizationURL(
        configuration: LMGoogleOAuthConfiguration,
        codeChallenge: String,
        state: String
    ) -> URL? {
        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: configuration.clientID),
            URLQueryItem(name: "redirect_uri", value: configuration.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: configuration.scopes.joined(separator: " ")),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "include_granted_scopes", value: "true"),
            URLQueryItem(name: "prompt", value: "consent")
        ]

        return components?.url
    }

    private func authorizationCode(from callbackURL: URL, expectedState: String) throws -> String {
        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false) else {
            throw LMGoogleOAuthError.invalidCallbackURL
        }

        let queryItems = components.queryItems ?? []

        if let error = queryItems.first(where: { $0.name == "error" })?.value {
            throw LMGoogleOAuthError.authorizationFailed(error)
        }

        guard queryItems.first(where: { $0.name == "state" })?.value == expectedState else {
            throw LMGoogleOAuthError.authorizationStateMismatch
        }

        guard let code = queryItems.first(where: { $0.name == "code" })?.value else {
            throw LMGoogleOAuthError.missingAuthorizationCode
        }

        return code
    }

    private func exchangeAuthorizationCode(
        _ authorizationCode: String,
        codeVerifier: String,
        configuration: LMGoogleOAuthConfiguration
    ) async throws -> LMGmailCredential {
        let body = [
            URLQueryItem(name: "client_id", value: configuration.clientID),
            URLQueryItem(name: "code", value: authorizationCode),
            URLQueryItem(name: "code_verifier", value: codeVerifier),
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "redirect_uri", value: configuration.redirectURI)
        ]

        let response = try await sendTokenRequest(body: body)
        let credential = response.makeCredential(existingRefreshToken: nil)

        guard credential.refreshToken != nil else {
            throw LMGoogleOAuthError.missingRefreshToken
        }

        return credential
    }

    private func refreshCredential(_ credential: LMGmailCredential) async throws -> LMGmailCredential {
        guard let refreshToken = credential.refreshToken else {
            throw LMGoogleOAuthError.missingRefreshToken
        }

        let configuration = try LMGoogleOAuthConfiguration.load()
        let body = [
            URLQueryItem(name: "client_id", value: configuration.clientID),
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: refreshToken)
        ]

        let response = try await sendTokenRequest(body: body)
        let refreshedCredential = response.makeCredential(
            existingRefreshToken: refreshToken,
            existingIDToken: credential.idToken
        )
        try tokenStore.saveCredential(refreshedCredential)

        return refreshedCredential
    }

    private func sendTokenRequest(body: [URLQueryItem]) async throws -> LMGoogleOAuthTokenResponse {
        guard let url = URL(string: "https://oauth2.googleapis.com/token") else {
            throw LMGoogleOAuthError.invalidTokenResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = makeFormBody(from: body)

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LMGoogleOAuthError.invalidTokenResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Google token request failed."
            throw LMGoogleOAuthError.authorizationFailed(message)
        }

        return try JSONDecoder().decode(LMGoogleOAuthTokenResponse.self, from: data)
    }

    private func makeFormBody(from queryItems: [URLQueryItem]) -> Data? {
        var components = URLComponents()
        components.queryItems = queryItems
        let query = components.percentEncodedQuery ?? ""

        return Data(query.utf8)
    }

    private func makeSecureRandomString() throws -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)

        guard status == errSecSuccess else {
            throw LMGoogleOAuthError.randomGenerationFailed
        }

        return Data(bytes).lmBase64URLEncodedString()
    }

    private func makeCodeChallenge(for codeVerifier: String) -> String {
        let data = Data(codeVerifier.utf8)
        let hash = SHA256.hash(data: data)

        return Data(hash).lmBase64URLEncodedString()
    }
}

private extension Data {
    func lmBase64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
