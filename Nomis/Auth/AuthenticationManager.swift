import Foundation

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var canEdit: Bool = false
    @Published var canDelete: Bool = false
    @Published var currentUsername: String = ""
    
    private let userDefaultsKey = "lastAuthenticationTime"
    
    init() {
        // Her açılışta login ekranı gösterilsin
        isAuthenticated = false
        canEdit = false
        canDelete = false
        currentUsername = ""
    }
    
    func login(username: String, password: String) -> Bool {
        // Simple authentication logic
        // In a real app, this would validate against a secure backend
        if username == "mert" && password == "9023" {
            // Admin: Full permissions
            isAuthenticated = true
            canEdit = true
            canDelete = true
            currentUsername = username
            updateLastAuthenticationTime()
            return true
        } else if username == "killeR" && password == "k4yy21wac70?!/gdkye" {
            // Deleter: Only delete permission, no edit
            isAuthenticated = true
            canEdit = false
            canDelete = true
            currentUsername = username
            updateLastAuthenticationTime()
            return true
        } else if (username == "kadir" && password == "2390") || (username == "yalçın" && password == "4806") {
            // Viewers: Read-only
            isAuthenticated = true
            canEdit = false
            canDelete = false
            currentUsername = username
            updateLastAuthenticationTime()
            return true
        }
        return false
    }
    
    func authenticateAdmin(password: String) -> Bool {
        // Admin şifresi kontrolü - login ile aynı şifre
        return password == "9023"
    }
    
    func logout() {
        isAuthenticated = false
        canEdit = false
        canDelete = false
        currentUsername = ""
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
    
    private func updateLastAuthenticationTime() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: userDefaultsKey)
    }
}
