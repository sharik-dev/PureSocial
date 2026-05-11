import Foundation
import WebKit
import Combine

class WebViewModel: NSObject, ObservableObject {
    let platform: SocialPlatform

    @Published var canGoBack    = false
    @Published var canGoForward = false
    @Published var isLoading    = false
    @Published var progress: Double = 0

    private(set) lazy var webView: WKWebView = createWebView()
    private var observations: [NSKeyValueObservation] = []

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

    // MARK: - Setup

    private func createWebView() -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        // Require explicit user tap to play any video/audio — prevents reels/shorts autoplay
        config.mediaTypesRequiringUserActionForPlayback = .all

        let ucc = WKUserContentController()
        ucc.addUserScript(ContentBlocker.userScript(for: platform.id))
        config.userContentController = ucc

        let wv = WKWebView(frame: .zero, configuration: config)
        wv.navigationDelegate = self
        wv.allowsBackForwardNavigationGestures = true
        // Mobile Safari UA — proper responsive layout on all platforms
        wv.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

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
}

// MARK: - WKNavigationDelegate

extension WebViewModel: WKNavigationDelegate {

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let urlString = navigationAction.request.url?.absoluteString else {
            decisionHandler(.allow); return
        }
        for pattern in blockedPatterns {
            if urlString.range(of: pattern, options: .regularExpression) != nil {
                decisionHandler(.cancel)
                DispatchQueue.main.async { self.goHome() }
                return
            }
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Re-inject CSS + re-run DOM hider after every page finish (covers reloads + SPA nav)
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
