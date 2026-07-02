import SwiftUI

struct LMDigestPostScreen: View {
    @Environment(\.openURL) private var openURL
    @State private var viewModel: LMDigestPostViewModel

    init(articleTitle: String, sourceURL: URL) {
        _viewModel = State(
            initialValue: LMDigestPostViewModel(
                articleTitle: articleTitle,
                sourceURL: sourceURL
            )
        )
    }

    var body: some View {
        ZStack {
            content

            if viewModel.isLoading {
                ProgressView()
                    .padding(14)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .navigationTitle(viewModel.articleTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var content: some View {
        if let errorMessage = viewModel.errorMessage {
            ContentUnavailableView(
                "Unable to Load Post",
                systemImage: "exclamationmark.triangle",
                description: Text(errorMessage)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.background)
        } else if let freediumURL = viewModel.freediumURL {
            LMDigestPostWebView(
                url: freediumURL,
                onStartLoading: viewModel.webViewDidStartLoading,
                onFinishLoading: viewModel.webViewDidFinishLoading,
                onFailLoading: viewModel.webViewDidFailLoading,
                onOpenExternalURL: { url in
                    openURL(url)
                }
            )
        } else {
            ContentUnavailableView(
                "No Content",
                systemImage: "doc.text",
                description: Text("Freedium URL could not be created.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
