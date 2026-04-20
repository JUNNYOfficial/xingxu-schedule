import SwiftUI

struct WaterTrackerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    private let primaryTint = Color(red: 0.48, green: 0.61, blue: 0.75)
    private let waterBlue = Color(red: 0.42, green: 0.65, blue: 0.85)
    
    private var todayRecords: [WaterRecord] {
        dataManager.waterRecords.filter { $0.date == dataManager.currentDate }
    }
    
    private var todayTotal: Int {
        todayRecords.reduce(0) { $0 + $1.amount }
    }
    
    private var goal: Int {
        dataManager.settings.dailyWaterGoal
    }
    
    private var progress: Double {
        min(Double(todayTotal) / Double(goal), 1.0)
    }
    
    @State private var animateDrop = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // 大圆环进度
                    ZStack {
                        Circle()
                            .stroke(waterBlue.opacity(0.12), lineWidth: 16)
                            .frame(width: 200, height: 200)
                        
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                waterBlue,
                                style: StrokeStyle(lineWidth: 16, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 200, height: 200)
                            .animation(.easeInOut(duration: 0.5), value: progress)
                        
                        VStack(spacing: 4) {
                            Text("\(todayTotal)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(waterBlue)
                            Text("/ \(goal) ml")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("\(Int(progress * 100))%")
                                .font(.caption)
                                .foregroundColor(waterBlue.opacity(0.7))
                                .contentTransition(.numericText())
                        }
                    }
                    .padding(.top, 24)
                    
                    // 快速添加按钮
                    VStack(spacing: 16) {
                        Button(action: addWater) {
                            HStack(spacing: 8) {
                                Image(systemName: "drop.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .rotationEffect(.degrees(animateDrop ? 15 : -15))
                                    .animation(.easeInOut(duration: 0.3), value: animateDrop)
                                Text("喝一杯 (+250ml)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(waterBlue)
                            .cornerRadius(16)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        HStack(spacing: 12) {
                            quickAddButton(amount: 100, label: "小口")
                            quickAddButton(amount: 250, label: "一杯")
                            quickAddButton(amount: 500, label: "一瓶")
                        }
                    }
                    .padding(.horizontal)
                    
                    // 今日记录
                    if !todayRecords.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("今日记录")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 8) {
                                ForEach(todayRecords.sorted(by: { $0.timestamp > $1.timestamp })) { record in
                                    HStack {
                                        Image(systemName: "drop.fill")
                                            .foregroundColor(waterBlue.opacity(0.6))
                                        Text("\(record.amount) ml")
                                            .font(.subheadline)
                                        Spacer()
                                        Text(formatTime(record.timestamp))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Button(action: {
                                            dataManager.deleteWaterRecord(id: record.id)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.gray.opacity(0.3))
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("饮水记录")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
    
    private func quickAddButton(amount: Int, label: String) -> some View {
        Button(action: {
            dataManager.addWaterRecord(amount)
        }) {
            VStack(spacing: 4) {
                Text("+\(amount)")
                    .font(.subheadline.bold())
                Text(label)
                    .font(.caption2)
            }
            .foregroundColor(waterBlue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(waterBlue.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func addWater() {
        animateDrop.toggle()
        dataManager.addWaterRecord(250)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
