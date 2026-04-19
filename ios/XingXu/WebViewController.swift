import UIKit
import WebKit
import WidgetKit

class WebViewController: UIViewController {
    
    var webView: WKWebView!
    private var syncTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        loadLocalHTML()
        startAutoSync()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        syncTimer?.invalidate()
    }
    
    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.allowsInlineMediaPlayback = true
        config.websiteDataStore = WKWebsiteDataStore.default()
        config.userContentController.add(self, name: "xingxuBridge")
        
        let bridgeScript = """
        (function() {
            if (window.xingxuNative) return;
            window.xingxuNative = {
                postMessage: function(data) {
                    window.webkit.messageHandlers.xingxuBridge.postMessage(data);
                },
                ready: true
            };
            window.dispatchEvent(new CustomEvent('xingxuNativeReady'));
        })();
        """
        let userScript = WKUserScript(source: bridgeScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        config.userContentController.addUserScript(userScript)
        
        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = false
        webView.overrideUserInterfaceStyle = .unspecified
        view.addSubview(webView)
    }
    
    private func loadLocalHTML() {
        guard let htmlPath = Bundle.main.path(forResource: "index", ofType: "html") else {
            showError("未找到应用资源文件")
            return
        }
        let url = URL(fileURLWithPath: htmlPath)
        let dirURL = url.deletingLastPathComponent()
        webView.loadFileURL(url, allowingReadAccessTo: dirURL)
    }
    
    private func startAutoSync() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.syncTasksToWidget()
        }
    }
    
    func syncTasksToWidget() {
        let script = """
        (function() {
            try {
                var data = localStorage.getItem('schedule-unified-v2');
                var currentDate = localStorage.getItem('schedule-current-date') || new Date().toISOString().split('T')[0];
                if (data) {
                    var allTasks = JSON.parse(data);
                    var todayTasks = allTasks.filter(function(t) { return t.date === currentDate; });
                    var completed = todayTasks.filter(function(t) { return t.completed; }).length;
                    return JSON.stringify({
                        date: currentDate,
                        tasks: todayTasks.map(function(t) {
                            return {
                                id: t.id,
                                name: t.name,
                                time: t.time,
                                completed: !!t.completed,
                                tag: t.tag || '',
                                icon: t.icon || ''
                            };
                        }),
                        totalTasks: todayTasks.length,
                        completedTasks: completed
                    });
                }
                return JSON.stringify({ date: currentDate, tasks: [], totalTasks: 0, completedTasks: 0 });
            } catch (e) {
                return JSON.stringify({ error: e.message });
            }
        })();
        """
        
        webView.evaluateJavaScript(script) { [weak self] result, error in
            guard let self = self else { return }
            if let error = error {
                print("[WebView] 同步失败: \(error)")
                return
            }
            guard let jsonString = result as? String,
                  let jsonData = jsonString.data(using: .utf8) else { return }
            do {
                var data = try JSONDecoder().decode(WidgetScheduleData.self, from: jsonData)
                data.updatedAt = Date()
                SharedDataManager.shared.saveScheduleData(data)
                WidgetCenter.shared.reloadTimelines(ofKind: "XingXuWidget")
                print("[WebView] 已同步 \(data.tasks.count) 个任务到小组件")
            } catch {
                print("[WebView] 解析数据失败: \(error)")
            }
        }
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "错误", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("[WebView] 页面加载完成")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.syncTasksToWidget()
        }
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("[WebView] 加载失败: \(error)")
    }
}

extension WebViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in completionHandler() })
        present(alert, animated: true)
    }
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in completionHandler(true) })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in completionHandler(false) })
        present(alert, animated: true)
    }
}

extension WebViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "xingxuBridge",
              let body = message.body as? [String: Any] else { return }
        let action = body["action"] as? String ?? ""
        switch action {
        case "syncTasks":
            syncTasksToWidget()
        case "requestNotification":
            requestNotificationPermission()
        case "log":
            if let msg = body["message"] as? String {
                print("[WebView] \(msg)")
            }
        default:
            print("[WebView] 收到未知消息: \(action)")
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async { [weak self] in
                let result = granted ? "granted" : "denied"
                self?.webView.evaluateJavaScript(
                    "window.xingxuNativePermissionCallback && window.xingxuNativePermissionCallback('\(result)')",
                    completionHandler: nil
                )
            }
        }
    }
}
