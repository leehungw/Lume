import Foundation

struct LMGoogleOAuthConfiguration {
    let clientID: String
    let redirectScheme: String
    let redirectURI: String
    let scopes: [String]

    static func load() throws -> LMGoogleOAuthConfiguration {
        let clientID = Bundle.main.lmRequiredOAuthValue(for: "LMGoogleOAuthClientID")
        let redirectScheme = Bundle.main.lmRequiredOAuthValue(for: "LMGoogleOAuthRedirectScheme")

        guard let clientID, let redirectScheme else {
            throw LMGoogleOAuthError.missingConfiguration
        }

        return LMGoogleOAuthConfiguration(
            clientID: clientID,
            redirectScheme: redirectScheme,
            redirectURI: "\(redirectScheme):/oauth2redirect",
            scopes: [
                "openid",
                "email",
                "https://www.googleapis.com/auth/gmail.readonly"
            ]
        )
    }
}

private extension Bundle {
    func lmRequiredOAuthValue(for key: String) -> String? {
        guard let value = object(forInfoDictionaryKey: key) as? String else { return nil }
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedValue.isEmpty == false else { return nil }
        guard trimmedValue.localizedCaseInsensitiveContains("placeholder") == false else { return nil }
        guard trimmedValue.contains("$(") == false else { return nil }

        return trimmedValue
    }
}
