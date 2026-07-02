import Foundation

struct LMGmailMessageListResponse: Decodable {
    let messages: [Message]?

    struct Message: Decodable {
        let id: String
        let threadId: String?
    }
}
