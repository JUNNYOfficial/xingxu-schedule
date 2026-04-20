import Foundation

/// 饮水记录
struct WaterRecord: Codable, Identifiable, Equatable {
    var id: String
    var date: String       // yyyy-MM-dd
    var amount: Int        // ml
    var timestamp: Date
    
    init(id: String = UUID().uuidString, date: String, amount: Int = 250, timestamp: Date = Date()) {
        self.id = id
        self.date = date
        self.amount = amount
        self.timestamp = timestamp
    }
}
