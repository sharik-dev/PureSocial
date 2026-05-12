import Foundation
import WebKit
import Combine
import SafariServices

class WebViewModel: NSObject, ObservableObject {
    let platform: SocialPlatform

    @Published var canGoBack    = false
    @Published var canGoForward = false
    @Published var isLoading    = false
    @Published var progress: Double = 0
    @Published var authWebView: WKWebView? = nil

    private(set) lazy var webView: WKWebView = createWebView()
    private var observations: [NSKeyValueObservation] = []

    // Shared across all instances — same network process, shared DNS/HTTP/TLS cache
    private static let sharedProcessPool = WKProcessPool()

    init(platform: SocialPlatform) {
        self.platform = platform
        super.init()
        _ = webView
    }

    deinit {
        observations.forEach { $0.invalidate() }
    }

    // MARK: - Actions

    func goBack()      { webView.goBack() }
    func goForward()   { webView.goForward() }
    func reload()      { webView.reload() }
    func stopLoading() { webView.stopLoading() }
    func goHome()      { navigate(to: platform.startURL) }
    func compose()     { if let url = platform.composeURL { navigate(to: url) } }

    func navigate(to urlString: String) {
        guard let url = URL(string: urlString) else { return }
        webView.load(URLRequest(url: url))
    }

    private func presentAuthWebView(for url: URL, basedOn sourceWebView: WKWebView) {
        let authConfig = WKWebViewConfiguration()
        authConfig.processPool = WebViewModel.sharedProcessPool
        authConfig.websiteDataStore = sourceWebView.configuration.websiteDataStore
        authConfig.allowsInlineMediaPlayback = true
        authConfig.mediaTypesRequiringUserActionForPlayback = .all

        let authWV = WKWebView(frame: .zero, configuration: authConfig)
        authWV.customUserAgent = customUserAgent
        authWV.allowsBackForwardNavigationGestures = true
        authWV.navigationDelegate = self
        authWV.uiDelegate = self
        authWV.load(URLRequest(url: url))

        DispatchQueue.main.async {
            self.authWebView = authWV
        }
    }

    // MARK: - Setup

    private func createWebView() -> WKWebView {
        let config = WKWebViewConfiguration()
        config.processPool = WebViewModel.sharedProcessPool
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = .all

        let ucc = WKUserContentController()
        ucc.addUserScript(ContentBlocker.userScript(for: platform.id))
        config.userContentController = ucc

        let wv = WKWebView(frame: .zero, configuration: config)
        wv.navigationDelegate = self
        wv.uiDelegate = self
        wv.allowsBackForwardNavigationGestures = true
        wv.customUserAgent = customUserAgent

        observations = [
            wv.observe(\.estimatedProgress) { [weak self] wv, _ in
                DispatchQueue.main.async { self?.progress = wv.estimatedProgress }
            },
            wv.observe(\.canGoBack) { [weak self] wv, _ in
                DispatchQueue.main.async { self?.canGoBack = wv.canGoBack }
            },
            wv.observe(\.canGoForward) { [weak self] wv, _ in
                DispatchQueue.main.async { self?.canGoForward = wv.canGoForward }
            },
            wv.observe(\.isLoading) { [weak self] wv, _ in
                DispatchQueue.main.async { self?.isLoading = wv.isLoading }
            },
        ]

        if let url = URL(string: platform.startURL) {
            wv.load(URLRequest(url: url))
        }
        return wv
    }

    private var customUserAgent: String {
        switch platform.id {
        case "tiktok", "messenger":
            return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        default:
            return "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        }
    }

}

// MARK: - WKUIDelegate

extension WebViewModel: WKUIDelegate {

    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard let url = navigationAction.request.url else { return nil }

        // Same-origin popup → load in current webview (e.g. Facebook message thread)
        if let currentHost = webView.url?.host, let newHost = url.host {
            let sameOrigin = newHost == currentHost
                || newHost.hasSuffix("." + currentHost)
                || currentHost.hasSuffix("." + newHost)
            if sameOrigin {
                webView.load(URLRequest(url: url))
                return nil
            }
        }

        // External popup (OAuth) → dedicated auth sheet using a WKWebView that shares cookies.
        presentAuthWebView(for: url, basedOn: webView)
        return nil
    }
}

// MARK: - WKNavigationDelegate

extension WebViewModel: WKNavigationDelegate {

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow); return
        }

        // Some OAuth providers open a new tab/window without going through createWebViewWith.
        if navigationAction.targetFrame == nil {
            decisionHandler(.cancel)
            presentAuthWebView(for: url, basedOn: webView)
            return
        }

        for pattern in blockedPatterns {
            if url.absoluteString.range(of: pattern, options: .regularExpression) != nil {
                decisionHandler(.cancel)
                DispatchQueue.main.async { self.goHome() }
                return
            }
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let js = ContentBlocker.reinjectJS(for: platform.id)
        guard !js.isEmpty else { return }
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    private var blockedPatterns: [String] {
        switch platform.id {
        case "instagram": return ["/reels(/|$)"]
        case "facebook":  return ["/watch(/|$)", "/gaming(/|$)"]
        case "youtube":   return ["/shorts(/|$)"]
        default:          return []
        }
    }
}

// MARK: - UIApplication helper

extension UIApplication {
    var topPresentedViewController: UIViewController? {
        let scenes = connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes.flatMap(\.windows).first(where: \.isKeyWindow)
        var vc = window?.rootViewController
        while let presented = vc?.presentedViewController { vc = presented }
        return vc
    }
}
