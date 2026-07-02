import Foundation

enum LMFreediumServiceError: Error, LocalizedError {
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Unable to build the Freedium URL."
        }
    }
}
