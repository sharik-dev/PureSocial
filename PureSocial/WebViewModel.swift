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

    private(set) lazy var webView: WKWebView = createWebView()
    private var observations: [NSKeyValueObservation] = []
    private var grayscaleOn = false
    private var muteSoundOn = false
    private var blockVideoOn = false

    // Shared across all instances — same network process, shared DNS/HTTP/TLS cache
    private static let sharedProcessPool = WKProcessPool()

    private var didLoadInitial = false

    init(platform: SocialPlatform) {
        self.platform = platform
        super.init()
    }

    // Loads the platform's start URL the first time its tab is shown. Deferring this keeps app
    // launch instant: only the active platform loads its (heavy) site, instead of every enabled
    // platform hammering the network at once behind the onboarding screen.
    func loadInitialIfNeeded() {
        guard !didLoadInitial else { return }
        didLoadInitial = true
        navigate(to: platform.startURL)
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

    // Toggle a CSS grayscale filter on the page. The SwiftUI .grayscale() modifier does not
    // reliably affect out-of-process WKWebView content, so we inject the filter directly.
    func applyGrayscale(_ on: Bool) {
        grayscaleOn = on
        let js = on
            ? "document.documentElement.style.setProperty('filter','grayscale(1)','important');"
            : "document.documentElement.style.removeProperty('filter');"
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    // Enforce the global mute-sound / block-video settings on the page's media elements.
    func applyMediaSettings(muteSound: Bool, blockVideo: Bool) {
        muteSoundOn = muteSound
        blockVideoOn = blockVideo
        let js = ContentBlocker.mediaControlJS(muteSound: muteSound, blockVideo: blockVideo)
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    func navigate(to urlString: String) {
        guard let url = URL(string: urlString) else { return }
        webView.load(URLRequest(url: url))
    }

    // MARK: - Setup

    private func createWebView() -> WKWebView {
        let config = WKWebViewConfiguration()
        config.processPool = WebViewModel.sharedProcessPool
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = .all

        let ucc = WKUserContentController()
        ucc.addUserScript(ContentBlocker.navigationFixUserScript())
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

        return wv
    }

    private var customUserAgent: String {
        // Per-platform override (e.g. desktop UA for Messenger); fall back to mobile Safari.
        platform.customUserAgent ??
        "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
    }

}

// MARK: - WKUIDelegate

extension WebViewModel: WKUIDelegate {

    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        // A single-view browser has nowhere to put a new window. Rather than spawning a popup
        // (or a stuck auth sheet), load the destination inline so links that target a new tab —
        // "Help Center", "For developers", "Log in", "Continue with…" — always navigate.
        if let url = navigationAction.request.url {
            webView.load(URLRequest(url: url))
        }
        return nil
    }

    // Auto-dismiss JS dialogs so they can't block the login flow.
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        completionHandler()
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

        // Hand non-web schemes (mailto:, tel:, app deep-links, …) off to the system.
        if let scheme = url.scheme?.lowercased(),
           !["http", "https", "about", "blob", "data", "javascript"].contains(scheme) {
            decisionHandler(.cancel)
            DispatchQueue.main.async { UIApplication.shared.open(url) }
            return
        }

        // Links that open a new tab/window (target="_blank") arrive with no target frame —
        // WKWebView drops them silently, which is why links looked "dead". Load them inline in
        // the same view so every link is reachable and login redirect chains complete normally.
        if navigationAction.targetFrame == nil {
            decisionHandler(.cancel)
            DispatchQueue.main.async { webView.load(URLRequest(url: url)) }
            return
        }

        // Full browsing freedom: every other navigation is allowed.
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard webView === self.webView else { return }
        if grayscaleOn { applyGrayscale(true) }
        if muteSoundOn || blockVideoOn { applyMediaSettings(muteSound: muteSoundOn, blockVideo: blockVideoOn) }
        let js = ContentBlocker.reinjectJS(for: platform.id)
        guard !js.isEmpty else { return }
        webView.evaluateJavaScript(js, completionHandler: nil)
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
