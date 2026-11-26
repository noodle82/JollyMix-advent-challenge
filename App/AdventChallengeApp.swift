import SwiftUI
import WebKit

@main
struct AdventChallengeApp: App {
    var body: some Scene {
        WindowGroup {
            CalendarView()
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

    override func viewDidLoad() {
        super.viewDidLoad()
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.userContentController.add(ShareRelay(controller: self), name: Self.shareAction)
        let calendar = WKWebView(frame: .zero, configuration: configuration)
        let background = UIColor(red: 0.10, green: 0.06, blue: 0.05, alpha: 1)
        calendar.navigationDelegate = self
        calendar.isOpaque = false
        calendar.backgroundColor = background
        calendar.scrollView.backgroundColor = background
        calendar.scrollView.contentInsetAdjustmentBehavior = .never
        view.backgroundColor = background
        view.addSubview(calendar)
        calendar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            calendar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            calendar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            calendar.topAnchor.constraint(equalTo: view.topAnchor),
            calendar.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        if let page = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Web") {
            calendar.loadFileURL(page, allowingReadAccessTo: page.deletingLastPathComponent())
        }
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
