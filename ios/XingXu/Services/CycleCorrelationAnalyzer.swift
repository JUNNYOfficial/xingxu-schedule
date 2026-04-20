import Foundation

/// 周期与心情/任务的关联分析结果
struct CycleCorrelationResult {
    /// 各周期阶段的平均心情 (1-5)
    let moodByPhase: [(phaseName: String, avgMood: Double, sampleCount: Int)]
    /// 各周期阶段的任务完成率
    let completionRateByPhase: [(phaseName: String, rate: Double, totalTasks: Int)]
    /// 最强关联发现（洞察建议）
    let insights: [String]
    /// 是否有足够数据进行分析
    let hasEnoughData: Bool
}

/// 周期关联分析引擎
class CycleCorrelationAnalyzer {
    
    /// 分析周期与心情/任务的关联
    static func analyze(records: [MenstrualRecord], moods: [MoodEntry], tasks: [TaskItem]) -> CycleCorrelationResult {
        // 数据量检查：至少需要2条周期记录才能分阶段
        guard records.count >= 2 else {
            return CycleCorrelationResult(
                moodByPhase: [],
                completionRateByPhase: [],
                insights: ["记录更多月经周期后，可以发现周期对心情和任务的影响规律。"],
                hasEnoughData: false
            )
        }
        
        let sortedRecords = records.sorted { $0.startDate < $1.startDate }
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        // 计算平均周期长度（用于分阶段）
        let cycleLengths = computeCycleLengths(sortedRecords)
        let avgCycle = cycleLengths.isEmpty ? 28 : cycleLengths.reduce(0, +) / cycleLengths.count
        
        // 按周期阶段分组的心情数据
        var moodData: [String: [Int]] = [
            "月经期": [],
            "卵泡期": [],
            "排卵期": [],
            "黄体期": [],
            "经前期": []
        ]
        
        // 按周期阶段分组的任务数据
        var taskData: [String: (total: Int, completed: Int)] = [
            "月经期": (0, 0),
            "卵泡期": (0, 0),
            "排卵期": (0, 0),
            "黄体期": (0, 0),
            "经前期": (0, 0)
        ]
        
        // 分析心情数据
        for mood in moods {
            guard let moodDate = formatter.date(from: mood.date) else { continue }
            let phase = cyclePhaseForDate(moodDate, records: sortedRecords, avgCycle: avgCycle)
            moodData[phase]?.append(mood.value)
        }
        
        // 分析任务数据
        for task in tasks {
            guard let taskDate = formatter.date(from: task.date) else { continue }
            let phase = cyclePhaseForDate(taskDate, records: sortedRecords, avgCycle: avgCycle)
            var current = taskData[phase] ?? (0, 0)
            current.total += 1
            if task.completed { current.completed += 1 }
            taskData[phase] = current
        }
        
        // 计算各阶段平均心情
        let moodByPhase = moodData.map { (phase, values) -> (String, Double, Int) in
            let avg = values.isEmpty ? 0.0 : Double(values.reduce(0, +)) / Double(values.count)
            return (phase, avg, values.count)
        }.sorted { $0.1 > $1.1 }
        
        // 计算各阶段完成率
        let completionRateByPhase = taskData.map { (phase, data) -> (String, Double, Int) in
            let rate = data.total > 0 ? Double(data.completed) / Double(data.total) * 100 : 0
            return (phase, rate, data.total)
        }.sorted { $0.1 > $1.1 }
        
        // 生成洞察
        let insights = generateInsights(
            moodByPhase: moodByPhase,
            completionRateByPhase: completionRateByPhase,
            recordsCount: records.count
        )
        
        return CycleCorrelationResult(
            moodByPhase: moodByPhase,
            completionRateByPhase: completionRateByPhase,
            insights: insights,
            hasEnoughData: records.count >= 3 && moods.count >= 5
        )
    }
    
    /// 判断某日期处于哪个周期阶段
    private static func cyclePhaseForDate(_ date: Date, records: [MenstrualRecord], avgCycle: Int) -> String {
        let calendar = Calendar.current
        
        // 先检查是否在已知经期中
        for record in records {
            let endDate = record.endDate ?? calendar.date(byAdding: .day, value: record.durationDays - 1, to: record.startDate)!
            if date >= record.startDate && date <= endDate {
                return "月经期"
            }
        }
        
        // 找到最近的经期开始日
        guard let lastRecord = records.last else { return "卵泡期" }
        let daysSinceLast = calendar.dateComponents([.day], from: lastRecord.startDate, to: date).day ?? 0
        
        // 如果日期在经期之前（可能是未来日期）
        if daysSinceLast < 0 {
            return "卵泡期"
        }
        
        // 基于平均周期长度分阶段
        let dayInCycle = daysSinceLast % avgCycle
        
        if dayInCycle <= 5 {
            return "月经期"
        } else if dayInCycle <= 13 {
            return "卵泡期"
        } else if dayInCycle <= 16 {
            return "排卵期"
        } else if dayInCycle >= avgCycle - 7 {
            return "经前期"
        } else {
            return "黄体期"
        }
    }
    
    private static func computeCycleLengths(_ records: [MenstrualRecord]) -> [Int] {
        var lengths: [Int] = []
        for i in 0..<(records.count - 1) {
            let days = Calendar.current.dateComponents([.day], from: records[i].startDate, to: records[i + 1].startDate).day ?? 28
            if days >= 10 && days <= 90 {
                lengths.append(days)
            }
        }
        return lengths
    }
    
    /// 生成洞察建议
    private static func generateInsights(
        moodByPhase: [(String, Double, Int)],
        completionRateByPhase: [(String, Double, Int)],
        recordsCount: Int
    ) -> [String] {
        var insights: [String] = []
        
        // 心情洞察
        let validMoods = moodByPhase.filter { $0.2 >= 2 }
        if validMoods.count >= 2 {
            let sortedMood = validMoods.sorted { $0.1 > $1.1 }
            if let best = sortedMood.first, let worst = sortedMood.last, best.1 > worst.1 + 0.5 {
                insights.append("😊 \(best.0)的心情最好（平均\(String(format: "%.1f", best.1))分），\(worst.0)的心情较低（平均\(String(format: "%.1f", worst.1))分）")
            }
        }
        
        // 任务完成率洞察
        let validTasks = completionRateByPhase.filter { $0.2 >= 3 }
        if validTasks.count >= 2 {
            let sortedRate = validTasks.sorted { $0.1 > $1.1 }
            if let best = sortedRate.first, let worst = sortedRate.last, best.1 > worst.1 + 15 {
                insights.append("📈 \(best.0)的任务完成率最高（\(Int(best.1))%），\(worst.0)的效率相对较低（\(Int(worst.1))%）")
            }
        }
        
        // 综合建议
        if let premenstrualMood = moodByPhase.first(where: { $0.0 == "经前期" }), premenstrualMood.1 > 0 && premenstrualMood.1 < 3.0 {
            insights.append("💗 经前期心情容易低落，建议提前安排更多休息时间和舒缓活动")
        }
        
        if let menstrualRate = completionRateByPhase.first(where: { $0.0 == "月经期" }), menstrualRate.1 > 0 && menstrualRate.1 < 60 {
            insights.append("🌙 经期任务完成率较低，这是完全正常的。可以适当减少任务量")
        }
        
        if insights.isEmpty {
            insights.append("继续记录心情和任务，周期与身心状态的关联会越来越清晰")
        }
        
        return insights
    }
}
