import SwiftUI

// ── Onboarding flow (first-run, 2 screens via TabView .page) ─────────────────

struct OnboardingView: View {
    @Binding var platforms: [SocialPlatform]
    let onComplete: () -> Void

    @State private var step: Int = 0

    var body: some View {
        TabView(selection: $step) {
            WelcomeScreen(onContinue: {
                Haptics.tap()
                step = 1
            })
                .tag(0)
            PickPlatformsScreen(platforms: $platforms, onComplete: {
                Haptics.tap()
                onComplete()
            })
                .tag(1)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
        .background(Color(.systemBackground))
    }
}

// ── Screen 0: Welcome ─────────────────────────────────────────────────────────

private struct WelcomeScreen: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // 56 pt PS branded disc
            ZStack {
                Circle()
                    .fill(Color(red: 0.87, green: 0.22, blue: 0.17))
                    .frame(width: 56, height: 56)
                Text("PS")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text("PureSocial")
                .font(.title2.weight(.semibold))

            Text("One browser for the people you already talk to. Nothing for the algorithm.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            ProgressDots(count: 2, active: 0)

            Button(action: onContinue) {
                Text("Continue")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        Capsule()
                            .fill(Color.black)
                    )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// ── Screen 1: Pick platforms ──────────────────────────────────────────────────

private struct PickPlatformsScreen: View {
    @Binding var platforms: [SocialPlatform]
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 60)

            Text("What do you use?")
                .font(.title3.weight(.semibold))

            Text("Enable what you want. You can always change this.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            OnboardingPickGrid(platforms: $platforms)
                .padding(.horizontal, 16)
                .padding(.top, 8)

            Spacer()

            ProgressDots(count: 2, active: 1)

            Button(action: onComplete) {
                Text("Get Started")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        Capsule()
                            .fill(Color.black)
                    )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// ── Onboarding platform pick grid ─────────────────────────────────────────────

struct OnboardingPickGrid: View {
    @Binding var platforms: [SocialPlatform]

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 140))],
            spacing: 12
        ) {
            ForEach($platforms) { $platform in
                OnboardingPlatformCell(platform: $platform)
            }
        }
    }
}

private struct OnboardingPlatformCell: View {
    @Binding var platform: SocialPlatform

    var body: some View {
        Button {
            Haptics.selection()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                platform.isEnabled.toggle()
            }
        } label: {
            HStack(spacing: 10) {
                ZStack(alignment: .bottomTrailing) {
                    BrandDisc(platform: platform, size: 38, isActive: platform.isEnabled)
                    if platform.isEnabled {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white, platform.accentColor)
                            .offset(x: 4, y: 4)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                Text(platform.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(
                        platform.isEnabled ? platform.accentColor : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// ── Progress dots ─────────────────────────────────────────────────────────────

struct ProgressDots: View {
    let count: Int
    let active: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == active ? Color.primary : Color(.systemGray4))
                    .frame(
                        width: index == active ? 20 : 6,
                        height: 6
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: active)
            }
        }
    }
}
