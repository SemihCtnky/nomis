import Foundation
import Security

class KeychainService {
    static let shared = KeychainService()
    private init() {}
    
    private let service = "com.kilitcim.app"
    
    // MARK: - Store Password
    func storePassword(username: String, password: String) -> Bool {
        guard let passwordData = password.data(using: .utf8) else {
            return false
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: username,
            kSecValueData as String: passwordData
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Retrieve Password
    func retrievePassword(username: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: username,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let passwordData = result as? Data,
              let password = String(data: passwordData, encoding: .utf8) else {
            return nil
        }
        
        return password
    }
    
    // MARK: - Delete Password
    func deletePassword(username: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: username
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Update Password
    func updatePassword(username: String, newPassword: String) -> Bool {
        guard let newPasswordData = newPassword.data(using: .utf8) else {
            return false
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: username
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: newPasswordData
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        // If item doesn't exist, create it
        if status == errSecItemNotFound {
            return storePassword(username: username, password: newPassword)
        }
        
        return status == errSecSuccess
    }
    
    // MARK: - Hash Password
    func hashPassword(_ password: String) -> String {
        guard let data = password.data(using: .utf8) else {
            return ""
        }
        let hash = data.withUnsafeBytes { bytes in
            return Data(bytes).base64EncodedString()
        }
        return hash
    }
    
    // MARK: - Verify Password
    func verifyPassword(_ password: String, against hashedPassword: String) -> Bool {
        return hashPassword(password) == hashedPassword
    }
    
    // MARK: - Setup Default Users
    func setupDefaultUsers() {
        let defaultUsers = [
            ("admin", "1234", UserRole.admin),
            ("g1", "1111", UserRole.viewer1),
            ("g2", "2222", UserRole.viewer2)
        ]
        
        for (username, password, _) in defaultUsers {
            let hashedPassword = hashPassword(password)
            _ = storePassword(username: username, password: hashedPassword)
        }
    }
    
    // MARK: - List All Stored Users
    func listStoredUsers() -> [String] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let items = result as? [[String: Any]] else {
            return []
        }
        
        return items.compactMap { item in
            item[kSecAttrAccount as String] as? String
        }
    }
    
    // MARK: - Check if user exists
    func userExists(_ username: String) -> Bool {
        return retrievePassword(username: username) != nil
    }
}

