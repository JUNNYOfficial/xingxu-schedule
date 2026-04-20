import AppIntents
import Foundation

/// Siri 快捷指令：添加日程任务
/// 示例："嘿 Siri，用星序记录明天上午9点数学课"
struct AddTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "添加日程"
    static var description = IntentDescription("在星序中添加一个新的日程任务")
    
    @Parameter(title: "任务名称", requestValueDialog: "要记录什么任务？")
    var taskName: String
    
    @Parameter(title: "时间", description: "例如：09:00、下午3点", requestValueDialog: "几点开始？")
    var time: String?
    
    @Parameter(title: "日期", description: "例如：今天、明天、下周一", requestValueDialog: "哪一天？")
    var dateDescription: String?
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let resolvedDate = resolveDate(from: dateDescription)
        let resolvedTime = resolveTime(from: time) ?? "09:00"
        
        let task = TaskItem(
            name: taskName.trimmingCharacters(in: .whitespaces),
            time: resolvedTime,
            date: resolvedDate,
            tag: ""
        )
        
        await MainActor.run {
            DataManager.shared.addTask(task)
        }
        
        return .result(value: "已添加：\(taskName)")
    }
    
    // MARK: - 日期解析
    
    private func resolveDate(from description: String?) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "zh_CN")
        
        guard let desc = description?.trimmingCharacters(in: .whitespaces) else {
            return formatter.string(from: Date())
        }
        
        let lowercased = desc.lowercased()
        let calendar = Calendar.current
        
        if lowercased.contains("明天") || lowercased.contains("明") {
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
            return formatter.string(from: tomorrow)
        }
        if lowercased.contains("后天") {
            let dayAfter = calendar.date(byAdding: .day, value: 2, to: Date())!
            return formatter.string(from: dayAfter)
        }
        if lowercased.contains("昨天") {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
            return formatter.string(from: yesterday)
        }
        if lowercased.contains("今天") || lowercased.contains("今") {
            return formatter.string(from: Date())
        }
        if lowercased.contains("下周") {
            let nextWeek = calendar.date(byAdding: .day, value: 7, to: Date())!
            return formatter.string(from: nextWeek)
        }
        
        // 尝试直接解析日期
        let dateFormats = ["yyyy-MM-dd", "M月d日", "M/d", "M-d"]
        for format in dateFormats {
            formatter.dateFormat = format
            if let date = formatter.date(from: desc) {
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter.string(from: date)
            }
        }
        
        // 默认今天
        return formatter.string(from: Date())
    }
    
    // MARK: - 时间解析
    
    private func resolveTime(from description: String?) -> String? {
        guard let desc = description?.trimmingCharacters(in: .whitespaces) else { return nil }
        
        let lowercased = desc.lowercased()
        
        // 尝试直接匹配 HH:mm
        let timePattern = "^([0-9]{1,2}):([0-9]{2})$"
        if let regex = try? NSRegularExpression(pattern: timePattern),
           let match = regex.firstMatch(in: desc, range: NSRange(desc.startIndex..., in: desc)) {
            let hourRange = Range(match.range(at: 1), in: desc)!
            let minuteRange = Range(match.range(at: 2), in: desc)!
            let hour = Int(desc[hourRange]) ?? 0
            let minute = Int(desc[minuteRange]) ?? 0
            return String(format: "%02d:%02d", hour, minute)
        }
        
        // 解析 "上午X点" "下午X点"
        let amPattern = "上午?([0-9]{1,2})点?"
        let pmPattern = "下午?([0-9]{1,2})点?"
        
        if let regex = try? NSRegularExpression(pattern: amPattern),
           let match = regex.firstMatch(in: lowercased, range: NSRange(lowercased.startIndex..., in: lowercased)) {
            let range = Range(match.range(at: 1), in: lowercased)!
            let hour = Int(lowercased[range]) ?? 9
            return String(format: "%02d:00", hour)
        }
        
        if let regex = try? NSRegularExpression(pattern: pmPattern),
           let match = regex.firstMatch(in: lowercased, range: NSRange(lowercased.startIndex..., in: lowercased)) {
            let range = Range(match.range(at: 1), in: lowercased)!
            let hour = (Int(lowercased[range]) ?? 1) + 12
            return String(format: "%02d:00", min(hour, 23))
        }
        
        // 纯数字，当作小时
        if let hour = Int(desc), hour >= 0 && hour <= 23 {
            return String(format: "%02d:00", hour)
        }
        
        return nil
    }
}
