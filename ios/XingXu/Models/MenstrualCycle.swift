import Foundation

/// 月经流量等级
enum FlowLevel: String, Codable, CaseIterable {
    case spotting = "点滴"
    case light = "少"
    case medium = "中"
    case heavy = "多"
    case veryHeavy = "很多"
    
    var color: String {
        switch self {
        case .spotting: return "#B8C5D0"
        case .light: return "#8FABBF"
        case .medium: return "#6B8BA3"
        case .heavy: return "#5A7A94"
        case .veryHeavy: return "#4A6A82"
        }
    }
}

/// 经前/经期症状
enum CycleSymptom: String, Codable, CaseIterable {
    case moodSwings = "情绪波动"
    case irritability = "易怒"
    case anxiety = "焦虑"
    case fatigue = "疲劳"
    case cramps = "腹痛"
    case backPain = "腰酸"
    case headache = "头痛"
    case breastTenderness = "乳房胀痛"
    case bloating = "腹胀"
    case acne = "长痘"
    case insomnia = "失眠"
    case foodCravings = "食欲变化"
    case sensorySensitivity = "感官敏感"
    case socialWithdrawal = "社交退缩"
    
    var icon: String {
        switch self {
        case .moodSwings: return "🎭"
        case .irritability: return "😤"
        case .anxiety: return "😰"
        case .fatigue: return "😴"
        case .cramps: return "🤕"
        case .backPain: return "🦴"
        case .headache: return "🤯"
        case .breastTenderness: return "⚠️"
        case .bloating: return "🎈"
        case .acne: return "🔴"
        case .insomnia: return "🌙"
        case .foodCravings: return "🍫"
        case .sensorySensitivity: return "👂"
        case .socialWithdrawal: return "🏠"
        }
    }
}

/// 单次月经记录
struct MenstrualRecord: Codable, Identifiable, Equatable {
    var id: String
    var startDate: Date
    var endDate: Date?
    var flowLevel: FlowLevel
    var symptoms: [CycleSymptom]
    var notes: String
    var createdAt: Date
    var modifiedAt: Date
    
    init(
        id: String = UUID().uuidString,
        startDate: Date,
        endDate: Date? = nil,
        flowLevel: FlowLevel = .medium,
        symptoms: [CycleSymptom] = [],
        notes: String = "",
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.flowLevel = flowLevel
        self.symptoms = symptoms
        self.notes = notes
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
    
    /// 经期持续天数
    var durationDays: Int {
        guard let end = endDate else { return 5 }
        let days = Calendar.current.dateComponents([.day], from: startDate, to: end).day ?? 5
        return max(1, days + 1)
    }
}

/// 周期阶段
enum CyclePhase: String, Codable {
    case noData = "暂无数据"
    case menstruation = "月经期"
    case follicular = "卵泡期"
    case ovulation = "排卵期"
    case luteal = "黄体期"
    case premenstrual = "经前期"
    case uncertain = "阶段不明"
    case overdue = "已逾期"
    case establishing = "建立规律中"
    
    var description: String {
        switch self {
        case .noData: return "记录您的第一次月经，开始追踪"
        case .menstruation: return "注意保暖，适当休息"
        case .follicular: return "精力恢复期，适合安排活动"
        case .ovulation: return "注意身体信号"
        case .luteal: return "情绪可能波动，多关爱自己"
        case .premenstrual: return "经前不适期，减少压力"
        case .uncertain: return "周期还在变化中，持续记录"
        case .overdue: return "如果延迟较久，可考虑咨询医生"
        case .establishing: return "初潮后周期需要时间稳定，这是正常的"
        }
    }
    
    var color: String {
        switch self {
        case .noData: return "#9CA3AF"
        case .menstruation: return "#C27BA0"
        case .follicular: return "#8AABBF"
        case .ovulation: return "#7AA87B"
        case .luteal: return "#D4A76A"
        case .premenstrual: return "#D4886A"
        case .uncertain: return "#A0AEC0"
        case .overdue: return "#E53E3E"
        case .establishing: return "#9F7AEA"
        }
    }
}

/// 周期预测结果
struct CyclePrediction: Codable, Equatable {
    /// 规律度评分 0-100（0=极不规律/数据不足，100=非常规律）
    var regularityScore: Int
    /// 下次最早可能来潮日期
    var nextWindowEarliest: Date?
    /// 下次最晚可能来潮日期
    var nextWindowLatest: Date?
    /// 预计最可能来潮日期
    var mostLikelyDate: Date?
    /// 当前阶段
    var currentPhase: CyclePhase
    /// 距离下次来潮的描述（针对青春期不固定周期的友好文案）
    var daysUntilDescription: String
    /// 是否处于预警期（经前3-7天）
    var isPremenstrualAlert: Bool
}

/// 用户周期档案（用于长期追踪趋势）
struct CycleProfile: Codable, Equatable {
    /// 初潮日期
    var menarcheDate: Date?
    /// 总记录次数
    var totalRecords: Int
    /// 历史周期长度统计
    var cycleLengths: [Int]  // 天数
    /// 平均症状偏移天数（症状首次出现距下次来潮的平均天数）
    var avgSymptomOffset: Int?
    /// 是否需要特别关怀（青春期、不规律等）
    var needsGentleCare: Bool
}
