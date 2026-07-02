import Factory
import Foundation
import Observation

@Observable
@MainActor
final class LMDigestPostViewModel: Loggable {
    @ObservationIgnored private let contentService: LMFreediumContentService

    let articleTitle: String
    let sourceURL: URL

    private(set) var freediumURL: URL?
    private(set) var isLoading = true
    private(set) var errorMessage: String?

    init(
        articleTitle: String,
        sourceURL: URL,
        contentService: LMFreediumContentService = Container.shared.freediumContentService()
    ) {
        self.articleTitle = articleTitle
        self.sourceURL = sourceURL
        self.contentService = contentService

        configureFreediumURL()
    }

    func webViewDidStartLoading() {
        isLoading = true
        errorMessage = nil
    }

    func webViewDidFinishLoading() {
        isLoading = false
    }

    func webViewDidFailLoading(_ error: Error) {
        let nsError = error as NSError

        guard nsError.domain != NSURLErrorDomain || nsError.code != NSURLErrorCancelled else {
            return
        }

        isLoading = false
        errorMessage = readableMessage(for: error)
        logError("Failed to load Freedium page: \(error.localizedDescription)")
    }

    private func configureFreediumURL() {
        do {
            freediumURL = try contentService.makeFreediumURL(for: sourceURL)
        } catch {
            isLoading = false
            errorMessage = readableMessage(for: error)
            logError("Failed to build Freedium URL: \(error.localizedDescription)")
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
