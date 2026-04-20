import SwiftUI

/// 正念冥想引导
/// 自闭症友好：极简界面、单一视觉焦点、大按钮、柔和配色、随时可退出
struct MindfulnessView: View {
    @Environment(\.dismiss) var dismiss
       
    private let primaryTint = Color(red: 0.48, green: 0.61, blue: 0.75)
    
    private let durationOptions = [
        (60, "1分钟", "快速放松"),
        (180, "3分钟", "短暂休息"),
        (300, "5分钟", "日常正念"),
        (600, "10分钟", "深度放松"),
        (900, "15分钟", "专注练习"),
        (1200, "20分钟", "完整冥想")
    ]
    
    @State private var selectedDuration: Int? = nil
    @State private var isMeditating = false
    @State private var timeRemaining: Int = 0
    @State private var totalDuration: Int = 0
    @State private var timer: Timer? = nil
    @State private var isCompleted = false
    @State private var showExitConfirm = false
    
    var body: some View {
        NavigationView {
            Group {
                if isCompleted {
                    completionView
                } else if isMeditating {
                    meditationView
                } else {
                    durationSelectionView
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("正念冥想")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !isMeditating && !isCompleted {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("关闭") { dismiss() }
                    }
                }
            }
            .alert("确认退出", isPresented: $showExitConfirm) {
                Button("继续冥想", role: .cancel) {}
                Button("退出", role: .destructive) {
                    stopMeditation()
                }
            } message: {
                Text("退出后本次冥想不会保存。确定要退出吗？")
            }
        }
    }
    
    // MARK: - 时长选择
    
    private var durationSelectionView: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 48))
                        .foregroundColor(primaryTint)
                    Text("选择一个时长开始")
                        .font(.title2.bold())
                    Text("找一个安静的地方，放松身体，专注于呼吸")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 24)
                
                VStack(spacing: 12) {
                    ForEach(durationOptions, id: \.0) { option in
                        Button(action: {
                            startMeditation(duration: option.0)
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(option.1)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(option.2)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(primaryTint)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 40)
            }
        }
    }
    
    // MARK: - 冥想中
    
    private var meditationView: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // 大圆环倒计时
                ZStack {
                    Circle()
                        .stroke(primaryTint.opacity(0.1), lineWidth: 12)
                        .frame(width: 240, height: 240)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            primaryTint.opacity(0.4),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 240, height: 240)
                        .animation(.linear(duration: 0.5), value: progress)
                    
                    // 呼吸提示圆
                    Circle()
                        .fill(primaryTint.opacity(0.08))
                        .frame(width: 160 + breathingScale * 20, height: 160 + breathingScale * 20)
                        .animation(.easeInOut(duration: 4), value: breathingScale)
                    
                    VStack(spacing: 8) {
                        Text(formattedTime(timeRemaining))
                            .font(.system(size: 56, weight: .light, design: .rounded))
                            .foregroundColor(primaryTint)
                            .monospacedDigit()
                        
                        Text(breathingHint)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 提示语
                Text("把注意力放在呼吸上\n如果走神了，温柔地把它带回来")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                // 停止按钮
                Button(action: { showExitConfirm = true }) {
                    Text("停止")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .frame(width: 120, height: 48)
                        .background(Color.gray.opacity(0.12))
                        .cornerRadius(24)
                }
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            startBreathingAnimation()
        }
    }
    
    // MARK: - 完成页面
    
    private var completionView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(primaryTint)
            
            VStack(spacing: 8) {
                Text("冥想完成")
                    .font(.title2.bold())
                Text("本次正念时长：\(formattedTime(totalDuration))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text("正念时间已同步到 Apple 健康")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Text("完成")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(primaryTint)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - 逻辑
    
    private var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return Double(totalDuration - timeRemaining) / Double(totalDuration)
    }
    
    private var breathingScale: CGFloat {
        guard totalDuration > 0 else { return 0 }
        let cycle = 4.0 // 4秒一个呼吸周期
        let t = Double(totalDuration - timeRemaining).truncatingRemainder(dividingBy: cycle)
        return CGFloat(sin(t / cycle * .pi))
    }
    
    private var breathingHint: String {
        guard totalDuration > 0 else { return "" }
        let cycle = 4.0
        let t = Double(totalDuration - timeRemaining).truncatingRemainder(dividingBy: cycle)
        if t < 2 {
            return "吸气"
        } else {
            return "呼气"
        }
    }
    
    private func startMeditation(duration: Int) {
        selectedDuration = duration
        totalDuration = duration
        timeRemaining = duration
        isMeditating = true
        
        // 触觉反馈
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                completeMeditation()
            }
        }
    }
    
    private func startBreathingAnimation() {
        // 呼吸动画由 breathingScale 自动驱动
    }
    
    private func completeMeditation() {
        timer?.invalidate()
        timer = nil
        isMeditating = false
        isCompleted = true
        
        // 同步到 HealthKit
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .second, value: -totalDuration, to: endDate)!
        Task {
            await HealthManager.shared.saveMindfulSession(startDate: startDate, endDate: endDate)
        }
        
        // 完成触觉反馈
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func stopMeditation() {
        timer?.invalidate()
        timer = nil
        isMeditating = false
        timeRemaining = 0
        dismiss()
    }
    
    private func formattedTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        if m > 0 {
            return String(format: "%d:%02d", m, s)
        }
        return String(format: "%d秒", s)
    }
}
