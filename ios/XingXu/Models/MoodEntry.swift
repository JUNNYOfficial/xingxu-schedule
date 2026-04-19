import Foundation

/// 心情记录
struct MoodEntry: Codable, Identifiable, Equatable {
    var id: String
    var date: String  // YYYY-MM-DD
    var value: Int    // 1-5
    var note: String
    var createdAt: Date
    
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
