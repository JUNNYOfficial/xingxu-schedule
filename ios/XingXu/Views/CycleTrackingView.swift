import SwiftUI

struct CycleTrackingView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    
    @State private var showAddRecord = false
    @State private var selectedDate = Date()
    @State private var selectedEndDate: Date?
    @State private var selectedFlow: FlowLevel = .medium
    @State private var selectedSymptoms: Set<CycleSymptom> = []
    @State private var notes = ""
    
    private let primaryTint = Color(red: 0.48, green: 0.61, blue: 0.75)
    
    private var prediction: CyclePrediction {
        CyclePredictor.predict(records: dataManager.menstrualRecords)
    }
    
    private var profile: CycleProfile {
        CyclePredictor.generateProfile(records: dataManager.menstrualRecords)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    predictionCard
                    statusCard
                    if !dataManager.menstrualRecords.isEmpty {
                        cycleCalendarSection
                        cycleTrendSection
                        symptomSection
                    }
                    historySection
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("周期追踪")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddRecord = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(primaryTint)
                    }
                }
            }
            .sheet(isPresented: $showAddRecord) {
                addRecordSheet
            }
        }
    }
    
    // MARK: - 预测卡片
    
    private var predictionCard: some View {
        VStack(spacing: 12) {
            // 大数字显示（固定占 60pt）
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                if let earliest = prediction.nextWindowEarliest, let _ = prediction.nextWindowLatest {
                    let daysUntil = daysBetween(Date(), earliest)
                    if daysUntil <= 0 {
                        Text("可能")
                            .font(.title2)
                        Text("快来了")
                            .font(.system(size: 42, weight: .bold))
                    } else {
                        Text("\(daysUntil)")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(prediction.isPremenstrualAlert ? Color(hex: "#D4886A") : primaryTint)
                        Text("天左右")
                            .font(.title2)
                    }
                } else {
                    VStack(spacing: 4) {
                        Text("--")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundColor(.secondary)
                        Text("还需要多记录几次")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(minHeight: 60)
            
            // 描述（固定占 22pt）
            Text(prediction.daysUntilDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(minHeight: 22)
            
            // 规律度指示器（固定占 20pt）
            HStack(spacing: 8) {
                Text("周期规律度")
                    .font(.caption)
                    .foregroundColor(.secondary)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.15))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(regularityColor)
                            .frame(width: geo.size.width * CGFloat(prediction.regularityScore) / 100)
                    }
                }
                .frame(height: 8)
                Text("\(prediction.regularityScore)")
                    .font(.caption.bold())
                    .foregroundColor(regularityColor)
                    .frame(width: 28, alignment: .trailing)
            }
            .padding(.horizontal)
            .opacity(prediction.regularityScore > 0 ? 1 : 0)
            
            // 概率窗口显示（固定占 44pt）
            HStack(spacing: 16) {
                if let earliest = prediction.nextWindowEarliest, let latest = prediction.nextWindowLatest {
                    VStack(spacing: 4) {
                        Text(formatShortDate(earliest))
                            .font(.subheadline.bold())
                        Text("最早")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Image(systemName: "arrow.right")
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 4) {
                        Text(formatShortDate(latest))
                            .font(.subheadline.bold())
                        Text("最晚")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("记录 3 次以上即可预测")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(minHeight: 44)
            
            Spacer(minLength: 0)
        }
        .frame(minHeight: 210, alignment: .top)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private var regularityColor: Color {
        switch prediction.regularityScore {
        case 0..<30: return Color(hex: "#E53E3E")
        case 30..<60: return Color(hex: "#D4886A")
        case 60..<85: return Color(hex: "#8AABBF")
        default: return Color(hex: "#7AA87B")
        }
    }
    
    // MARK: - 状态卡片
    
    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题行（固定占 24pt）
            HStack {
                Circle()
                    .fill(Color(hex: prediction.currentPhase.color))
                    .frame(width: 12, height: 12)
                Text(prediction.currentPhase.rawValue)
                    .font(.headline)
                Spacer()
            }
            .frame(minHeight: 24)
            
            // 描述（固定占 44pt，最多两行）
            Text(prediction.currentPhase.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .frame(minHeight: 44, alignment: .top)
            
            // 提示文案（固定占 56pt，最多三行）
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundColor(Color(hex: "#C27BA0"))
                Text(profile.needsGentleCare
                    ? "您的周期还在变化中，这是完全正常的。多记录几次，预测会越来越准。"
                    : "您的周期记录已足够，预测准确度较高。")
                    .font(.caption)
                    .foregroundColor(Color(hex: "#C27BA0"))
                    .lineLimit(3)
            }
            .frame(minHeight: 56, alignment: .top)
            
            Spacer(minLength: 0)
        }
        .frame(minHeight: 210, alignment: .top)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    // MARK: - 周期日历可视化
    
    private var cycleCalendarSection: some View {
        let calendar = Calendar.current
        let today = Date()
        let year = calendar.component(.year, from: today)
        let month = calendar.component(.month, from: today)
        let daysInMonth = calendar.range(of: .day, in: .month, for: today)!.count
        let firstDay = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
        let weekdayOfFirst = calendar.component(.weekday, from: firstDay)
        let offset = (weekdayOfFirst - calendar.firstWeekday + 7) % 7
        let totalCells = offset + daysInMonth
        let rows = Int(ceil(Double(totalCells) / 7.0))
        let totalGridCells = rows * 7
        let dayValues: [Int?] = Array(repeating: nil, count: offset)
            + (1...daysInMonth).map { Int($0) }
            + Array(repeating: nil, count: totalGridCells - totalCells)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("\(month)月")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                // 星期标题
                let weekdays = ["日", "一", "二", "三", "四", "五", "六"]
                HStack {
                    ForEach(weekdays, id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 日期网格
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                    ForEach(Array(dayValues.enumerated()), id: \.offset) { index, day in
                        if let day = day {
                            let dateStr = formatter.string(from: calendar.date(from: DateComponents(year: year, month: month, day: day))!)
                            let isToday = dateStr == formatter.string(from: today)
                            let isPeriod = dataManager.menstrualRecords.contains { (record: MenstrualRecord) -> Bool in
                                guard let date = formatter.date(from: dateStr) else { return false }
                                let start = record.startDate
                                let end = record.endDate ?? Calendar.current.date(byAdding: .day, value: 4, to: start)!
                                return date >= start && date <= end
                            }
                            let prediction = CyclePredictor.predict(records: dataManager.menstrualRecords)
                            let isPredicted = isInPredictedWindow(dateStr, prediction: prediction)
                            
                            ZStack {
                                if isPeriod {
                                    Circle()
                                        .fill(Color(hex: "#C27BA0").opacity(0.25))
                                        .frame(width: 34, height: 34)
                                } else if isPredicted {
                                    Circle()
                                        .stroke(Color(hex: "#D4886A").opacity(0.5), lineWidth: 1.5)
                                        .frame(width: 32, height: 32)
                                }
                                
                                if isToday {
                                    Circle()
                                        .stroke(primaryTint, lineWidth: 2)
                                        .frame(width: 32, height: 32)
                                }
                                
                                Text("\(day)")
                                    .font(.system(size: 14))
                                    .foregroundColor(isToday ? primaryTint : .primary)
                                    .fontWeight(isToday ? .bold : .regular)
                            }
                            .frame(height: 36)
                        } else {
                            Color.clear
                                .frame(height: 36)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            .padding(.horizontal)
            
            // 图例
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(hex: "#C27BA0").opacity(0.25))
                        .frame(width: 12, height: 12)
                    Text("经期")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                HStack(spacing: 4) {
                    Circle()
                        .stroke(Color(hex: "#D4886A").opacity(0.5), lineWidth: 1.5)
                        .frame(width: 12, height: 12)
                    Text("预测窗口")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                HStack(spacing: 4) {
                    Circle()
                        .stroke(primaryTint, lineWidth: 2)
                        .frame(width: 12, height: 12)
                    Text("今天")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func isInPredictedWindow(_ dateStr: String, prediction: CyclePrediction) -> Bool {
        guard let earliest = prediction.nextWindowEarliest,
              let latest = prediction.nextWindowLatest else { return false }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateStr) else { return false }
        return date >= earliest && date <= latest
    }
    
    // MARK: - 周期长度趋势
    
    private var cycleTrendSection: some View {
        let records = dataManager.menstrualRecords.sorted(by: { $0.startDate < $1.startDate })
        guard records.count >= 2 else { return AnyView(EmptyView()) }
        
        let cycleLengths = stride(from: 1, to: records.count, by: 1).map { i in
            daysBetween(records[i-1].startDate, records[i].startDate)
        }
        let maxLength = max(cycleLengths.max() ?? 1, 1)
        let avgLength = Double(cycleLengths.reduce(0, +)) / Double(cycleLengths.count)
        
        return AnyView(VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("周期长度趋势")
                    .font(.headline)
                Spacer()
                Text("平均 \(String(format: "%.1f", avgLength)) 天")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(Array(cycleLengths.enumerated()), id: \.offset) { index, length in
                    VStack(spacing: 4) {
                        Text("\(length)")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(length > Int(avgLength) + 7 ? Color(hex: "#D4886A") : Color(hex: "#8AABBF"))
                            .frame(width: 24, height: max(CGFloat(length) / CGFloat(maxLength) * 80, 4))
                        Text("第\(index + 1)次")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            .padding(.horizontal)
        })
    }
    
    // MARK: - 症状统计
    
    private var symptomSection: some View {
        var symptomCounts: [CycleSymptom: Int] = [:]
        for record in dataManager.menstrualRecords {
            for symptom in record.symptoms {
                symptomCounts[symptom, default: 0] += 1
            }
        }
        let sortedSymptoms = symptomCounts.sorted { $0.value > $1.value }.prefix(5)
        let maxCount = max(symptomCounts.values.max() ?? 1, 1)
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("常见症状")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 10) {
                ForEach(Array(sortedSymptoms), id: \.key) { symptom, count in
                    HStack(spacing: 8) {
                        Text(symptom.icon)
                            .font(.title3)
                        Text(symptom.rawValue)
                            .font(.subheadline)
                            .frame(width: 80, alignment: .leading)
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.1))
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(hex: "#C27BA0").opacity(0.4))
                                    .frame(width: geo.size.width * CGFloat(count) / CGFloat(maxCount))
                            }
                        }
                        .frame(height: 8)
                        
                        Text("\(count)次")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 32, alignment: .trailing)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            .padding(.horizontal)
        }
    }
    
    // MARK: - 历史记录
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("历史记录")
                    .font(.title3.bold())
                Spacer()
                Text("共 \(dataManager.menstrualRecords.count) 次")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            if dataManager.menstrualRecords.isEmpty {
                EmptyStateView(
                    icon: "heart.text.square",
                    title: "还没有记录",
                    subtitle: "记录第一次月经，开始了解自己的身体",
                    action: { showAddRecord = true },
                    actionTitle: "添加记录"
                )
                .padding(.horizontal)
            } else {
                VStack(spacing: 8) {
                    ForEach(dataManager.menstrualRecords.sorted(by: { $0.startDate > $1.startDate })) { record in
                        recordRow(record)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func recordRow(_ record: MenstrualRecord) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: record.flowLevel.color))
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(formatDate(record.startDate))
                    .font(.subheadline.bold())
                HStack(spacing: 6) {
                    Text("\(record.durationDays)天")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(record.flowLevel.rawValue)
                        .font(.caption)
                        .foregroundColor(Color(hex: record.flowLevel.color))
                }
                if !record.symptoms.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(record.symptoms.prefix(3), id: \.self) { symptom in
                            Text(symptom.icon)
                                .font(.caption)
                        }
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                dataManager.deleteMenstrualRecord(id: record.id)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray.opacity(0.4))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - 添加记录 Sheet
    
    private var addRecordSheet: some View {
        NavigationView {
            Form {
                Section("日期") {
                    DatePicker("开始日期", selection: $selectedDate, displayedComponents: .date)
                    
                    Toggle("设置结束日期", isOn: Binding(
                        get: { selectedEndDate != nil },
                        set: { if !$0 { selectedEndDate = nil } else { selectedEndDate = Calendar.current.date(byAdding: .day, value: 5, to: selectedDate) } }
                    ))
                    
                    if selectedEndDate != nil {
                        DatePicker("结束日期", selection: Binding(
                            get: { selectedEndDate ?? selectedDate },
                            set: { selectedEndDate = $0 }
                        ), displayedComponents: .date)
                    }
                }
                
                Section("流量") {
                    Picker("流量等级", selection: $selectedFlow) {
                        ForEach(FlowLevel.allCases, id: \.self) { level in
                            HStack {
                                Circle()
                                    .fill(Color(hex: level.color))
                                    .frame(width: 10, height: 10)
                                Text(level.rawValue)
                            }
                            .tag(level)
                        }
                    }
                }
                
                Section("症状") {
                    FlowLayout(spacing: 8) {
                        ForEach(CycleSymptom.allCases, id: \.self) { symptom in
                            Button(action: {
                                if selectedSymptoms.contains(symptom) {
                                    selectedSymptoms.remove(symptom)
                                } else {
                                    selectedSymptoms.insert(symptom)
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Text(symptom.icon)
                                    Text(symptom.rawValue)
                                        .font(.subheadline)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(selectedSymptoms.contains(symptom) ? primaryTint.opacity(0.15) : Color.gray.opacity(0.08))
                                .foregroundColor(selectedSymptoms.contains(symptom) ? primaryTint : .primary)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(selectedSymptoms.contains(symptom) ? primaryTint : Color.clear, lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Section("备注") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                }
            }
            .navigationTitle("记录月经")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        resetForm()
                        showAddRecord = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveRecord()
                        showAddRecord = false
                    }
                }
            }
        }
    }
    
    private func saveRecord() {
        let record = MenstrualRecord(
            startDate: selectedDate,
            endDate: selectedEndDate,
            flowLevel: selectedFlow,
            symptoms: Array(selectedSymptoms),
            notes: notes
        )
        dataManager.addMenstrualRecord(record)
        resetForm()
    }
    
    private func resetForm() {
        selectedDate = Date()
        selectedEndDate = nil
        selectedFlow = .medium
        selectedSymptoms = []
        notes = ""
    }
    
    // MARK: - 日期格式化
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
    }
    
    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
    
    private func daysBetween(_ from: Date, _ to: Date) -> Int {
        Calendar.current.dateComponents([.day], from: from, to: to).day ?? 0
    }
}

// MARK: - FlowLayout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}
