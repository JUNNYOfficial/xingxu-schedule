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
            ("\(s.totalTasks)", "总任务", .blue),
            ("\(s.completedTasks)", "已完成", .green),
            ("\(Int(s.completionRate))%", "完成率", .orange),
            ("\(s.dailyData.filter { $0.total > 0 }.count)天", "活跃天数", .purple)
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
                                    .fill(rate >= 1.0 ? Color.green : rate >= 0.5 ? Color.orange : Color.red)
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
            
            let activeHours = stats.hourStats.filter { $0.value.total > 0 }
            if activeHours.isEmpty {
                Text("暂无数据")
                    .foregroundColor(.secondary)
            } else {
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(activeHours.sorted(by: { $0.key < $1.key }), id: \.key) { hour, stat in
                        let rate = Double(stat.completed) / Double(stat.total)
                        VStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(rate >= 0.8 ? Color.green : rate >= 0.5 ? Color.orange : Color.red)
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
                ForEach(stats.tagStats.sorted(by: { $0.value > $1.value }), id: \.key) { tag, count in
                    HStack {
                        Text(tag.isEmpty ? "未分类" : tag)
                            .font(.subheadline)
                        Spacer()
                        Text("\(count)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var insights: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("💡 智能建议")
                .font(.headline)
            
            let s = stats
            var insights: [String] = []
            
            if s.totalTasks == 0 {
                insights.append("继续使用，数据积累后会生成个性化分析建议。")
            } else {
                if s.completionRate >= 85 {
                    insights.append("🌟 表现优秀：完成率高达 \(Int(s.completionRate))%，可以适量增加挑战性任务。")
                } else if s.completionRate >= 60 {
                    insights.append("👍 表现良好：完成率 \(Int(s.completionRate))%，继续保持！")
                } else {
                    insights.append("💪 有待提升：完成率 \(Int(s.completionRate))%，建议减少每日任务数量，聚焦重点。")
                }
                
                let activeDays = s.dailyData.filter { $0.total > 0 }.count
                if activeDays < rangeDays / 2 {
                    insights.append("📅 使用频率：近 \(rangeDays) 天中只有 \(activeDays) 天有记录，建议养成每日查看日程的习惯。")
                }
            }
            
            ForEach(insights, id: \.self) { insight in
                Text(insight)
                    .font(.subheadline)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
        }
    }
}
