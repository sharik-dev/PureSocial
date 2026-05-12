import SwiftUI

struct SettingsView: View {
    @Binding var platforms: [SocialPlatform]
    @Environment(\.dismiss) private var dismiss

    private let blockedFeatures = ["feeds", "stories", "reels", "explore", "shorts", "suggestions"]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach($platforms) { $platform in
                        HStack(spacing: 14) {
                            BrandDisc(platform: platform, size: 26, isActive: platform.isEnabled)
                            Text(platform.name)
                            Spacer()
                            Toggle("", isOn: $platform.isEnabled)
                                .labelsHidden()
                                .tint(platform.accentColor)
                        }
                        .padding(.vertical, 2)
                    }
                    .onMove { source, destination in
                        platforms.move(fromOffsets: source, toOffset: destination)
                    }
                }
                .environment(\.editMode, .constant(.active))

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            ForEach(blockedFeatures.prefix(3), id: \.self) { feature in
                                BlockChip(label: feature)
                            }
                        }
                        HStack(spacing: 8) {
                            ForEach(blockedFeatures.suffix(3), id: \.self) { feature in
                                BlockChip(label: feature)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("What's blocked everywhere")
                }
            }
            .navigationTitle("Platforms")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        Haptics.tap()
                        dismiss()
                    }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.medium, .large])
    }
}

private struct BlockChip: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.system(size: 13, weight: .medium))
            .strikethrough(true)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.psCanvas)
            )
    }
}
