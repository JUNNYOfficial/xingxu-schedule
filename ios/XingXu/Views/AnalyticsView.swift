import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var rangeDays = 7
    
    private var stats: DailyStats {
        dataManager.stats(forDays: rangeDays)
    }
    
    private var cycleCorrelation: CycleCorrelationResult {
        CycleCorrelationAnalyzer.analyze(
            records: dataManager.menstrualRecords,
            moods: dataManager.moods,
            tasks: dataManager.tasks
        )
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 时间范围选择
                    rangePicker
                    
                    // 概览卡片
                    overviewCards
                    
                    // 完成率趋势
                    trendChart
                    
                    // 时段分析
                    hourChart
                    
                    // 标签分布
                    tagDistribution
                    
                    // 周期关联分析
                    cycleCorrelationSection
                    
                    // 建议
                    insights
                }
                .padding()
            }
            .navigationTitle("数据分析")
        }
    }
    
    private var rangePicker: some View {
        HStack(spacing: 8) {
            ForEach([7, 14, 30], id: \.self) { days in
                Button(action: { rangeDays = days }) {
                    Text("近\(days)天")
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(rangeDays == days ? Color.primary : Color(.systemGray6))
                        .foregroundColor(rangeDays == days ? Color(.systemBackground) : .primary)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("查看近\(days)天数据")
                .accessibilityAddTraits(rangeDays == days ? .isSelected : [])
            }
        }
    }
    
    private let tint = Color(red: 0.48, green: 0.61, blue: 0.75)
    
    private var overviewCards: some View {
        let s = stats
        let cards: [(String, String)] = [
            ("\(s.totalTasks)", "总任务"),
            ("\(s.completedTasks)", "已完成"),
            ("\(Int(s.completionRate))%", "完成率"),
            ("\(s.dailyData.filter { $0.total > 0 }.count)天", "活跃天数")
        ]
        
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(cards, id: \.1) { card in
                VStack(spacing: 4) {
                    Text(card.0)
                        .font(.title2.bold())
                        .foregroundColor(tint)
                    Text(card.1)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
    
    private var trendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("完成率趋势")
                .font(.headline)
            
            if stats.dailyData.allSatisfy({ $0.total == 0 }) {
                EmptyStateView(
                    icon: "chart.bar",
                    title: "暂无趋势数据",
                    subtitle: "添加并完成任务后，这里会显示完成率趋势"
                )
            } else {
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(stats.dailyData, id: \.date) { day in
                        VStack(spacing: 4) {
                            if day.total > 0 {
                                let rate = Double(day.completed) / Double(day.total)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(tint.opacity(rate >= 0.5 ? 0.8 : 0.4))
                                    .frame(height: max(4, rate * 120))
                            } else {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 4)
                            }
                            Text(String(day.date.suffix(2)))
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 160)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var hourChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("时段分析")
                .font(.headline)
            
            let displayHours = 6...22
            let hasAnyData = displayHours.contains { stats.hourStats[$0]?.total ?? 0 > 0 }
            if !hasAnyData {
                EmptyStateView(
                    icon: "clock",
                    title: "暂无时段数据",
                    subtitle: "添加带时间的任务后，可查看哪个时段效率最高"
                )
            } else {
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(Array(displayHours), id: \.self) { hour in
                        let stat = stats.hourStats[hour] ?? (total: 0, completed: 0)
                        let rate = stat.total > 0 ? Double(stat.completed) / Double(stat.total) : 0
                        VStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(stat.total == 0 ? Color.gray.opacity(0.1) : tint.opacity(rate >= 0.8 ? 0.9 : rate >= 0.5 ? 0.6 : 0.3))
                                .frame(height: max(4, CGFloat(stat.total) * 15))
                            Text("\(hour)")
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 120)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var tagDistribution: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("标签分布")
                .font(.headline)
            
            if stats.tagStats.isEmpty {
                EmptyStateView(
                    icon: "tag",
                    title: "暂无标签数据",
                    subtitle: "为任务添加标签后，可查看各类任务的分布"
                )
            } else {
                let sortedTags = stats.tagStats.sorted(by: { $0.value > $1.value })
                let tagColors: [Color] = [
                    tint, tint.opacity(0.8), tint.opacity(0.6),
                    tint.opacity(0.5), tint.opacity(0.4), tint.opacity(0.3), tint.opacity(0.25)
                ]
                ForEach(Array(sortedTags.enumerated()), id: \.offset) { index, item in
                    let (tag, count) = item
                    HStack(spacing: 12) {
                        Circle()
                            .fill(tagColors[index % tagColors.count])
                            .frame(width: 10, height: 10)
                        Text(tag.isEmpty ? "未分类" : tag)
                            .font(.subheadline)
                        Spacer()
                        Text("\(count)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - 周期关联分析
    
    private var cycleCorrelationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🩸 周期与身心关联")
                .font(.headline)
            
            if !cycleCorrelation.hasEnoughData {
                EmptyStateView(
                    icon: "drop",
                    title: "数据积累中",
                    subtitle: "记录更多月经周期、心情和任务后，可发现周期对身心状态的影响"
                )
            } else {
                // 心情按周期阶段
                if !cycleCorrelation.moodByPhase.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("各阶段心情")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(alignment: .bottom, spacing: 8) {
                            ForEach(cycleCorrelation.moodByPhase.filter { $0.sampleCount > 0 }, id: \.phaseName) { item in
                                VStack(spacing: 4) {
                                    Text(String(format: "%.1f", item.avgMood))
                                        .font(.caption.bold())
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(phaseColor(item.phaseName).opacity(0.7))
                                        .frame(height: max(8, CGFloat(item.avgMood) * 20))
                                    Text(item.phaseName)
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                    Text("n=\(item.sampleCount)")
                                        .font(.system(size: 8))
                                        .foregroundColor(.secondary.opacity(0.7))
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(height: 100)
                    }
                }
                
                // 完成率按周期阶段
                if !cycleCorrelation.completionRateByPhase.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("各阶段完成率")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(alignment: .bottom, spacing: 8) {
                            ForEach(cycleCorrelation.completionRateByPhase.filter { $0.totalTasks > 0 }, id: \.phaseName) { item in
                                VStack(spacing: 4) {
                                    Text("\(Int(item.rate))%")
                                        .font(.caption.bold())
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(phaseColor(item.phaseName).opacity(0.7))
                                        .frame(height: max(8, CGFloat(item.rate) * 0.8))
                                    Text(item.phaseName)
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(height: 80)
                    }
                }
                
                // 洞察建议
                ForEach(cycleCorrelation.insights, id: \.self) { insight in
                    Text(insight)
                        .font(.caption)
                        .padding(10)
                        .background(phaseColor("洞察").opacity(0.08))
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func phaseColor(_ phase: String) -> Color {
        switch phase {
        case "月经期": return Color(hex: "#C27BA0")
        case "卵泡期": return Color(hex: "#8AABBF")
        case "排卵期": return Color(hex: "#7AA87B")
        case "黄体期": return Color(hex: "#D4A76A")
        case "经前期": return Color(hex: "#D4886A")
        default: return Color(red: 0.48, green: 0.61, blue: 0.75)
        }
    }
    
    private var insightTexts: [String] {
        let s = stats
        var result: [String] = []
        
        if s.totalTasks == 0 {
            result.append("继续使用，数据积累后会生成个性化分析建议。")
        } else {
            if s.completionRate >= 85 {
                result.append("🌟 表现优秀：完成率高达 \(Int(s.completionRate))%，可以适量增加挑战性任务。")
            } else if s.completionRate >= 60 {
                result.append("👍 表现良好：完成率 \(Int(s.completionRate))%，继续保持！")
            } else {
                result.append("💪 有待提升：完成率 \(Int(s.completionRate))%，建议减少每日任务数量，聚焦重点。")
            }
            
            let activeDays = s.dailyData.filter { $0.total > 0 }.count
            if activeDays < rangeDays / 2 {
                result.append("📅 使用频率：近 \(rangeDays) 天中只有 \(activeDays) 天有记录，建议养成每日查看日程的习惯。")
            }
        }
        
        return result
    }
    
    private var insights: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("💡 智能建议")
                .font(.headline)
            
            ForEach(insightTexts, id: \.self) { insight in
                Text(insight)
                    .font(.subheadline)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .accessibilityLabel(insight)
            }
        }
    }
}
