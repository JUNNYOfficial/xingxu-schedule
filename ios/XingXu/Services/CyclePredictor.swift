import Foundation

/// 月经周期本地预测引擎
/// 专为青春期/不规律周期设计的鲁棒算法
class CyclePredictor {
    
    // MARK: - 核心预测方法
    
    /// 基于历史记录生成预测
    static func predict(records: [MenstrualRecord]) -> CyclePrediction {
        let sorted = records.sorted { $0.startDate < $1.startDate }
        let today = Date()
        
        // 数据不足：无法预测
        guard sorted.count >= 2 else {
            if sorted.count == 1 {
                // 只有1条记录：显示建立规律中
                let daysSince = daysBetween(sorted[0].startDate, today)
                return CyclePrediction(
                    regularityScore: 0,
                    nextWindowEarliest: nil, nextWindowLatest: nil,
                    mostLikelyDate: nil,
                    currentPhase: .establishing,
                    daysUntilDescription: "还需要多记录几次，才能帮您预测",
                    isPremenstrualAlert: false
                )
            }
            return CyclePrediction(
                regularityScore: 0,
                nextWindowEarliest: nil, nextWindowLatest: nil,
                mostLikelyDate: nil,
                currentPhase: .noData,
                daysUntilDescription: "记录第一次月经，开始追踪",
                isPremenstrualAlert: false
            )
        }
        
        // 计算周期长度序列
        let cycleLengths = computeCycleLengths(sorted)
        let regularity = computeRegularity(cycleLengths)
        let lastStart = sorted.last!.startDate
        let daysSinceLast = daysBetween(lastStart, today)
        
        // 判断当前是否正在经期
        if let lastRecord = sorted.last, daysSinceLast <= 7 {
            return CyclePrediction(
                regularityScore: regularity,
                nextWindowEarliest: nil, nextWindowLatest: nil,
                mostLikelyDate: nil,
                currentPhase: .menstruation,
                daysUntilDescription: "正在经期中",
                isPremenstrualAlert: false
            )
        }
        
        // 基于规律度选择预测策略
        if regularity < 30 || cycleLengths.count < 3 {
            // 不规律或数据不足：使用历史范围 + 症状辅助
            return predictForIrregularCycle(
                records: sorted,
                cycleLengths: cycleLengths,
                regularity: regularity,
                lastStart: lastStart,
                daysSinceLast: daysSinceLast
            )
        } else {
            // 较规律：使用自适应统计模型
            return predictForRegularCycle(
                records: sorted,
                cycleLengths: cycleLengths,
                regularity: regularity,
                lastStart: lastStart,
                daysSinceLast: daysSinceLast
            )
        }
    }
    
    // MARK: - 不规律周期预测（青春期/生长期专用）
    
    private static func predictForIrregularCycle(
        records: [MenstrualRecord],
        cycleLengths: [Int],
        regularity: Int,
        lastStart: Date,
        daysSinceLast: Int
    ) -> CyclePrediction {
        let calendar = Calendar.current
        
        // 历史范围：最短到最长周期
        let minCycle = cycleLengths.min() ?? 21
        let maxCycle = cycleLengths.max() ?? 45
        let avgCycle = cycleLengths.reduce(0, +) / max(1, cycleLengths.count)
        
        // 基础预测窗口（历史范围 ±3天缓冲）
        var earliest = calendar.date(byAdding: .day, value: minCycle - 3, to: lastStart)!
        var latest = calendar.date(byAdding: .day, value: maxCycle + 3, to: lastStart)!
        
        // 症状辅助修正：如果用户记录了经前症状，用症状出现时间缩小窗口
        if let symptomPrediction = symptomBasedPrediction(records: records) {
            // 症状预测与统计预测取交集
            earliest = max(earliest, calendar.date(byAdding: .day, value: -3, to: symptomPrediction)!)
            latest = min(latest, calendar.date(byAdding: .day, value: 3, to: symptomPrediction)!)
        }
        
        let today = Date()
        let daysUntilEarliest = daysBetween(today, earliest)
        let daysUntilLatest = daysBetween(today, latest)
        
        // 判断当前阶段
        let phase: CyclePhase
        let description: String
        let isAlert: Bool
        
        if daysSinceLast > maxCycle + 7 {
            phase = .overdue
            description = "已经延迟较久了，如果担心可以咨询医生"
            isAlert = true
        } else if daysSinceLast > maxCycle {
            phase = .uncertain
            description = "周期在变化中，可能快要来了"
            isAlert = true
        } else if daysSinceLast >= avgCycle - 3 {
            // 进入可能来潮窗口
            phase = .premenstrual
            if daysUntilEarliest <= 0 && daysUntilLatest >= 0 {
                description = "这几天可能要来，做好准备"
            } else if daysUntilEarliest > 0 {
                description = "大概还有 \(daysUntilEarliest)~\(daysUntilLatest) 天"
            } else {
                description = "已经进入可能来潮的时间"
            }
            isAlert = true
        } else {
            phase = .uncertain
            if cycleLengths.count < 3 {
                description = "还在建立规律中，继续记录会更好预测"
            } else {
                description = "周期比较不规律，大概还有 \(daysUntilEarliest)~\(daysUntilLatest) 天"
            }
            isAlert = false
        }
        
        return CyclePrediction(
            regularityScore: regularity,
            nextWindowEarliest: earliest, nextWindowLatest: latest,
            mostLikelyDate: nil,  // 不规律时不给出精确日期
            currentPhase: phase,
            daysUntilDescription: description,
            isPremenstrualAlert: isAlert
        )
    }
    
    // MARK: - 规律周期预测
    
    private static func predictForRegularCycle(
        records: [MenstrualRecord],
        cycleLengths: [Int],
        regularity: Int,
        lastStart: Date,
        daysSinceLast: Int
    ) -> CyclePrediction {
        let calendar = Calendar.current
        
        // 使用 EWMA（指数加权移动平均），最近3个周期权重更高
        let ewmaCycle = computeEWMA(cycleLengths, alpha: 0.4)
        let stdCycle = computeStd(cycleLengths.suffix(6))  // 最近6个周期的标准差
        
        // 预测日期 = 上次开始 + EWMA周期长度
        let predictedDate = calendar.date(byAdding: .day, value: ewmaCycle, to: lastStart)!
        
        // 置信窗口：±1.5个标准差（约86%置信度）
        let windowHalfWidth = max(2, Int(1.5 * Double(stdCycle)))
        let earliest = calendar.date(byAdding: .day, value: -windowHalfWidth, to: predictedDate)!
        let latest = calendar.date(byAdding: .day, value: windowHalfWidth, to: predictedDate)!
        
        let today = Date()
        let daysUntilPredicted = daysBetween(today, predictedDate)
        
        // 判断阶段
        let phase: CyclePhase
        let description: String
        let isAlert: Bool
        
        if daysSinceLast > ewmaCycle + windowHalfWidth + 5 {
            phase = .overdue
            description = "比预计时间延迟了，周期可能又有变化"
            isAlert = true
        } else if daysUntilPredicted <= 3 && daysUntilPredicted >= 0 {
            phase = .premenstrual
            description = daysUntilPredicted == 0 ? "预计今天可能来" : "大概还有 \(daysUntilPredicted) 天"
            isAlert = true
        } else if daysUntilPredicted < 0 {
            phase = .overdue
            description = "已经逾期 \(abs(daysUntilPredicted)) 天"
            isAlert = true
        } else if Double(daysSinceLast) < Double(ewmaCycle) * 0.5 {
            phase = .follicular
            description = "大概还有 \(daysUntilPredicted) 天"
            isAlert = false
        } else if Double(daysSinceLast) < Double(ewmaCycle) * 0.75 {
            phase = .ovulation
            description = "大概还有 \(daysUntilPredicted) 天"
            isAlert = false
        } else {
            phase = .luteal
            description = "大概还有 \(daysUntilPredicted) 天"
            isAlert = false
        }
        
        return CyclePrediction(
            regularityScore: regularity,
            nextWindowEarliest: earliest, nextWindowLatest: latest,
            mostLikelyDate: predictedDate,
            currentPhase: phase,
            daysUntilDescription: description,
            isPremenstrualAlert: isAlert
        )
    }
    
    // MARK: - 症状辅助预测
    
    /// 基于经前症状出现时间辅助预测
    private static func symptomBasedPrediction(records: [MenstrualRecord]) -> Date? {
        var offsets: [Int] = []
        
        for i in 0..<(records.count - 1) {
            let current = records[i]
            let next = records[i + 1]
            
            guard !current.symptoms.isEmpty else { continue }
            
            // 假设症状记录日期就是症状首次出现的日期（简化处理）
            // 计算症状出现到下次来潮的偏移
            let offset = daysBetween(current.startDate, next.startDate)
            offsets.append(offset)
        }
        
        guard !offsets.isEmpty else { return nil }
        
        let avgOffset = offsets.reduce(0, +) / offsets.count
        let lastRecord = records.last!
        let calendar = Calendar.current
        
        // 基于上次症状记录（如果有）或上次来潮 + 平均偏移
        return calendar.date(byAdding: .day, value: avgOffset, to: lastRecord.startDate)
    }
    
    // MARK: - 统计工具
    
    /// 计算相邻周期长度（天）
    private static func computeCycleLengths(_ records: [MenstrualRecord]) -> [Int] {
        var lengths: [Int] = []
        for i in 0..<(records.count - 1) {
            let days = daysBetween(records[i].startDate, records[i + 1].startDate)
            if days >= 10 && days <= 90 {  // 过滤异常值（<10天或>90天可能是误记录）
                lengths.append(days)
            }
        }
        return lengths
    }
    
    /// 计算规律度评分（0-100）
    /// CV < 0.05 → 95+, CV > 0.4 → <20
    private static func computeRegularity(_ lengths: [Int]) -> Int {
        guard lengths.count >= 2 else { return 0 }
        let mean = Double(lengths.reduce(0, +)) / Double(lengths.count)
        let variance = lengths.map { Double($0) - mean }.map { $0 * $0 }.reduce(0, +) / Double(lengths.count)
        let std = sqrt(variance)
        let cv = std / mean  // 变异系数
        
        let score = max(0, min(100, Int(100 - cv * 200)))
        return score
    }
    
    /// 指数加权移动平均
    private static func computeEWMA(_ values: [Int], alpha: Double) -> Int {
        guard !values.isEmpty else { return 28 }
        var result = Double(values[0])
        for i in 1..<values.count {
            result = alpha * Double(values[i]) + (1 - alpha) * result
        }
        return Int(round(result))
    }
    
    /// 标准差
    private static func computeStd(_ values: [Int]) -> Double {
        guard values.count >= 2 else { return 5 }
        let mean = Double(values.reduce(0, +)) / Double(values.count)
        let variance = values.map { pow(Double($0) - mean, 2) }.reduce(0, +) / Double(values.count)
        return sqrt(variance)
    }
    
    /// 两个日期之间的天数
    private static func daysBetween(_ from: Date, _ to: Date) -> Int {
        Calendar.current.dateComponents([.day], from: from, to: to).day ?? 0
    }
    
    // MARK: - 日历辅助
    
    /// 获取某日期对应的周期阶段（用于日历着色）
    static func phaseForDate(_ date: Date, records: [MenstrualRecord]) -> CyclePhase? {
        let sorted = records.sorted { $0.startDate < $1.startDate }
        guard let lastRecord = sorted.last else { return nil }
        
        let prediction = predict(records: sorted)
        let calendar = Calendar.current
        
        // 检查是否在已知经期
        for record in sorted {
            let daysFromStart = daysBetween(record.startDate, date)
            if daysFromStart >= 0 && daysFromStart < record.durationDays {
                return .menstruation
            }
        }
        
        // 基于预测判断未来日期
        guard let earliest = prediction.nextWindowEarliest, let latest = prediction.nextWindowLatest else { return nil }
        
        if date >= earliest && date <= latest {
            return .premenstrual
        }
        
        return nil
    }
    
    /// 生成周期档案摘要
    static func generateProfile(records: [MenstrualRecord]) -> CycleProfile {
        let sorted = records.sorted { $0.startDate < $1.startDate }
        let lengths = computeCycleLengths(sorted)
        
        // 计算平均症状偏移
        var offsets: [Int] = []
        for i in 0..<(sorted.count - 1) {
            guard !sorted[i].symptoms.isEmpty else { continue }
            offsets.append(daysBetween(sorted[i].startDate, sorted[i + 1].startDate))
        }
        
        return CycleProfile(
            menarcheDate: sorted.first?.startDate,
            totalRecords: sorted.count,
            cycleLengths: lengths,
            avgSymptomOffset: offsets.isEmpty ? nil : offsets.reduce(0, +) / offsets.count,
            needsGentleCare: computeRegularity(lengths) < 50 || sorted.count < 6
        )
    }
}
