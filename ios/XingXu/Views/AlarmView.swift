import SwiftUI

/// 全屏闹钟提醒
/// 自闭症友好：超大字体、高对比度按钮、无闪烁、温和配色
struct AlarmView: View {
    @EnvironmentObject var dataManager: DataManager
    
    let task: TaskItem
    
    private let primaryTint = Color(red: 0.48, green: 0.61, blue: 0.75)
    
    @State private var currentTime = ""
    @State private var timer: Timer? = nil
    
    var body: some View {
        ZStack {
            // 背景：柔和的蓝灰色，带轻微渐变
            LinearGradient(
                colors: [
                    Color(red: 0.38, green: 0.51, blue: 0.65),
                    Color(red: 0.48, green: 0.61, blue: 0.75)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // 图标
                Image(systemName: "alarm.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.white.opacity(0.9))
                
                // 当前时间（大字）
                Text(currentTime)
                    .font(.system(size: 72, weight: .light, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()
                    .minimumScaleFactor(0.7)
                
                VStack(spacing: 16) {
                    // 任务名称
                    Text("「\(task.name)」")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    // 任务时间
                    Text("开始时间：\(task.displayTime)")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.85))
                }
                
                if !task.subSteps.isEmpty {
                    VStack(spacing: 8) {
                        Text("步骤提醒")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(task.subSteps.prefix(3)) { step in
                                HStack(spacing: 8) {
                                    Image(systemName: step.completed ? "checkmark.circle.fill" : "circle")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                    Text(step.title)
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.9))
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(16)
                }
                
                Spacer()
                
                // 操作按钮区
                VStack(spacing: 16) {
                    // 关闭按钮
                    Button(action: dismissAlarm) {
                        Text("我知道了")
                            .font(.title3.bold())
                            .foregroundColor(primaryTint)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.white)
                            .cornerRadius(16)
                    }
                    
                    // 稍后提醒（5分钟后）
                    Button(action: snoozeAlarm) {
                        Text("5分钟后再提醒")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            updateTime()
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                updateTime()
            }
            // 触觉反馈
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
        .statusBar(hidden: true)
    }
    
    private func updateTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        currentTime = formatter.string(from: Date())
    }
    
    private func dismissAlarm() {
        dataManager.activeAlarmTask = nil
    }
    
    private func snoozeAlarm() {
        // 5分钟后再次提醒
        let content = UNMutableNotificationContent()
        content.title = "星序"
        content.body = "「\(task.name)」快要开始了"
        content.sound = .default
        content.userInfo = ["taskId": task.id, "taskName": task.name, "taskTime": task.time, "fullscreenAlarm": true]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5 * 60, repeats: false)
        let request = UNNotificationRequest(identifier: "\(task.id)_snooze", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
        
        dataManager.activeAlarmTask = nil
    }
}
