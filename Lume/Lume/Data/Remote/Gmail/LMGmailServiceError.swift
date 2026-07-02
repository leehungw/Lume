import Foundation

enum LMGmailServiceError: Error, LocalizedError {
    case notConnected
    case invalidURL
    case invalidResponse
    case requestFailed(Int, String)

    var errorDescription: String? {
        switch self {
        case .notConnected:
            "Connect Gmail before fetching your Medium digest."
        case .invalidURL:
            "Unable to build the Gmail request."
        case .invalidResponse:
            "Gmail returned an invalid response."
        case .requestFailed(let statusCode, let message):
            "Gmail request failed (\(statusCode)): \(message)"
        }
    }
}
