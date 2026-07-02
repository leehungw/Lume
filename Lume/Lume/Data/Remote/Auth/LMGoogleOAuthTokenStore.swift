import Foundation
import Security

final class LMGoogleOAuthTokenStore: Loggable {
    private let service: String
    private let account = "gmail-oauth"

    init(service: String = Bundle.main.bundleIdentifier ?? "Lume") {
        self.service = service
    }

    func loadCredential() throws -> LMGmailCredential? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status != errSecItemNotFound else { return nil }
        guard status == errSecSuccess, let data = result as? Data else {
            throw LMGoogleOAuthError.keychainFailure(status)
        }

        return try JSONDecoder().decode(LMGmailCredential.self, from: data)
    }

    func saveCredential(_ credential: LMGmailCredential) throws {
        let data = try JSONEncoder().encode(credential)
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let updateStatus = SecItemUpdate(baseQuery() as CFDictionary, attributes as CFDictionary)

        switch updateStatus {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            var query = baseQuery()
            attributes.forEach { key, value in
                query[key] = value
            }

            let addStatus = SecItemAdd(query as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw LMGoogleOAuthError.keychainFailure(addStatus)
            }
        default:
            throw LMGoogleOAuthError.keychainFailure(updateStatus)
        }
    }

    func deleteCredential() throws {
        let status = SecItemDelete(baseQuery() as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw LMGoogleOAuthError.keychainFailure(status)
        }
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
