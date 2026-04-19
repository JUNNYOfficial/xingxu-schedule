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
        // 自闭症友好：统一柔和蓝灰色系，不同明度区分
        switch value {
        case 1: return "#5A7A94"   // 深
        case 2: return "#6B8BA3"   // 较深
        case 3: return "#7BA3C4"   // 中（标准蓝灰）
        case 4: return "#8FB8D4"   // 较浅
        case 5: return "#A3CDE4"   // 浅
        default: return "#7BA3C4"
        }
    }
}
