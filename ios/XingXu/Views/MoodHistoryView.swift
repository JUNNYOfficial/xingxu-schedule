import SwiftUI

struct MoodHistoryView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var rangeDays = 7
    @State private var showMoodPicker = false
    
    private var filteredMoods: [MoodEntry] {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -(rangeDays - 1), to: endDate) else {
            return []
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        return dataManager.moods
            .filter { mood in
                guard let moodDate = formatter.date(from: mood.date) else { return false }
                return moodDate >= startDate && moodDate <= endDate
            }
            .sorted { $0.date < $1.date }
    }
    
    private var averageMood: Double {
        guard !filteredMoods.isEmpty else { return 0 }
        return Double(filteredMoods.reduce(0) { $0 + $1.value }) / Double(filteredMoods.count)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 时间范围选择
                rangePicker
                
                // 平均心情
                averageMoodCard
                
                // 心情趋势图
                moodChart
                
                // 详细记录列表
                moodList
            }
            .padding()
        }
        .navigationTitle("心情与健康")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showMoodPicker = true }) {
                    Image(systemName: "plus")
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $showMoodPicker) {
            MoodPickerView(date: dataManager.currentDate)
        }
    }
    
    // MARK: - Range Picker
    
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
    
    // MARK: - Average Mood Card
    
    private var averageMoodCard: some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                if averageMood > 0 {
                    Text(String(format: "%.1f", averageMood))
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(moodColor(for: averageMood))
                } else {
                    Text("—")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.secondary)
                }
                Text("平均心情")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            VStack(spacing: 4) {
                Text("\(filteredMoods.count)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.indigo)
                Text("记录次数")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Mood Chart
    
    private var moodChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("心情趋势")
                .font(.headline)
            
            if filteredMoods.isEmpty {
                Text("暂无数据")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(filteredMoods) { mood in
                        VStack(spacing: 4) {
                            Text(mood.emoji)
                                .font(.title3)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: mood.color).opacity(0.4))
                                .frame(width: 28, height: max(8, CGFloat(mood.value) * 14))
                            Text(shortDate(mood.date))
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                                .rotationEffect(.degrees(-45))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 140)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Mood List
    
    private var moodList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("详细记录")
                .font(.headline)
            
            if filteredMoods.isEmpty {
                Text("暂无心情记录")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                VStack(spacing: 0) {
                    ForEach(filteredMoods) { mood in
                        HStack(spacing: 12) {
                            Text(mood.emoji)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(formattedDate(mood.date))
                                    .font(.body)
                                if !mood.note.isEmpty {
                                    Text(mood.note)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            
                            Spacer()
                            
                            Text("\(mood.value)/5")
                                .font(.subheadline)
                                .foregroundColor(Color(hex: mood.color))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color(hex: mood.color).opacity(0.12))
                                .cornerRadius(8)
                        }
                        .padding()
                        
                        if mood.id != filteredMoods.last?.id {
                            Divider()
                                .padding(.leading)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func moodColor(for value: Double) -> Color {
        switch value {
        case 0..<2: return Color(red: 0.9, green: 0.5, blue: 0.5)
        case 2..<3: return Color(red: 1.0, green: 0.7, blue: 0.3)
        case 3..<4: return .mint
        default: return Color(red: 0.5, green: 0.72, blue: 0.85)
        }
    }
    
    private func shortDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return "" }
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
    
    private func formattedDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
}
