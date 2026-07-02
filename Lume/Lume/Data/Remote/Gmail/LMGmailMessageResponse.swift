import Foundation

struct LMGmailMessageResponse: Decodable {
    let id: String
    let threadId: String?
    let snippet: String?
    let payload: Payload?
    let internalDate: String?

    struct Payload: Decodable {
        let mimeType: String?
        let headers: [Header]?
        let body: Body?
        let parts: [Payload]?
    }

    struct Header: Decodable {
        let name: String
        let value: String
    }

    struct Body: Decodable {
        let data: String?
    }
}
