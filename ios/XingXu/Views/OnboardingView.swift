import SwiftUI

struct OnboardingView: View {
    @AppStorage("xingxu_has_seen_onboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0
    
    private let primaryTint = Color(red: 0.48, green: 0.61, blue: 0.75)
    
    private let pages: [(icon: String, title: String, description: String)] = [
        ("calendar.badge.checkmark", "欢迎星序", "专为自闭症群体设计的日程管理工具。简单、清晰、无压力，让每一天都井然有序。"),
        ("list.bullet.clipboard", "管理日程", "添加每日任务，用 emoji 图标让内容更直观。完成后轻轻一点，看着进度慢慢填满。"),
        ("heart.text.square", "记录心情", "每天花几秒记录心情，了解自己的情绪变化。数据会帮你发现规律，给出温暖建议。")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // 跳过按钮
            HStack {
                Spacer()
                Button(action: finishOnboarding) {
                    Text("跳过")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.top, 16)
            .padding(.trailing, 8)
            
            // TabView 页面
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPage(
                        icon: pages[index].icon,
                        title: pages[index].title,
                        description: pages[index].description,
                        primaryTint: primaryTint
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // 底部控制区
            VStack(spacing: 24) {
                // 圆点指示器
                HStack(spacing: 10) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? primaryTint : Color.gray.opacity(0.25))
                            .frame(width: currentPage == index ? 10 : 8, height: currentPage == index ? 10 : 8)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
                
                // 按钮
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        finishOnboarding()
                    }
                }) {
                    Text(currentPage < pages.count - 1 ? "下一步" : "开始使用")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(primaryTint)
                        .cornerRadius(16)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 32)
            }
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private func finishOnboarding() {
        hasSeenOnboarding = true
    }
}

// MARK: - 单页

struct OnboardingPage: View {
    let icon: String
    let title: String
    let description: String
    let primaryTint: Color
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer(minLength: 40)
            
            // 大图标
            ZStack {
                Circle()
                    .fill(primaryTint.opacity(0.1))
                    .frame(width: 160, height: 160)
                
                Image(systemName: icon)
                    .font(.system(size: 72))
                    .foregroundColor(primaryTint)
            }
            
            // 文字
            VStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 40)
            }
            
            Spacer(minLength: 40)
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
