import SwiftUI

/// 温和呼吸练习引导（4-7-8 呼吸法）
/// 自闭症友好：无突然动画、柔和色彩、清晰倒计时、可中途退出
struct BreathingGuideView: View {
    @Environment(\.dismiss) var dismiss
    
    private let primaryTint = Color(red: 0.48, green: 0.61, blue: 0.75)
    
    // 呼吸阶段：吸气 4秒 → 屏息 7秒 → 呼气 8秒
    private let cycleSeconds = [4.0, 7.0, 8.0]
    private let phaseNames = ["吸气", "屏息", "呼气"]
    private let phaseHints = ["用鼻子慢慢吸气", "轻轻屏住呼吸", "用嘴巴慢慢呼气"]
    private let totalCycles = 5
    
    @State private var currentCycle = 1
    @State private var currentPhase = 0  // 0=吸气, 1=屏息, 2=呼气
    @State private var phaseProgress: Double = 0
    @State private var isRunning = false
    @State private var isCompleted = false
    @State private var timer: Timer? = nil
    @State private var showExitConfirm = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // 顶部信息
                VStack(spacing: 8) {
                    Text("温和呼吸")
                        .font(.title2.bold())
                    Text("\(currentCycle) / \(totalCycles) 轮")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                Spacer()
                
                // 呼吸动画圆
                ZStack {
                    // 外圈背景
                    Circle()
                        .stroke(primaryTint.opacity(0.12), lineWidth: 12)
                        .frame(width: 220, height: 220)
                    
                    // 进度圈
                    Circle()
                        .trim(from: 0, to: phaseProgress)
                        .stroke(
                            primaryTint.opacity(phaseColorOpacity),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 220, height: 220)
                        .animation(.linear(duration: 0.1), value: phaseProgress)
                    
                    // 中心内容
                    VStack(spacing: 12) {
                        Text(phaseNames[currentPhase])
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(primaryTint)
                        
                        if isRunning || isCompleted {
                            Text(phaseHints[currentPhase])
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        } else {
                            Text("按开始，跟随引导呼吸")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("\(Int(ceil(cycleSeconds[currentPhase] * (1 - phaseProgress))))")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(primaryTint.opacity(0.6))
                            .monospacedDigit()
                    }
                }
                
                Spacer()
                
                // 控制按钮
                VStack(spacing: 16) {
                    if isCompleted {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(primaryTint)
                            Text("完成了，感觉好些了吗？")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        .padding(.bottom, 8)
                        
                        Button(action: { dismiss() }) {
                            Text("关闭")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(primaryTint)
                                .cornerRadius(16)
                        }
                    } else if !isRunning {
                        Button(action: startBreathing) {
                            Text("开始")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(primaryTint)
                                .cornerRadius(16)
                        }
                    } else {
                        Button(action: { showExitConfirm = true }) {
                            Text("停止")
                                .font(.headline)
                                .foregroundColor(primaryTint)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(primaryTint.opacity(0.12))
                                .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .alert("确认停止", isPresented: $showExitConfirm) {
                Button("继续呼吸", role: .cancel) {}
                Button("停止", role: .destructive) {
                    stopBreathing()
                    dismiss()
                }
            } message: {
                Text("呼吸练习可以帮助平复情绪，确定要停止吗？")
            }
        }
    }
    
    private var phaseColorOpacity: Double {
        switch currentPhase {
        case 0: return 0.5 + phaseProgress * 0.5   // 吸气：从浅到深
        case 1: return 1.0                          // 屏息：稳定
        case 2: return 1.0 - phaseProgress * 0.5    // 呼气：从深到浅
        default: return 0.5
        }
    }
    
    private func startBreathing() {
        isRunning = true
        currentCycle = 1
        currentPhase = 0
        phaseProgress = 0
        runPhase()
    }
    
    private func runPhase() {
        guard isRunning else { return }
        
        let duration = cycleSeconds[currentPhase]
        let interval = 0.05
        var elapsed: Double = 0
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { t in
            guard isRunning else {
                t.invalidate()
                return
            }
            
            elapsed += interval
            phaseProgress = min(elapsed / duration, 1.0)
            
            if elapsed >= duration {
                t.invalidate()
                advancePhase()
            }
        }
    }
    
    private func advancePhase() {
        if currentPhase < 2 {
            currentPhase += 1
            phaseProgress = 0
            runPhase()
        } else {
            if currentCycle < totalCycles {
                currentCycle += 1
                currentPhase = 0
                phaseProgress = 0
                runPhase()
            } else {
                isRunning = false
                isCompleted = true
                timer?.invalidate()
                timer = nil
                
                // 完成时轻震反馈
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
    }
    
    private func stopBreathing() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
}
