import Foundation
import SwiftUI
import WebKit

struct LMDigestPostWebView: UIViewRepresentable {
    let url: URL
    let onStartLoading: @MainActor () -> Void
    let onFinishLoading: @MainActor () -> Void
    let onFailLoading: @MainActor (Error) -> Void
    let onOpenExternalURL: @MainActor (URL) -> Void

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        webView.scrollView.backgroundColor = .systemBackground

        context.coordinator.load(url, in: webView)

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.load(url, in: webView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            articleURL: url,
            onStartLoading: onStartLoading,
            onFinishLoading: onFinishLoading,
            onFailLoading: onFailLoading,
            onOpenExternalURL: onOpenExternalURL
        )
    }
}

extension LMDigestPostWebView {
    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        private let articleURL: URL
        private let onStartLoading: @MainActor () -> Void
        private let onFinishLoading: @MainActor () -> Void
        private let onFailLoading: @MainActor (Error) -> Void
        private let onOpenExternalURL: @MainActor (URL) -> Void
        private var currentURL: URL?

        init(
            articleURL: URL,
            onStartLoading: @escaping @MainActor () -> Void,
            onFinishLoading: @escaping @MainActor () -> Void,
            onFailLoading: @escaping @MainActor (Error) -> Void,
            onOpenExternalURL: @escaping @MainActor (URL) -> Void
        ) {
            self.articleURL = articleURL
            self.onStartLoading = onStartLoading
            self.onFinishLoading = onFinishLoading
            self.onFailLoading = onFailLoading
            self.onOpenExternalURL = onOpenExternalURL
        }

        func load(_ url: URL, in webView: WKWebView) {
            guard currentURL != url else { return }

            currentURL = url
            webView.load(URLRequest(url: url))
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let requestedURL = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }

            guard isWebURL(requestedURL) else {
                openExternalURL(requestedURL)
                decisionHandler(.cancel)
                return
            }

            if navigationAction.targetFrame == nil ||
                shouldOpenExternally(requestedURL, navigationType: navigationAction.navigationType) {
                openExternalURL(requestedURL)
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            Task { @MainActor in
                onStartLoading()
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Task { @MainActor in
                onFinishLoading()
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            failLoading(error)
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            failLoading(error)
        }

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            if let requestedURL = navigationAction.request.url {
                openExternalURL(requestedURL)
            }

            return nil
        }

        private func isWebURL(_ url: URL) -> Bool {
            guard let scheme = url.scheme?.lowercased() else { return false }

            return scheme == "http" || scheme == "https"
        }

        private func shouldOpenExternally(_ url: URL, navigationType: WKNavigationType) -> Bool {
            guard navigationType == .linkActivated else { return false }
            guard let articleHost = articleURL.host,
                  let requestedHost = url.host else {
                return true
            }

            return requestedHost != articleHost
        }

        private func openExternalURL(_ url: URL) {
            Task { @MainActor in
                onOpenExternalURL(url)
            }
        }

        private func failLoading(_ error: Error) {
            Task { @MainActor in
                onFailLoading(error)
            }
        }
    }
}
