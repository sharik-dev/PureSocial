import SwiftUI

struct ContentView: View {
    @AppStorage("platformsData") private var platformsData: Data = Data()
    @AppStorage("onboardingComplete") private var onboardingComplete = false

    @State private var platforms: [SocialPlatform] = []
    @State private var activeIndex: Int = 0
    @State private var viewModels: [String: WebViewModel] = [:]
    @State private var showSettings = false

    private var enabled: [SocialPlatform] { platforms.filter(\.isEnabled) }

    private var activePlatform: SocialPlatform? {
        enabled.indices.contains(activeIndex) ? enabled[activeIndex] : nil
    }

    // Binding that is true when onboarding is NOT complete; setting it to false
    // marks onboarding as done.
    private var showOnboarding: Binding<Bool> {
        Binding<Bool>(
            get: { !onboardingComplete },
            set: { shouldShow in
                if !shouldShow { onboardingComplete = true }
            }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Top browser bar ──────────────────────────────────────
            if let platform = activePlatform {
                BrowserToolbarView(
                    platform: platform,
                    viewModel: vm(for: platform),
                    onSettings: { showSettings = true }
                )
            } else {
                fallbackBar
            }

            // ── Web views (all alive, only active one visible) ───────
            ZStack {
                Color.psBackground
                if enabled.isEmpty {
                    emptyState
                } else {
                    ForEach(Array(enabled.enumerated()), id: \.element.id) { index, platform in
                        PlatformWebContainer(
                            viewModel: vm(for: platform),
                            isActive: index == activeIndex
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // ── Bottom platform tab bar ──────────────────────────────
            PlatformTabBar(
                platforms: enabled,
                activeIndex: $activeIndex,
                onAdd: { showSettings = true }
            )
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(platforms: $platforms)
                .onDisappear { savePlatforms(); clampIndex() }
        }
        .fullScreenCover(isPresented: showOnboarding) {
            OnboardingView(platforms: $platforms) {
                onboardingComplete = true
                savePlatforms()
            }
        }
        .onAppear { loadPlatforms() }
    }

    // MARK: - Subviews

    private var fallbackBar: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundStyle(.blue)
                Text("PureSocial")
                    .font(.headline)
            }
            Spacer()
            Button {
                Haptics.tap()
                showSettings = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16, weight: .medium))
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 16)
        .background(Color.psBackground)
        .overlay(Divider(), alignment: .bottom)
    }

    // ── Empty state — spec C ─────────────────────────────────────────
    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()

            Text("Choose what\nyou let in.")
                .font(.system(size: 22, weight: .semibold))
                .kerning(-0.44)

            Text("Pick the platforms you use to communicate. Everything else stays out: no feed, no reels, no algorithm.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Horizontal scroll of platform chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(platforms) { platform in
                        PlatformChip(platform: platform) {
                            enablePlatform(platform)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.horizontal, -24)

            Spacer()

            // Full-width black pill CTA
            Button {
                Haptics.tap()
                showSettings = true
            } label: {
                Text("Pick three to start")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        Capsule()
                            .fill(Color.black)
                    )
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - ViewModel cache

    private func vm(for platform: SocialPlatform) -> WebViewModel {
        if let existing = viewModels[platform.id] { return existing }
        let model = WebViewModel(platform: platform)
        viewModels[platform.id] = model
        return model
    }

    // MARK: - Helpers

    private func enablePlatform(_ platform: SocialPlatform) {
        guard let index = platforms.firstIndex(where: { $0.id == platform.id }) else { return }
        Haptics.selection()
        platforms[index].isEnabled = true
        savePlatforms()
        clampIndex()
    }

    // MARK: - Persistence

    private func loadPlatforms() {
        guard !platformsData.isEmpty,
              let decoded = try? JSONDecoder().decode([SocialPlatform].self, from: platformsData)
        else { platforms = SocialPlatform.defaults; return }

        let existingIds = Set(decoded.map(\.id))
        let missingDefaults = SocialPlatform.defaults.filter { !existingIds.contains($0.id) }
        platforms = decoded + missingDefaults
    }

    func savePlatforms() {
        if let encoded = try? JSONEncoder().encode(platforms) {
            platformsData = encoded
        }
    }

    private func clampIndex() {
        let count = enabled.count
        if count == 0 { activeIndex = 0 } else if activeIndex >= count { activeIndex = count - 1 }
    }
}

// ── Platform chip (empty state + onboarding) ─────────────────────────────────

struct PlatformChip: View {
    let platform: SocialPlatform
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                BrandDisc(platform: platform, size: 20, isActive: false)
                Text(platform.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.psCanvas)
            )
        }
        .buttonStyle(.plain)
    }
}

// ── Per-platform web container — observes its viewModel for auth sheet ───────

struct PlatformWebContainer: View {
    @ObservedObject var viewModel: WebViewModel
    let isActive: Bool

    var body: some View {
        WebViewRepresentable(viewModel: viewModel)
            .opacity(isActive ? 1 : 0)
            .allowsHitTesting(isActive)
            .sheet(isPresented: Binding(
                get: { viewModel.authWebView != nil },
                set: { showing in
                    if !showing {
                        viewModel.authWebView = nil
                        viewModel.goHome()
                    }
                }
            )) {
                if let authWV = viewModel.authWebView {
                    AuthSheetView(webView: authWV) {
                        viewModel.authWebView = nil
                        viewModel.goHome()
                    }
                }
            }
    }
}

#Preview {
    ContentView()
}
