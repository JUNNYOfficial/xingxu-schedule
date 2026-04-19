import Foundation

/// 心情记录
struct MoodEntry: Codable, Identifiable, Equatable {
    var id: String
    var date: String  // YYYY-MM-DD
    var value: Int    // 1-5
    var note: String
    var createdAt: Date
    var modifiedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, date, value, note, createdAt, modifiedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        date = try container.decode(String.self, forKey: .date)
        value = try container.decodeIfPresent(Int.self, forKey: .value) ?? 3
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        modifiedAt = try container.decodeIfPresent(Date.self, forKey: .modifiedAt) ?? Date()
    }
    
    init(
        id: String = UUID().uuidString,
        date: String,
        value: Int,
        note: String = ""
    ) {
        self.id = id
        self.date = date
        self.value = max(1, min(5, value))
        self.note = note
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
    
    var emoji: String {
        switch value {
        case 1: return "😢"
        case 2: return "😔"
        case 3: return "😐"
        case 4: return "🙂"
        case 5: return "😊"
        default: return "😐"
        }
    }
    
    var color: String {
        switch value {
        case 1: return "#EF4444"
        case 2: return "#F59E0B"
        case 3: return "#9CA3AF"
        case 4: return "#10B981"
        case 5: return "#3B82F6"
        default: return "#9CA3AF"
        }
    }
}
