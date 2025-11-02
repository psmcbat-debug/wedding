import Foundation

// MARK: - Gift Models
struct Gift: Codable, Identifiable {
    let id = UUID()
    var guestName: String
    var amount: Double?
    var description: String?
    var receivedDate: Date
    var category: GiftCategory
    var notes: String?
}

enum GiftCategory: String, Codable, CaseIterable {
    case money = "money"
    case物品 = "item"
    case service = "service"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .money: return "Argent"
        case .物品: return "Objet"
        case .service: return "Service"
        case .other: return "Autre"
        }
    }
}

struct GiftData: Codable {
    var gifts: [Gift]
    var updatedAt: Date
    
    var totalMoneyReceived: Double {
        gifts.filter { $0.category == .money }
             .compactMap { $0.amount }
             .reduce(0, +)
    }
    
    var giftCount: Int {
        gifts.count
    }
}

// MARK: - Task Models
struct WeddingTask: Codable, Identifiable {
    let id = UUID()
    var title: String
    var description: String?
    var dueDate: Date?
    var isCompleted: Bool
    var priority: TaskPriority
    var category: TaskCategory
    var assignedTo: String?
    var notes: String?
    var completedDate: Date?
}

enum TaskPriority: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case urgent = "urgent"
    
    var displayName: String {
        switch self {
        case .low: return "Faible"
        case .medium: return "Moyenne"
        case .high: return "Haute"
        case .urgent: return "Urgente"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .urgent: return "red"
        }
    }
}

enum TaskCategory: String, Codable, CaseIterable {
    case venue = "venue"
    case catering = "catering"
    case decoration = "decoration"
    case music = "music"
    case photography = "photography"
    case transport = "transport"
    case legal = "legal"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .venue: return "Lieu"
        case .catering: return "Traiteur"
        case .decoration: return "Décoration"
        case .music: return "Musique"
        case .photography: return "Photographie"
        case .transport: return "Transport"
        case .legal: return "Administratif"
        case .other: return "Autre"
        }
    }
}

struct TaskData: Codable {
    var tasks: [WeddingTask]
    var updatedAt: Date
    
    var completedTasks: [WeddingTask] {
        tasks.filter { $0.isCompleted }
    }
    
    var pendingTasks: [WeddingTask] {
        tasks.filter { !$0.isCompleted }
    }
    
    var overdueTasks: [WeddingTask] {
        let now = Date()
        return tasks.filter { task in
            !task.isCompleted && 
            task.dueDate != nil && 
            task.dueDate! < now
        }
    }
    
    var completionPercentage: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(completedTasks.count) / Double(tasks.count) * 100
    }
}