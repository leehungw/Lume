import Foundation

struct LMGmailCredential: Codable, Equatable {
    let accessToken: String
    let refreshToken: String?
    let idToken: String?
    let tokenType: String
    let scopes: String
    let expirationDate: Date

    var isExpired: Bool {
        expirationDate.timeIntervalSinceNow < 60
    }
}
