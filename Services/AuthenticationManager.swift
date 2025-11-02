import Foundation
import Security
import Combine

class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let keychainService = "WeddingManager"
    private let tokenKey = "AuthToken"
    private let userKey = "CurrentUser"
    
    init() {
        checkAuthenticationStatus()
    }
    
    // MARK: - Authentication Status
    func checkAuthenticationStatus() {
        if let token = getStoredToken(), !token.isEmpty {
            // Vérifier si le token est toujours valide
            Task {
                await validateToken()
            }
        } else {
            DispatchQueue.main.async {
                self.isAuthenticated = false
                self.currentUser = nil
            }
        }
    }
    
    // MARK: - Login
    @MainActor
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await APIService.shared.login(email: email, password: password)
            
            if response.success, let user = response.user, let token = response.token {
                // Stocker le token et les données utilisateur
                storeToken(token)
                storeUser(user)
                
                // Mettre à jour l'état
                self.currentUser = user
                self.isAuthenticated = true
            } else {
                self.errorMessage = response.message
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Register
    @MainActor
    func register(email: String, password: String, name: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await APIService.shared.register(email: email, password: password, name: name)
            
            if response.success, let user = response.user, let token = response.token {
                // Stocker le token et les données utilisateur
                storeToken(token)
                storeUser(user)
                
                // Mettre à jour l'état
                self.currentUser = user
                self.isAuthenticated = true
            } else {
                self.errorMessage = response.message
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Logout
    @MainActor
    func logout() {
        // Supprimer les données stockées
        deleteStoredToken()
        deleteStoredUser()
        
        // Mettre à jour l'état
        self.currentUser = nil
        self.isAuthenticated = false
        self.errorMessage = nil
    }
    
    // MARK: - Token Validation
    private func validateToken() async {
        do {
            let response = try await APIService.shared.refreshToken()
            
            DispatchQueue.main.async {
                if response.success, let user = response.user {
                    self.currentUser = user
                    self.isAuthenticated = true
                    
                    if let newToken = response.token {
                        self.storeToken(newToken)
                    }
                } else {
                    self.logout()
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.logout()
            }
        }
    }
    
    // MARK: - Keychain Operations
    func getStoredToken() -> String? {
        return getKeychainValue(for: tokenKey)
    }
    
    private func storeToken(_ token: String) {
        storeInKeychain(value: token, for: tokenKey)
    }
    
    private func deleteStoredToken() {
        deleteFromKeychain(key: tokenKey)
    }
    
    private func storeUser(_ user: User) {
        if let userData = try? JSONEncoder().encode(user) {
            storeInKeychain(data: userData, for: userKey)
        }
    }
    
    private func getStoredUser() -> User? {
        guard let userData = getKeychainData(for: userKey) else { return nil }
        return try? JSONDecoder().decode(User.self, from: userData)
    }
    
    private func deleteStoredUser() {
        deleteFromKeychain(key: userKey)
    }
    
    // MARK: - Generic Keychain Methods
    private func storeInKeychain(value: String, for key: String) {
        guard let data = value.data(using: .utf8) else { return }
        storeInKeychain(data: data, for: key)
    }
    
    private func storeInKeychain(data: Data, for key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Supprimer l'ancienne valeur s'il y en a une
        SecItemDelete(query as CFDictionary)
        
        // Ajouter la nouvelle valeur
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func getKeychainValue(for key: String) -> String? {
        guard let data = getKeychainData(for: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    private func getKeychainData(for key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }
    
    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Error Handling
    func clearError() {
        errorMessage = nil
    }
}