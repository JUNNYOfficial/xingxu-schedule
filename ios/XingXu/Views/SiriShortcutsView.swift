import SwiftUI
import AppIntents

struct SiriShortcutsView: View {
    @Environment(\.dismiss) var dismiss
    
    private let primaryTint = Color(red: 0.48, green: 0.61, blue: 0.75)
    
    private let examples = [
        ("添加日程", "嘿 Siri，用星序记录明天上午9点数学课", "添加任务到指定日期和时间"),
        ("添加日程", "嘿 Siri，在星序记录下午3点看医生", "添加今天某时间的任务"),
        ("添加日程", "嘿 Siri，用星序记录周末去超市", "添加后天/周末的任务"),
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 顶部图标
                    VStack(spacing: 12) {
                        Image(systemName: "mic.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(primaryTint)
                        Text("Siri 快捷指令")
                            .font(.title2.bold())
                        Text("用语音快速添加日程，不用打字")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 24)
                    
                    // 示例列表
                    VStack(alignment: .leading, spacing: 12) {
                        Text("可以这样说")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 10) {
                            ForEach(examples, id: \.1) { example in
                                HStack(spacing: 12) {
                                    Image(systemName: "waveform")
                                        .font(.title3)
                                        .foregroundColor(primaryTint)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\"\(example.1)\"")
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                        Text(example.2)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // 设置提示
                    VStack(alignment: .leading, spacing: 12) {
                        Text("如何设置")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            stepRow(number: 1, text: "点击下方的\"添加到Siri\"按钮")
                            stepRow(number: 2, text: "录制你的语音指令，如\"记录数学课\"")
                            stepRow(number: 3, text: "之后对 Siri 说这句话即可自动添加")
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 20)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Siri 快捷指令")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
    
    private func stepRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.bold())
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(primaryTint)
                .cornerRadius(12)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}
