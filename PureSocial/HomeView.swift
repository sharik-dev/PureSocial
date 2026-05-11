import SwiftUI

struct HomeView: View {
    @AppStorage("platformsData") private var platformsData: Data = Data()
    @State private var platforms: [SocialPlatform] = []
    @State private var selectedPlatform: SocialPlatform?
    @State private var showSettings = false
    @State private var viewModels: [String: WebViewModel] = [:]

    private let columns = [GridItem(.adaptive(minimum: 140, maximum: 180), spacing: 16)]

    var body: some View {
        NavigationStack {
            ScrollView {
                if platforms.filter(\.isEnabled).isEmpty {
                    emptyState
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(platforms.filter(\.isEnabled)) { platform in
                            PlatformCard(platform: platform)
                                .onTapGesture { selectedPlatform = platform }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("PureSocial")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "slider.horizontal.3")
                            .fontWeight(.medium)
                    }
                }
            }
            .sheet(item: $selectedPlatform) { platform in
                PlatformBrowserView(viewModel: cachedViewModel(for: platform))
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(platforms: $platforms)
                    .onDisappear { savePlatforms() }
            }
        }
        .onAppear { loadPlatforms() }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "apps.iphone")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("No platforms enabled")
                .font(.title3)
                .fontWeight(.semibold)
            Text("Tap the settings icon to enable platforms.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Open Settings") { showSettings = true }
                .buttonStyle(.borderedProminent)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - ViewModel cache (keeps sessions alive across sheet dismissals)

    private func cachedViewModel(for platform: SocialPlatform) -> WebViewModel {
        if let existing = viewModels[platform.id] { return existing }
        let vm = WebViewModel(platform: platform)
        viewModels[platform.id] = vm
        return vm
    }

    // MARK: - Persistence

    private func loadPlatforms() {
        guard !platformsData.isEmpty,
              let decoded = try? JSONDecoder().decode([SocialPlatform].self, from: platformsData)
        else {
            platforms = SocialPlatform.defaults
            return
        }
        platforms = decoded
    }

    private func savePlatforms() {
        if let encoded = try? JSONEncoder().encode(platforms) {
            platformsData = encoded
        }
    }
}

// MARK: - Platform Card

struct PlatformCard: View {
    let platform: SocialPlatform

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(platform.accentColor.gradient)
                    .frame(width: 64, height: 64)
                Image(systemName: platform.systemIconName)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.white)
            }
            Text(platform.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 2)
        )
    }
}
