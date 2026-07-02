import Foundation

final class LMGmailDigestService: Loggable {
    private let urlSession: URLSession

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    func fetchMediumDigest(accessToken: String) async throws -> [LMMediumDigestEmail] {
        let messageIDs = try await fetchMediumMessageIDs(accessToken: accessToken)
        var digestEmails: [LMMediumDigestEmail] = []

        for messageID in messageIDs {
            let message = try await fetchMessage(id: messageID, accessToken: accessToken)

            guard let digestEmail = makeDigestEmail(from: message),
                  digestEmail.articleLinks.isEmpty == false else {
                continue
            }

            digestEmails.append(digestEmail)
        }

        logInfo("Fetched \(digestEmails.count) Medium digest email(s)")
        return digestEmails
    }

    private func fetchMediumMessageIDs(accessToken: String) async throws -> [String] {
        var components = URLComponents(string: "https://gmail.googleapis.com/gmail/v1/users/me/messages")
        components?.queryItems = [
            URLQueryItem(name: "q", value: "from:medium.com newer_than:30d"),
            URLQueryItem(name: "maxResults", value: "20"),
            URLQueryItem(name: "includeSpamTrash", value: "false")
        ]

        guard let url = components?.url else {
            throw LMGmailServiceError.invalidURL
        }

        let response: LMGmailMessageListResponse = try await sendGmailRequest(url: url, accessToken: accessToken)
        return response.messages?.map(\.id) ?? []
    }

    private func fetchMessage(id: String, accessToken: String) async throws -> LMGmailMessageResponse {
        var components = URLComponents(string: "https://gmail.googleapis.com/gmail/v1/users/me/messages/\(id)")
        components?.queryItems = [
            URLQueryItem(name: "format", value: "full")
        ]

        guard let url = components?.url else {
            throw LMGmailServiceError.invalidURL
        }

        return try await sendGmailRequest(url: url, accessToken: accessToken)
    }

    private func sendGmailRequest<Response: Decodable>(url: URL, accessToken: String) async throws -> Response {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LMGmailServiceError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown Gmail API error."
            throw LMGmailServiceError.requestFailed(httpResponse.statusCode, message)
        }

        return try JSONDecoder().decode(Response.self, from: data)
    }

    private func makeDigestEmail(from message: LMGmailMessageResponse) -> LMMediumDigestEmail? {
        guard let payload = message.payload else { return nil }

        let htmlBody = collectBodyText(from: payload, preferredMimeType: "text/html")
        let plainBody = collectBodyText(from: payload, preferredMimeType: "text/plain")
        let body = htmlBody.isEmpty ? plainBody : htmlBody
        let links = extractMediumArticleLinks(from: body)
        let subject = headerValue("Subject", in: payload) ?? "Medium Digest"
        let sender = headerValue("From", in: payload) ?? "Medium"

        guard isLikelyMediumDigest(sender: sender, subject: subject, snippet: message.snippet, linkCount: links.count) else {
            return nil
        }

        return LMMediumDigestEmail(
            id: message.id,
            subject: subject,
            sender: sender,
            receivedAtDescription: headerValue("Date", in: payload),
            snippet: message.snippet ?? "",
            articleLinks: links
        )
    }

    private func headerValue(_ name: String, in payload: LMGmailMessageResponse.Payload) -> String? {
        payload.headers?.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }?.value
    }

    private func collectBodyText(
        from payload: LMGmailMessageResponse.Payload,
        preferredMimeType: String
    ) -> String {
        var output: [String] = []

        collectBodyText(from: payload, preferredMimeType: preferredMimeType, output: &output)

        return output.joined(separator: "\n")
    }

    private func collectBodyText(
        from payload: LMGmailMessageResponse.Payload,
        preferredMimeType: String,
        output: inout [String]
    ) {
        if payload.mimeType == preferredMimeType,
           let encodedData = payload.body?.data,
           let decodedText = decodeBase64URLText(encodedData) {
            output.append(decodedText)
        }

        payload.parts?.forEach { part in
            collectBodyText(from: part, preferredMimeType: preferredMimeType, output: &output)
        }
    }

    private func decodeBase64URLText(_ encodedText: String) -> String? {
        var base64 = encodedText
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let paddingLength = (4 - base64.count % 4) % 4
        base64.append(String(repeating: "=", count: paddingLength))

        guard let data = Data(base64Encoded: base64) else { return nil }

        return String(data: data, encoding: .utf8)
    }

    private func extractMediumArticleLinks(from body: String) -> [LMMediumDigestArticleLink] {
        var links: [LMMediumDigestArticleLink] = []
        var seenIDs = Set<String>()

        extractAnchorLinks(from: body).forEach { title, url in
            guard let link = makeArticleLink(title: title, url: url) else { return }
            guard seenIDs.insert(link.id).inserted else { return }
            links.append(link)
        }

        extractPlainURLs(from: body).forEach { url in
            guard let link = makeArticleLink(title: nil, url: url) else { return }
            guard seenIDs.insert(link.id).inserted else { return }
            links.append(link)
        }

        return links
    }

    private func extractAnchorLinks(from body: String) -> [(String?, URL)] {
        let pattern = #"<a\b[^>]*href=["']([^"']+)["'][^>]*>(.*?)</a>"#
        let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        )
        let range = NSRange(body.startIndex..<body.endIndex, in: body)

        return regex?.matches(in: body, range: range).compactMap { match in
            guard let hrefRange = Range(match.range(at: 1), in: body),
                  let url = cleanedURL(from: String(body[hrefRange])) else {
                return nil
            }

            let title: String?
            if let titleRange = Range(match.range(at: 2), in: body) {
                title = cleanedTitle(from: String(body[titleRange]))
            } else {
                title = nil
            }

            return (title, url)
        } ?? []
    }

    private func extractPlainURLs(from body: String) -> [URL] {
        let pattern = #"https?://[^\s"'<>]+"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(body.startIndex..<body.endIndex, in: body)

        return regex?.matches(in: body, range: range).compactMap { match in
            guard let urlRange = Range(match.range, in: body) else { return nil }
            return cleanedURL(from: String(body[urlRange]))
        } ?? []
    }

    private func makeArticleLink(title: String?, url: URL) -> LMMediumDigestArticleLink? {
        let articleURL = resolvedMediumURL(from: url)

        guard isMediumArticleURL(articleURL) else { return nil }

        let id = normalizedID(for: articleURL)
        let displayTitle = title?.isEmpty == false ? title ?? fallbackTitle(for: articleURL) : fallbackTitle(for: articleURL)

        return LMMediumDigestArticleLink(id: id, title: displayTitle, url: articleURL)
    }

    private func cleanedURL(from value: String) -> URL? {
        let decodedValue = value
            .replacingOccurrences(of: "&amp;", with: "&")
            .trimmingCharacters(in: CharacterSet(charactersIn: " \n\t\r)>]\"'"))

        return URL(string: decodedValue)
    }

    private func resolvedMediumURL(from url: URL) -> URL {
        guard let host = url.host,
              isMediumHost(host),
              url.path == "/r/",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let redirectURLValue = components.queryItems?.first(where: { $0.name == "url" })?.value,
              let redirectURL = URL(string: redirectURLValue) else {
            return url
        }

        return redirectURL
    }

    private func isMediumArticleURL(_ url: URL) -> Bool {
        guard let host = url.host, isMediumHost(host) else { return false }

        let path = url.path.lowercased()
        let excludedPathFragments = [
            "/m/signin",
            "/me/",
            "/membership",
            "/plans",
            "/settings",
            "/about",
            "/policy",
            "/tag/"
        ]

        guard excludedPathFragments.contains(where: { path.contains($0) }) == false else {
            return false
        }

        return isArticlePath(url.path)
    }

    private func isMediumHost(_ host: String) -> Bool {
        let normalizedHost = host.lowercased()
        return normalizedHost == "medium.com" || normalizedHost.hasSuffix(".medium.com")
    }

    private func isArticlePath(_ path: String) -> Bool {
        let pathComponents = path
            .split(separator: "/")
            .map(String.init)

        guard let firstComponent = pathComponents.first,
              let lastComponent = pathComponents.last else {
            return false
        }

        if firstComponent == "p", pathComponents.count >= 2 {
            return true
        }

        if firstComponent.hasPrefix("@"), pathComponents.count >= 2 {
            return true
        }

        return lastComponent.count > 10 && lastComponent.contains("-")
    }

    private func isLikelyMediumDigest(
        sender: String,
        subject: String,
        snippet: String?,
        linkCount: Int
    ) -> Bool {
        let lowercasedSender = sender.lowercased()
        let lowercasedSubject = subject.lowercased()
        let lowercasedSnippet = snippet?.lowercased() ?? ""

        guard lowercasedSender.contains("@medium.com") || lowercasedSender.contains("medium.com") else {
            return false
        }

        let digestTerms = [
            "daily",
            "digest",
            "recommended",
            "stories for you",
            "today's picks",
            "for you"
        ]

        let hasDigestTerm = digestTerms.contains { term in
            lowercasedSubject.contains(term) || lowercasedSnippet.contains(term)
        }

        return hasDigestTerm || linkCount >= 2
    }

    private func normalizedID(for url: URL) -> String {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.query = nil
        components?.fragment = nil

        return components?.url?.absoluteString ?? url.absoluteString
    }

    private func fallbackTitle(for url: URL) -> String {
        let lastComponent = url.deletingPathExtension().lastPathComponent
        let title = lastComponent
            .split(separator: "-")
            .prefix(8)
            .joined(separator: " ")

        return title.isEmpty ? url.absoluteString : title
    }

    private func cleanedTitle(from html: String) -> String? {
        let withoutTags = html.replacingOccurrences(
            of: #"<[^>]+>"#,
            with: " ",
            options: .regularExpression
        )
        let decodedTitle = withoutTags
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")

        return decodedTitle
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
}
