import Foundation

struct LMMediumDigestEmail: Identifiable, Hashable {
    let id: String
    let subject: String
    let sender: String
    let receivedAtDescription: String?
    let snippet: String
    let articleLinks: [LMMediumDigestArticleLink]
}
