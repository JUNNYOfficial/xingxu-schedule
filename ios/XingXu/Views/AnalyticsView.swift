import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var rangeDays = 7
    
    private var stats: DailyStats {
        dataManager.stats(forDays: rangeDays)
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
            }
        }
    }
    
    private var overviewCards: some View {
        let s = stats
        let cards: [(String, String, Color)] = [
            ("\(s.totalTasks)", "总任务", .indigo),
            ("\(s.completedTasks)", "已完成", .mint),
            ("\(Int(s.completionRate))%", "完成率", Color(red: 0.5, green: 0.72, blue: 0.85)),
            ("\(s.dailyData.filter { $0.total > 0 }.count)天", "活跃天数", Color(red: 0.6, green: 0.5, blue: 0.9))
        ]
        
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(cards, id: \.1) { card in
                VStack(spacing: 4) {
                    Text(card.0)
                        .font(.title2.bold())
                        .foregroundColor(card.2)
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
                Text("暂无数据")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(stats.dailyData, id: \.date) { day in
                        VStack(spacing: 4) {
                            if day.total > 0 {
                                let rate = Double(day.completed) / Double(day.total)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(rate >= 1.0 ? Color.mint : rate >= 0.5 ? Color(red: 0.5, green: 0.72, blue: 0.85) : Color(red: 1.0, green: 0.7, blue: 0.3))
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
                Text("暂无数据")
                    .foregroundColor(.secondary)
            } else {
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(Array(displayHours), id: \.self) { hour in
                        let stat = stats.hourStats[hour] ?? (total: 0, completed: 0)
                        let rate = stat.total > 0 ? Double(stat.completed) / Double(stat.total) : 0
                        VStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(stat.total == 0 ? Color.gray.opacity(0.1) : (rate >= 0.8 ? Color.mint : rate >= 0.5 ? Color(red: 0.5, green: 0.72, blue: 0.85) : Color(red: 1.0, green: 0.7, blue: 0.3)))
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
                Text("暂无数据")
                    .foregroundColor(.secondary)
            } else {
                let sortedTags = stats.tagStats.sorted(by: { $0.value > $1.value })
                let tagColors: [Color] = [.mint, Color(red: 0.5, green: 0.72, blue: 0.85), .indigo, Color(red: 0.9, green: 0.6, blue: 0.4), Color(red: 0.6, green: 0.5, blue: 0.9), .teal, Color(red: 0.95, green: 0.65, blue: 0.7)]
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
            }
        }
    }
}
