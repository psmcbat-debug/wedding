import Foundation

// MARK: - Seating Models
struct SeatingChart: Codable {
    var tables: [WeddingTable]
    var updatedAt: Date
    
    var totalSeats: Int {
        tables.reduce(0) { $0 + $1.capacity }
    }
    
    var occupiedSeats: Int {
        tables.reduce(0) { $0 + $1.guests.count }
    }
    
    var availableSeats: Int {
        totalSeats - occupiedSeats
    }
}

struct WeddingTable: Codable, Identifiable {
    let id = UUID()
    var tableNumber: Int
    var capacity: Int
    var shape: TableShape
    var position: TablePosition
    var guests: [Int] // Guest IDs
    var notes: String?
    
    var isComplete: Bool {
        guests.count == capacity
    }
    
    var availableSpots: Int {
        capacity - guests.count
    }
}

enum TableShape: String, Codable, CaseIterable {
    case round = "round"
    case rectangular = "rectangular"
    case square = "square"
    case oval = "oval"
    
    var displayName: String {
        switch self {
        case .round: return "Ronde"
        case .rectangular: return "Rectangulaire"
        case .square: return "Carrée"
        case .oval: return "Ovale"
        }
    }
}

struct TablePosition: Codable {
    var x: Double
    var y: Double
    var rotation: Double = 0
}

// MARK: - Hall Layout Models
struct HallLayout: Codable {
    var items: [HallItem]
    var hallDimensions: HallDimensions
    var updatedAt: Date
}

struct HallItem: Codable, Identifiable {
    let id = UUID()
    var type: HallItemType
    var position: ItemPosition
    var size: ItemSize
    var label: String?
    var color: String?
    var rotation: Double = 0
}

enum HallItemType: String, Codable, CaseIterable {
    case table = "table"
    case stage = "stage"
    case bar = "bar"
    case danceFloor = "dance_floor"
    case entrance = "entrance"
    case photoArea = "photo_area"
    case buffet = "buffet"
    case decoration = "decoration"
    case speaker = "speaker"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .table: return "Table"
        case .stage: return "Scène"
        case .bar: return "Bar"
        case .danceFloor: return "Piste de danse"
        case .entrance: return "Entrée"
        case .photoArea: return "Espace photo"
        case .buffet: return "Buffet"
        case .decoration: return "Décoration"
        case .speaker: return "Haut-parleur"
        case .other: return "Autre"
        }
    }
    
    var defaultColor: String {
        switch self {
        case .table: return "brown"
        case .stage: return "purple"
        case .bar: return "blue"
        case .danceFloor: return "yellow"
        case .entrance: return "green"
        case .photoArea: return "pink"
        case .buffet: return "orange"
        case .decoration: return "red"
        case .speaker: return "black"
        case .other: return "gray"
        }
    }
}

struct ItemPosition: Codable {
    var x: Double
    var y: Double
}

struct ItemSize: Codable {
    var width: Double
    var height: Double
}

struct HallDimensions: Codable {
    var width: Double
    var height: Double
    var unit: String = "m" // mètres
}

// MARK: - Message Models
struct Message: Codable, Identifiable {
    let id = UUID()
    var from: String
    var subject: String?
    var content: String
    var receivedDate: Date
    var isRead: Bool = false
    var type: MessageType
    var relatedGuestId: Int?
}

enum MessageType: String, Codable, CaseIterable {
    case rsvp = "rsvp"
    case general = "general"
    case question = "question"
    case special = "special"
    
    var displayName: String {
        switch self {
        case .rsvp: return "RSVP"
        case .general: return "Général"
        case .question: return "Question"
        case .special: return "Spécial"
        }
    }
}