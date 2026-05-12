import SwiftUI
import WebKit

struct AuthSheetView: View {
    let webView: WKWebView
    let onDismiss: () -> Void

    @StateObject private var tracker: AuthWebTracker

    init(webView: WKWebView, onDismiss: @escaping () -> Void) {
        self.webView = webView
        self.onDismiss = onDismiss
        _tracker = StateObject(wrappedValue: AuthWebTracker(webView: webView))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                AuthWebViewRepresentable(webView: webView)
                    .ignoresSafeArea(edges: .bottom)

                // Loading progress bar
                if tracker.isLoading {
                    GeometryReader { geo in
                        Color.accentColor
                            .frame(width: geo.size.width * tracker.progress, height: 2)
                            .animation(.linear(duration: 0.08), value: tracker.progress)
                    }
                    .frame(height: 2)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Terminé", action: onDismiss)
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .principal) {
                    if let host = tracker.currentHost {
                        Text(host)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        webView.goBack()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(!tracker.canGoBack)

                    Button {
                        if tracker.isLoading { webView.stopLoading() } else { webView.reload() }
                    } label: {
                        Image(systemName: tracker.isLoading ? "xmark" : "arrow.clockwise")
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
    }
}

// Observes WKWebView state without taking over the WebView delegates.
private class AuthWebTracker: NSObject, ObservableObject {
    @Published var isLoading    = false
    @Published var progress: Double = 0
    @Published var canGoBack    = false
    @Published var currentHost: String? = nil

    private var observations: [NSKeyValueObservation] = []

    init(webView: WKWebView) {
        super.init()
        observations = [
            webView.observe(\.isLoading) { [weak self] wv, _ in
                DispatchQueue.main.async { self?.isLoading = wv.isLoading }
            },
            webView.observe(\.estimatedProgress) { [weak self] wv, _ in
                DispatchQueue.main.async { self?.progress = wv.estimatedProgress }
            },
            webView.observe(\.canGoBack) { [weak self] wv, _ in
                DispatchQueue.main.async { self?.canGoBack = wv.canGoBack }
            },
            webView.observe(\.url) { [weak self] wv, _ in
                DispatchQueue.main.async { self?.currentHost = wv.url?.host }
            },
        ]
    }

    deinit { observations.forEach { $0.invalidate() } }
}

private struct AuthWebViewRepresentable: UIViewRepresentable {
    let webView: WKWebView
    func makeUIView(context: Context) -> WKWebView { webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
