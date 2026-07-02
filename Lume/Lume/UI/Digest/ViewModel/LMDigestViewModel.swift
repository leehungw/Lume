import Factory
import Foundation
import Observation

@Observable
@MainActor
final class LMDigestViewModel: Loggable {
    @ObservationIgnored private let oauthService: LMGmailOAuthService
    @ObservationIgnored private let gmailDigestService: LMGmailDigestService

    private(set) var isConnected = false
    private(set) var isConnecting = false
    private(set) var isFetchingDigest = false
    private(set) var statusMessage = "Connect Gmail so Lume can import Medium daily digests from this device."
    private(set) var errorMessage: String?
    private(set) var digestEmails: [LMMediumDigestEmail] = []

    var connectionActionTitle: String {
        isConnected ? "Reconnect Gmail" : "Connect Gmail"
    }

    var articleCount: Int {
        digestEmails.reduce(0) { $0 + $1.articleLinks.count }
    }

    var isBusy: Bool {
        isConnecting || isFetchingDigest
    }

    init(
        oauthService: LMGmailOAuthService = Container.shared.gmailOAuthService(),
        gmailDigestService: LMGmailDigestService = Container.shared.gmailDigestService()
    ) {
        self.oauthService = oauthService
        self.gmailDigestService = gmailDigestService
    }

    func load() {
        do {
            let credential = try oauthService.storedCredential()
            errorMessage = nil
            updateConnectionState(isConnected: credential != nil)
        } catch {
            errorMessage = readableMessage(for: error)
            logError("Failed to load Gmail OAuth credential: \(error.localizedDescription)")
        }
    }

    func connectGmail() async {
        guard isBusy == false else { return }

        isConnecting = true
        errorMessage = nil

        do {
            _ = try await oauthService.signIn()
            updateConnectionState(isConnected: true)
        } catch {
            errorMessage = readableMessage(for: error)
            logError("Gmail OAuth sign-in failed: \(error.localizedDescription)")
        }

        isConnecting = false
    }

    func disconnectGmail() {
        do {
            try oauthService.signOut()
            digestEmails = []
            errorMessage = nil
            updateConnectionState(isConnected: false)
        } catch {
            errorMessage = readableMessage(for: error)
            logError("Failed to disconnect Gmail OAuth credential: \(error.localizedDescription)")
        }
    }

    func fetchMediumDigest() async {
        guard isBusy == false else { return }

        isFetchingDigest = true
        errorMessage = nil

        do {
            guard let credential = try await oauthService.validCredential() else {
                throw LMGmailServiceError.notConnected
            }

            digestEmails = try await gmailDigestService.fetchMediumDigest(accessToken: credential.accessToken)
            updateDigestStatus()
        } catch {
            errorMessage = readableMessage(for: error)
            logError("Failed to fetch Medium digest from Gmail: \(error.localizedDescription)")
        }

        isFetchingDigest = false
    }

    private func updateConnectionState(isConnected: Bool) {
        self.isConnected = isConnected
        statusMessage = isConnected
            ? "Gmail is connected. Lume can use it to check for Medium digests."
            : "Connect Gmail so Lume can import Medium daily digests from this device."
    }

    private func updateDigestStatus() {
        if digestEmails.isEmpty {
            statusMessage = "No Medium digest email was found in Gmail from the last 14 days."
        } else {
            statusMessage = "Found \(articleCount) Medium link(s) from \(digestEmails.count) digest email(s)."
        }
    }

    private func readableMessage(for error: Error) -> String {
        if let localizedError = error as? LocalizedError,
           let errorDescription = localizedError.errorDescription {
            return errorDescription
        }

        return error.localizedDescription
    }
}
