import Foundation

// MARK: - User Model
struct User: Codable, Identifiable {
    let id: Int
    let email: String
    let name: String
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, email, name
        case createdAt = "created_at"
    }
}

// MARK: - Authentication Models
struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let name: String
}

struct AuthResponse: Codable {
    let success: Bool
    let message: String
    let user: User?
    let token: String?
}

// MARK: - Guest Model
struct Guest: Codable, Identifiable {
    let id: Int
    let fullName: String
    let phone: String?
    let attendance: AttendanceStatus
    let guestCount: Int
    let message: String?
    let createdAt: Date
    let group: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case phone, attendance, message, group
        case guestCount = "guests"
        case createdAt = "created_at"
    }
}

enum AttendanceStatus: String, Codable, CaseIterable {
    case oui = "oui"
    case non = "non"
    case peutEtre = "peut-etre"
    
    var displayName: String {
        switch self {
        case .oui: return "Oui"
        case .non: return "Non"
        case .peutEtre: return "Peut-être"
        }
    }
    
    var color: String {
        switch self {
        case .oui: return "green"
        case .non: return "red"
        case .peutEtre: return "orange"
        }
    }
}

// MARK: - Budget Models
struct BudgetCategory: Codable, Identifiable {
    let id = UUID()
    var name: String
    var plannedAmount: Double
    var actualAmount: Double
    var items: [BudgetItem]
    
    var remainingAmount: Double {
        plannedAmount - actualAmount
    }
    
    var percentage: Double {
        guard plannedAmount > 0 else { return 0 }
        return (actualAmount / plannedAmount) * 100
    }
}

struct BudgetItem: Codable, Identifiable {
    let id = UUID()
    var name: String
    var amount: Double
    var isPaid: Bool
    var notes: String?
    var date: Date?
}

struct BudgetData: Codable {
    var categories: [BudgetCategory]
    var totalBudget: Double
    var updatedAt: Date
    
    var totalSpent: Double {
        categories.reduce(0) { $0 + $1.actualAmount }
    }
    
    var remainingBudget: Double {
        totalBudget - totalSpent
    }
}