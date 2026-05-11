import SwiftUI

// ── App-wide color tokens ─────────────────────────────────────────────────────

extension Color {
    static let psBackground = Color(red: 251/255, green: 249/255, blue: 244/255)  // #FBF9F4
    static let psCanvas     = Color(red: 239/255, green: 236/255, blue: 228/255)  // #EFECE4
}

// ── Brand Disc ────────────────────────────────────────────────────────────────

struct BrandDisc: View {
    let platform: SocialPlatform
    var size: CGFloat = 38
    var isActive: Bool

    var body: some View {
        ZStack {
            if isActive {
                Circle()
                    .fill(platform.accentColor)
                    .frame(width: size, height: size)
            } else {
                Circle()
                    .strokeBorder(Color(white: 0.52), lineWidth: 1.5)
                    .frame(width: size, height: size)
            }
            Image(systemName: platform.systemIconName)
                .font(.system(size: size * 0.40, weight: .semibold))
                .foregroundStyle(isActive ? .white : Color(white: 0.38))
        }
    }
}

// ── Platform Tab Bar ──────────────────────────────────────────────────────────

struct PlatformTabBar: View {
    let platforms: [SocialPlatform]
    @Binding var activeIndex: Int
    let onAdd: () -> Void

    private let tabBarHeight: CGFloat = 64
    private let scrollItemWidth: CGFloat = 72
    private let fadedWidth: CGFloat = 28

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            if platforms.isEmpty {
                addButton
                    .frame(height: tabBarHeight)
            } else if platforms.count <= 5 {
                HStack(spacing: 0) {
                    ForEach(Array(platforms.enumerated()), id: \.element.id) { index, platform in
                        TabCell(
                            platform: platform,
                            isActive: index == activeIndex
                        )
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                                activeIndex = index
                            }
                        }
                    }
                }
                .frame(height: tabBarHeight)
            } else {
                scrollingTabBar
            }
        }
        .background(Color.psBackground.ignoresSafeArea(edges: .bottom))
    }

    // MARK: - Scrolling tab bar (6+ platforms)

    private var scrollingTabBar: some View {
        ZStack(alignment: .trailing) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(Array(platforms.enumerated()), id: \.element.id) { index, platform in
                            TabCell(
                                platform: platform,
                                isActive: index == activeIndex
                            )
                            .frame(width: scrollItemWidth)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                                    activeIndex = index
                                }
                            }
                            .id(index)
                        }
                    }
                }
                .frame(height: tabBarHeight)
                .onChange(of: activeIndex) { _, newValue in
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                        proxy.scrollTo(newValue, anchor: .trailing)
                    }
                }
            }

            // Explicit height prevents LinearGradient from expanding the ZStack
            LinearGradient(
                colors: [.clear, Color.psBackground],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: fadedWidth, height: tabBarHeight)
            .allowsHitTesting(false)
        }
        .frame(height: tabBarHeight)
    }

    // MARK: - Add button (empty state)

    private var addButton: some View {
        Button(action: onAdd) {
            Label("Add Platforms", systemImage: "plus.circle.fill")
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
        }
    }
}

// ── Single tab cell ───────────────────────────────────────────────────────────

private struct TabCell: View {
    let platform: SocialPlatform
    let isActive: Bool

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(isActive ? platform.accentColor : Color.clear)
                .frame(width: 24, height: 2.5)

            Spacer()

            BrandDisc(platform: platform, size: 38, isActive: isActive)

            Text(platform.shortLabel.uppercased())
                .font(.system(size: 9, design: .rounded).weight(.medium))
                .foregroundStyle(isActive ? platform.accentColor : Color(white: 0.42))
                .lineLimit(1)

            Spacer()
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.72), value: isActive)
    }
}
