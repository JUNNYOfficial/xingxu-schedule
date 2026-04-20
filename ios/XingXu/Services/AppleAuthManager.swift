import Foundation
import AuthenticationServices
import SwiftUI

/// Apple ID 登录管理
@MainActor
class AppleAuthManager: ObservableObject {
    static let shared = AppleAuthManager()
    
    @Published var isSignedIn = false
    @Published var userName: String = ""
    @Published var userEmail: String = ""
    
    private let userIdKey = "xingxu_apple_user_id"
    private let userNameKey = "xingxu_apple_user_name"
    private let userEmailKey = "xingxu_apple_user_email"
    
    private init() {
        checkExistingSignIn()
    }
    
    /// 检查是否已有登录状态
    private func checkExistingSignIn() {
        guard let userId = UserDefaults.standard.string(forKey: userIdKey) else { return }
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        appleIDProvider.getCredentialState(forUserID: userId) { [weak self] state, _ in
            Task { @MainActor in
                switch state {
                case .authorized:
                    self?.isSignedIn = true
                    self?.userName = UserDefaults.standard.string(forKey: self?.userNameKey ?? "") ?? ""
                    self?.userEmail = UserDefaults.standard.string(forKey: self?.userEmailKey ?? "") ?? ""
                case .revoked, .notFound:
                    self?.signOut()
                default:
                    break
                }
            }
        }
    }
    
    /// 开始 Apple ID 登录流程
    func signInWithApple() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = AppleAuthDelegate.shared
        controller.presentationContextProvider = AppleAuthDelegate.shared
        controller.performRequests()
    }
    
    /// 登出
    func signOut() {
        UserDefaults.standard.removeObject(forKey: userIdKey)
        UserDefaults.standard.removeObject(forKey: userNameKey)
        UserDefaults.standard.removeObject(forKey: userEmailKey)
        isSignedIn = false
        userName = ""
        userEmail = ""
    }
    
    /// 保存登录信息（由 Delegate 调用）
    func saveCredential(_ credential: ASAuthorizationAppleIDCredential) {
        UserDefaults.standard.set(credential.user, forKey: userIdKey)
        
        if let fullName = credential.fullName,
           let givenName = fullName.givenName,
           let familyName = fullName.familyName {
            let name = "\(familyName)\(givenName)"
            userName = name
            UserDefaults.standard.set(name, forKey: userNameKey)
        }
        
        if let email = credential.email {
            userEmail = email
            UserDefaults.standard.set(email, forKey: userEmailKey)
        }
        
        isSignedIn = true
    }
}

// MARK: - ASAuthorizationController Delegate

class AppleAuthDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    static let shared = AppleAuthDelegate()
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
        Task { @MainActor in
            AppleAuthManager.shared.saveCredential(credential)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Apple ID 登录失败: \(error.localizedDescription)")
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return UIWindow()
        }
        return window
    }
}
