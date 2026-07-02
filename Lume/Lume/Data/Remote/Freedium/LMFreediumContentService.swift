import Foundation

final class LMFreediumContentService {
    func makeFreediumURL(for sourceURL: URL) throws -> URL {
        let base = AppConst.FREEDIUM_LINK.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let value = "\(base)/\(sourceURL.absoluteString)"

        guard let url = URL(string: value) else {
            throw LMFreediumServiceError.invalidURL
        }

        return url
    }
}
