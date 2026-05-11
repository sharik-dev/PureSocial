import SwiftUI

struct PlatformBrowserView: View {
    @ObservedObject var viewModel: WebViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header
            progressBar
            WebViewRepresentable(viewModel: viewModel)
                .ignoresSafeArea(.container, edges: .bottom)
            bottomToolbar
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Subviews

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(viewModel.platform.accentColor)
                        .frame(width: 32, height: 32)
                    Image(systemName: viewModel.platform.systemIconName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Text(viewModel.platform.name)
                    .font(.headline)
            }

            Spacer()

            // Invisible spacer to balance the close button
            Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.clear)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private var progressBar: some View {
        if viewModel.isLoading {
            GeometryReader { geo in
                viewModel.platform.accentColor
                    .frame(width: geo.size.width * viewModel.progress, height: 3)
                    .animation(.linear(duration: 0.1), value: viewModel.progress)
            }
            .frame(height: 3)
        } else {
            Divider()
        }
    }

    private var bottomToolbar: some View {
        HStack(spacing: 0) {
            BrowserButton(icon: "chevron.left", enabled: viewModel.canGoBack) {
                viewModel.goBack()
            }
            BrowserButton(icon: "chevron.right", enabled: viewModel.canGoForward) {
                viewModel.goForward()
            }
            Spacer()
            BrowserButton(icon: "house.fill", enabled: true) {
                viewModel.goHome()
            }
            Spacer()
            BrowserButton(icon: viewModel.isLoading ? "xmark" : "arrow.clockwise", enabled: true) {
                if viewModel.isLoading { viewModel.stopLoading() } else { viewModel.reload() }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Browser Button

private struct BrowserButton: View {
    let icon: String
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(enabled ? .primary : .tertiary)
                .frame(width: 44, height: 44)
        }
        .disabled(!enabled)
    }
}
