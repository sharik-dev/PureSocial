import SwiftUI

struct SettingsView: View {
    @Binding var platforms: [SocialPlatform]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach($platforms) { $platform in
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(platform.accentColor)
                                    .frame(width: 38, height: 38)
                                Image(systemName: platform.systemIconName)
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundStyle(.white)
                            }
                            Text(platform.name)
                            Spacer()
                            Toggle("", isOn: $platform.isEnabled)
                                .labelsHidden()
                                .tint(platform.accentColor)
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Text("Platforms")
                } footer: {
                    Text("PureSocial opens each platform on its messaging page and hides feeds, stories, and reels — so you can communicate without getting pulled into consumption.")
                        .font(.footnote)
                }

                Section("What's blocked") {
                    BlockedRow(icon: "film.stack",      label: "Reels & Short Videos")
                    BlockedRow(icon: "rectangle.stack", label: "Stories")
                    BlockedRow(icon: "square.grid.2x2", label: "Home Feeds & Timelines")
                    BlockedRow(icon: "magnifyingglass", label: "Explore & Discover Pages")
                }

                Section("About") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(.secondary)
                    }
                    Label("Sessions stored by iOS (no PureSocial account needed)", systemImage: "lock.shield.fill")
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

private struct BlockedRow: View {
    let icon: String
    let label: String

    var body: some View {
        Label {
            Text(label)
                .foregroundStyle(.secondary)
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(.red)
        }
    }
}
