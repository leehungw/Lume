import Foundation
import Security

enum LMGoogleOAuthError: Error, LocalizedError {
    case missingConfiguration
    case invalidAuthorizationURL
    case invalidCallbackURL
    case authorizationFailed(String)
    case authorizationStateMismatch
    case missingAuthorizationCode
    case missingRefreshToken
    case invalidTokenResponse
    case keychainFailure(OSStatus)
    case randomGenerationFailed

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            "Add your Google OAuth client ID and reversed URL scheme to the app build settings."
        case .invalidAuthorizationURL:
            "Unable to build the Google authorization URL."
        case .invalidCallbackURL:
            "Google returned an invalid authorization callback."
        case .authorizationFailed(let message):
            message
        case .authorizationStateMismatch:
            "The Google authorization response did not match this login request."
        case .missingAuthorizationCode:
            "Google did not return an authorization code."
        case .missingRefreshToken:
            "Gmail access needs a refresh token. Please connect Gmail again."
        case .invalidTokenResponse:
            "Google returned an invalid token response."
        case .keychainFailure(let status):
            "Keychain operation failed with status \(status)."
        case .randomGenerationFailed:
            "Unable to generate secure OAuth values."
        }
    }
}
