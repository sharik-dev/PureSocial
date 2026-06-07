import SwiftUI
import WebKit

struct WebViewRepresentable: UIViewRepresentable {
    @ObservedObject var viewModel: WebViewModel
    @AppStorage("grayscaleEnabled") private var grayscale = false
    @AppStorage("muteSoundEnabled") private var muteSound = false
    @AppStorage("blockVideoEnabled") private var blockVideo = false

    func makeUIView(context: Context) -> WKWebView {
        viewModel.webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        viewModel.applyGrayscale(grayscale)
        viewModel.applyMediaSettings(muteSound: muteSound, blockVideo: blockVideo)
    }
}
