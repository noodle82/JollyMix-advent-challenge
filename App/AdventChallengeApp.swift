import AVFAudio
import SwiftUI
import WebKit

@main
struct AdventChallengeApp: App {
    var body: some Scene {
        WindowGroup {
            CalendarView()
                .ignoresSafeArea(.keyboard)
                .background(Color(red: 0.10, green: 0.06, blue: 0.05))
                .statusBarHidden()
        }
    }
}

private struct CalendarView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CalendarController {
        CalendarController()
    }

    func updateUIViewController(_ controller: CalendarController, context: Context) {}
}

final class CalendarController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {
    private static let shareAction = "jollyMixShare"
    private var calendar: WKWebView?
    private var keyboardPresented = false

    override func viewDidLoad() {
        super.viewDidLoad()
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.userContentController.add(ShareRelay(controller: self), name: Self.shareAction)
        let calendar = WKWebView(frame: .zero, configuration: configuration)
        let background = UIColor(red: 0.10, green: 0.06, blue: 0.05, alpha: 1)
        self.calendar = calendar
        calendar.navigationDelegate = self
        calendar.isOpaque = false
        calendar.backgroundColor = background
        calendar.scrollView.backgroundColor = background
        calendar.scrollView.contentInsetAdjustmentBehavior = .never
        calendar.scrollView.bounces = false
        view.backgroundColor = background
        view.addSubview(calendar)
        calendar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            calendar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            calendar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            calendar.topAnchor.constraint(equalTo: view.topAnchor),
            calendar.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor)
        ])
        let notifications = NotificationCenter.default
        notifications.addObserver(self, selector: #selector(appBecameActive),
                                  name: UIApplication.didBecomeActiveNotification, object: nil)
        notifications.addObserver(self, selector: #selector(audioInterrupted(_:)),
                                  name: AVAudioSession.interruptionNotification, object: nil)
        notifications.addObserver(self, selector: #selector(audioReset),
                                  name: AVAudioSession.mediaServicesWereResetNotification, object: nil)
        if let page = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Web") {
            calendar.loadFileURL(page, allowingReadAccessTo: page.deletingLastPathComponent())
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let keyboardTop = view.keyboardLayoutGuide.layoutFrame.minY
        let obscuredHeight = view.bounds.maxY - keyboardTop
        let presented = view.bounds.height > 0 && obscuredHeight > view.safeAreaInsets.bottom + 55
        guard keyboardPresented != presented else { return }
        keyboardPresented = presented
        sendKeyboardState()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        sendKeyboardState()
    }

    private func sendKeyboardState() {
        let state = keyboardPresented ? "true" : "false"
        calendar?.evaluateJavaScript("window.jollyMixKeyboardChanged?.(" + state + ")", completionHandler: nil)
    }

    @objc private func appBecameActive() {
        audioReset()
    }

    @objc private func audioInterrupted(_ notice: Notification) {
        guard let raw = notice.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              AVAudioSession.InterruptionType(rawValue: raw) == .ended else { return }
        audioReset()
    }

    @objc private func audioReset() {
        calendar?.evaluateJavaScript("window.jollyMixAudioInterrupted?.()", completionHandler: nil)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor action: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = action.request.url else {
            decisionHandler(.cancel)
            return
        }
        if url.isFileURL || url.scheme == "about" {
            decisionHandler(.allow)
            return
        }
        if action.navigationType == .linkActivated,
           action.sourceFrame.isMainFrame,
           ["https", "mailto"].contains(url.scheme ?? "") {
            UIApplication.shared.open(url)
        }
        decisionHandler(.cancel)
    }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == Self.shareAction, message.frameInfo.isMainFrame,
              let text = message.body as? String, text.count <= 1024,
              presentedViewController == nil else { return }
        let share = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        share.popoverPresentationController?.sourceView = view
        share.popoverPresentationController?.sourceRect = CGRect(
            x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1
        )
        present(share, animated: true)
    }
}

// The web view retains its script handlers. Keep the controller reference weak.
private final class ShareRelay: NSObject, WKScriptMessageHandler {
    private weak var controller: CalendarController?

    init(controller: CalendarController) {
        self.controller = controller
    }

    func userContentController(_ contentController: WKUserContentController, didReceive message: WKScriptMessage) {
        controller?.userContentController(contentController, didReceive: message)
    }
}
