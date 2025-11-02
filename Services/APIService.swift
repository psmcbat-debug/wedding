import Foundation
import Combine

class APIService: ObservableObject {
    static let shared = APIService()
    
    // Configuration de l'API - Modifiez cette URL pour pointer vers votre serveur PHP
    private let baseURL = "http://localhost/ios/api"
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Generic API Request Method
    private func makeRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Ajouter le token d'authentification si disponible
        if let token = AuthenticationManager.shared.getStoredToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Ajouter le token CSRF pour les requêtes de modification
        if method != .GET {
            if let csrfToken = await getCSRFToken() {
                request.setValue(csrfToken, forHTTPHeaderField: "X-CSRF-TOKEN")
            }
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                throw APIError.serverError(httpResponse.statusCode)
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            return try decoder.decode(responseType, from: data)
        } catch {
            throw APIError.networkError(error.localizedDescription)
        }
    }
    
    // MARK: - CSRF Token
    private func getCSRFToken() async -> String? {
        // Implémentation pour récupérer le token CSRF depuis votre API
        // Pour l'instant, retournons nil - à implémenter selon votre API
        return nil
    }
    
    // MARK: - Authentication Methods
    func login(email: String, password: String) async throws -> AuthResponse {
        let loginData = LoginRequest(email: email, password: password)
        let body = try JSONEncoder().encode(loginData)
        
        return try await makeRequest(
            endpoint: "auth/login.php",
            method: .POST,
            body: body,
            responseType: AuthResponse.self
        )
    }
    
    func register(email: String, password: String, name: String) async throws -> AuthResponse {
        let registerData = RegisterRequest(email: email, password: password, name: name)
        let body = try JSONEncoder().encode(registerData)
        
        return try await makeRequest(
            endpoint: "auth/register.php",
            method: .POST,
            body: body,
            responseType: AuthResponse.self
        )
    }
    
    func refreshToken() async throws -> AuthResponse {
        return try await makeRequest(
            endpoint: "auth/refresh.php",
            method: .POST,
            responseType: AuthResponse.self
        )
    }
}

// MARK: - Guest API Methods
extension APIService {
    func loadGuests() async throws -> [Guest] {
        struct GuestsResponse: Codable {
            let guests: [Guest]
        }
        
        let response = try await makeRequest(
            endpoint: "load_rsvps.php",
            responseType: GuestsResponse.self
        )
        
        return response.guests
    }
    
    func addGuest(_ guest: Guest) async throws -> Guest {
        let body = try JSONEncoder().encode(guest)
        
        return try await makeRequest(
            endpoint: "guest_add.php",
            method: .POST,
            body: body,
            responseType: Guest.self
        )
    }
    
    func updateGuest(_ guest: Guest) async throws -> Guest {
        let body = try JSONEncoder().encode(guest)
        
        return try await makeRequest(
            endpoint: "guest_update.php",
            method: .POST,
            body: body,
            responseType: Guest.self
        )
    }
}

// MARK: - Budget API Methods
extension APIService {
    func loadBudget() async throws -> BudgetData {
        return try await makeRequest(
            endpoint: "budget_load.php",
            responseType: BudgetData.self
        )
    }
    
    func saveBudget(_ budgetData: BudgetData) async throws -> Bool {
        let body = try JSONEncoder().encode(budgetData)
        
        struct BudgetResponse: Codable {
            let success: Bool
        }
        
        let response = try await makeRequest(
            endpoint: "budget_save.php",
            method: .POST,
            body: body,
            responseType: BudgetResponse.self
        )
        
        return response.success
    }
}

// MARK: - Gifts API Methods
extension APIService {
    func loadGifts() async throws -> GiftData {
        return try await makeRequest(
            endpoint: "gifts_load.php",
            responseType: GiftData.self
        )
    }
    
    func saveGifts(_ giftData: GiftData) async throws -> Bool {
        let body = try JSONEncoder().encode(giftData)
        
        struct GiftResponse: Codable {
            let success: Bool
        }
        
        let response = try await makeRequest(
            endpoint: "gifts_save.php",
            method: .POST,
            body: body,
            responseType: GiftResponse.self
        )
        
        return response.success
    }
}

// MARK: - Tasks API Methods
extension APIService {
    func loadTasks() async throws -> TaskData {
        return try await makeRequest(
            endpoint: "tasks_load.php",
            responseType: TaskData.self
        )
    }
    
    func saveTasks(_ taskData: TaskData) async throws -> Bool {
        let body = try JSONEncoder().encode(taskData)
        
        struct TaskResponse: Codable {
            let success: Bool
        }
        
        let response = try await makeRequest(
            endpoint: "tasks_save.php",
            method: .POST,
            body: body,
            responseType: TaskResponse.self
        )
        
        return response.success
    }
}

// MARK: - Supporting Types
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case networkError(String)
    case serverError(Int)
    case decodingError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL invalide"
        case .invalidResponse:
            return "Réponse invalide du serveur"
        case .networkError(let message):
            return "Erreur réseau: \(message)"
        case .serverError(let code):
            return "Erreur serveur: \(code)"
        case .decodingError(let message):
            return "Erreur de décodage: \(message)"
        }
    }
}