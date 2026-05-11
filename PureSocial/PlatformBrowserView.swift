import SwiftUI

struct BrowserToolbarView: View {
    let platform: SocialPlatform
    @ObservedObject var viewModel: WebViewModel
    let onSettings: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                HStack(spacing: 0) {
                    NavBtn(icon: "chevron.left", enabled: viewModel.canGoBack) {
                        viewModel.goBack()
                    }
                    NavBtn(icon: "chevron.right", enabled: viewModel.canGoForward) {
                        viewModel.goForward()
                    }
                }

                Spacer()

                Button { viewModel.goHome() } label: {
                    HStack(spacing: 7) {
                        BrandDisc(platform: platform, size: 28, isActive: true)
                        Text(platform.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)
                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.65)
                                .tint(.secondary)
                        }
                    }
                }

                Spacer()

                HStack(spacing: 0) {
                    NavBtn(icon: viewModel.isLoading ? "xmark" : "arrow.clockwise", enabled: true) {
                        if viewModel.isLoading { viewModel.stopLoading() } else { viewModel.reload() }
                    }
                    NavBtn(icon: "slider.horizontal.3", enabled: true, action: onSettings)
                }
            }
            .frame(height: 44)
            .padding(.horizontal, 4)
            .background(Color.psBackground)

            if viewModel.isLoading {
                GeometryReader { geo in
                    platform.accentColor
                        .frame(width: geo.size.width * viewModel.progress, height: 2)
                        .animation(.linear(duration: 0.08), value: viewModel.progress)
                }
                .frame(height: 2)
            } else {
                Divider()
            }
        }
    }
}

private struct NavBtn: View {
    let icon: String
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(enabled ? Color(white: 0.15) : Color(white: 0.62))
                .frame(width: 44, height: 44)
        }
        .disabled(!enabled)
    }
}
