import Foundation

struct LMGoogleOAuthTokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String?
    let idToken: String?
    let expiresIn: TimeInterval
    let scope: String
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case idToken = "id_token"
        case expiresIn = "expires_in"
        case scope
        case tokenType = "token_type"
    }

    func makeCredential(existingRefreshToken: String?, existingIDToken: String? = nil) -> LMGmailCredential {
        LMGmailCredential(
            accessToken: accessToken,
            refreshToken: refreshToken ?? existingRefreshToken,
            idToken: idToken ?? existingIDToken,
            tokenType: tokenType,
            scopes: scope,
            expirationDate: Date().addingTimeInterval(expiresIn)
        )
    }
}
