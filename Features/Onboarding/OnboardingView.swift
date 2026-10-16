import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var page = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            eyebrow: "Chat Story Maker",
            title: "Create fictional chats in minutes",
            subtitle: "Build chat stories with characters, message sides, timestamps, media-style messages, reactions, and receipts.",
            icon: "bubble.left.and.bubble.right.fill",
            colors: [Color(hex: "#2563EB"), Color(hex: "#0F766E")],
            features: [
                ("Characters", "Create sender profiles", "person.2.fill"),
                ("Messages", "Text, image, video, voice-style", "text.bubble.fill"),
                ("Receipts", "Delivered, seen, and timestamps", "checkmark.seal.fill"),
            ]
        ),
        OnboardingPage(
            eyebrow: "Story Setup",
            title: "Choose the style before writing",
            subtitle: "Pick a theme, set your cast, customize message sides, then keep the whole flow organized.",
            icon: "paintpalette.fill",
            colors: [Color(hex: "#0F766E"), Color(hex: "#B7791F")],
            features: [
                ("Themes", "WhatsApp, Instagram, Facebook, Telegram, Snapchat", "paintpalette.fill"),
                ("Cast", "Names, avatars, sides, colors", "person.crop.circle.badge.checkmark"),
                ("Flow", "Setup, write, preview, export", "point.3.connected.trianglepath.dotted"),
            ]
        ),
        OnboardingPage(
            eyebrow: "Export Ready",
            title: "Preview and export clean stories",
            subtitle: "Reveal messages in playback, then export selected areas or full conversations in creator-friendly formats.",
            icon: "square.and.arrow.up.fill",
            colors: [Color(hex: "#B7791F"), Color(hex: "#2563EB")],
            features: [
                ("Playback", "Tap reveal and auto-play", "play.fill"),
                ("Image Export", "Selected area or full chat", "photo.stack.fill"),
                ("Formats", "9:16, 1:1, and 4:5", "rectangle.3.group.fill"),
            ]
        ),
    ]

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let compact = DeviceSize.isCompactScreen(width: size.width, height: size.height)
            let horizontalPadding = horizontalPadding(for: size.width)
            let maxWidth = min(size.width - horizontalPadding * 2, size.width >= 700 ? 720 : 560)

            ZStack {
                background(for: pages[page])

                VStack(spacing: 0) {
                    topBar(current: pages[page], compact: compact)
                        .frame(maxWidth: maxWidth)
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, topPadding(safeTop: geometry.safeAreaInsets.top, compact: compact))
                        .padding(.bottom, compact ? 6 : 14)

                    TabView(selection: $page) {
                        ForEach(pages.indices, id: \.self) { index in
                            OnboardingPageView(
                                page: pages[index],
                                compact: compact,
                                maxWidth: maxWidth,
                                availableHeight: pageAreaHeight(size: size, safeTop: geometry.safeAreaInsets.top, safeBottom: geometry.safeAreaInsets.bottom)
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .animation(.spring(response: 0.42, dampingFraction: 0.86), value: page)

                    bottomBar(current: pages[page], compact: compact)
                        .frame(maxWidth: maxWidth)
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, compact ? 6 : 10)
                        .padding(.bottom, max(geometry.safeAreaInsets.bottom, compact ? 8 : 14))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .trackScreen(.onboarding)
        .onAppear { AppAnalytics.shared.track(.onboardingStep, ["step": page + 1]) }
        .onChange(of: page) { value in AppAnalytics.shared.track(.onboardingStep, ["step": value + 1]) }
    }

    private func topBar(current: OnboardingPage, compact: Bool) -> some View {
        HStack(spacing: compact ? 9 : 12) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font((compact ? Font.caption : Font.subheadline).weight(.heavy))
                .foregroundStyle(.white)
                .frame(width: compact ? 34 : 42, height: compact ? 34 : 42)
                .background(
                    LinearGradient(colors: current.colors, startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: compact ? 10 : 12, style: .continuous)
                )

            Text("ChatCraft")
                .font((compact ? Font.title3 : Font.title2).weight(.heavy))
                .lineLimit(1)

            Spacer(minLength: 10)

            Button("Skip") {
                AppAnalytics.shared.track(.onboardingSkip, ["step": page + 1])
                onComplete()
            }
                .font((compact ? Font.subheadline : Font.headline).weight(.heavy))
                .foregroundStyle(current.colors[0])
                .padding(.horizontal, compact ? 14 : 18)
                .padding(.vertical, compact ? 8 : 11)
                .background(Color.primary.opacity(colorScheme == .dark ? 0.10 : 0.06), in: Capsule())
        }
    }

    private func bottomBar(current: OnboardingPage, compact: Bool) -> some View {
        VStack(spacing: compact ? 9 : 12) {
            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? current.colors[0] : Color.secondary.opacity(0.20))
                        .frame(width: index == page ? (compact ? 34 : 42) : 9, height: compact ? 6 : 7)
                }
            }

            Button {
                if page == pages.count - 1 {
                    AppAnalytics.shared.track(.onboardingComplete)
                    onComplete()
                } else {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                        page += 1
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    Text(page == pages.count - 1 ? "Get Started" : "Continue")
                    Image(systemName: "arrow.right")
                }
                .font((compact ? Font.headline : Font.title3).weight(.heavy))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: compact ? 52 : 60)
                .background(
                    LinearGradient(colors: current.colors, startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: compact ? 18 : 22, style: .continuous)
                )
            }
            .buttonStyle(InteractiveScaleButtonStyle())
        }
        .padding(compact ? 10 : 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: compact ? 22 : 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: compact ? 22 : 28, style: .continuous)
                .stroke(Color.primary.opacity(colorScheme == .dark ? 0.08 : 0.05), lineWidth: 1)
        )
    }

    private func background(for page: OnboardingPage) -> some View {
        ZStack {
            PremiumBackdrop()

            LinearGradient(
                colors: [
                    page.colors[0].opacity(colorScheme == .dark ? 0.22 : 0.13),
                    page.colors[1].opacity(colorScheme == .dark ? 0.14 : 0.08),
                    Color.clear,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }

    private func horizontalPadding(for width: CGFloat) -> CGFloat {
        width < 380 ? 16 : DeviceSize.horizontalPadding(for: width)
    }

    private func topPadding(safeTop: CGFloat, compact: Bool) -> CGFloat {
        max(safeTop + (compact ? 8 : 14), compact ? 16 : 24)
    }

    private func pageAreaHeight(size: CGSize, safeTop: CGFloat, safeBottom: CGFloat) -> CGFloat {
        let topReserved = safeTop + 78
        let bottomReserved = safeBottom + 112
        return max(size.height - topReserved - bottomReserved, 360)
    }
}

private struct OnboardingPageView: View {
    let page: OnboardingPage
    let compact: Bool
    let maxWidth: CGFloat
    let availableHeight: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: compact ? 14 : 22) {
                hero

                VStack(spacing: compact ? 8 : 12) {
                    Label(page.eyebrow, systemImage: page.icon)
                        .font((compact ? Font.caption : Font.subheadline).weight(.heavy))
                        .foregroundStyle(page.colors[0])
                        .lineLimit(1)
                        .padding(.horizontal, compact ? 12 : 16)
                        .padding(.vertical, compact ? 7 : 9)
                        .background(page.colors[0].opacity(0.12), in: Capsule())

                    Text(page.title)
                        .font(.system(size: compact ? 25 : 40, weight: .heavy, design: .rounded))
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .minimumScaleFactor(0.82)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(page.subtitle)
                        .font(.system(size: compact ? 14 : 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, compact ? 4 : 34)
                }

                features
            }
            .frame(maxWidth: maxWidth)
            .frame(minHeight: compact ? nil : availableHeight, alignment: .center)
            .padding(.horizontal, 4)
            .padding(.top, compact ? 8 : 14)
            .padding(.bottom, compact ? 10 : 24)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var hero: some View {
        ZStack {
            RoundedRectangle(cornerRadius: compact ? 24 : 34, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.065) : Color.white.opacity(0.76))
                .overlay(
                    RoundedRectangle(cornerRadius: compact ? 24 : 34, style: .continuous)
                        .stroke(
                            LinearGradient(colors: [page.colors[0].opacity(0.55), page.colors[1].opacity(0.24)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1.2
                        )
                )

            VStack(spacing: compact ? 12 : 16) {
                Image(systemName: page.icon)
                    .font(.system(size: compact ? 38 : 54, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: compact ? 78 : 106, height: compact ? 78 : 106)
                    .background(
                        LinearGradient(colors: page.colors, startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: compact ? 22 : 30, style: .continuous)
                    )
                    .shadow(color: page.colors[0].opacity(0.25), radius: 18, y: 10)

                HStack(spacing: compact ? 8 : 12) {
                    miniBubble(width: 0.42, color: page.colors[0].opacity(0.20))
                    miniBubble(width: 0.58, color: page.colors[1].opacity(0.22))
                }

                HStack(spacing: compact ? 8 : 12) {
                    miniBubble(width: 0.66, color: Color.primary.opacity(0.08))
                    miniBubble(width: 0.34, color: page.colors[0].opacity(0.18))
                }
            }
            .padding(compact ? 18 : 28)
        }
        .frame(height: heroHeight)
    }

    private func miniBubble(width: CGFloat, color: Color) -> some View {
        GeometryReader { proxy in
            Capsule()
                .fill(color)
                .frame(width: proxy.size.width * width)
                .frame(maxWidth: .infinity, alignment: width > 0.5 ? .trailing : .leading)
        }
        .frame(height: compact ? 14 : 18)
    }

    private var features: some View {
        VStack(spacing: compact ? 8 : 10) {
            ForEach(page.features, id: \.0) { feature in
                HStack(spacing: compact ? 10 : 14) {
                    Image(systemName: feature.2)
                        .font((compact ? Font.caption : Font.subheadline).weight(.heavy))
                        .foregroundStyle(.white)
                        .frame(width: compact ? 34 : 42, height: compact ? 34 : 42)
                        .background(page.colors[0], in: RoundedRectangle(cornerRadius: compact ? 11 : 14, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.0)
                            .font((compact ? Font.subheadline : Font.headline).weight(.heavy))
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                        Text(feature.1)
                            .font((compact ? Font.caption : Font.subheadline).weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(compact ? 2 : 1)
                            .minimumScaleFactor(0.78)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "checkmark.circle.fill")
                        .font((compact ? Font.title3 : Font.title2).weight(.heavy))
                        .foregroundStyle(page.colors[1])
                }
                .padding(compact ? 11 : 14)
                .background(Color.primary.opacity(colorScheme == .dark ? 0.075 : 0.055), in: RoundedRectangle(cornerRadius: compact ? 18 : 22, style: .continuous))
            }
        }
    }

    private var heroHeight: CGFloat {
        if compact { return 170 }
        if maxWidth > 620 { return 260 }
        return 220
    }
}

private struct OnboardingPage: Identifiable {
    let id = UUID()
    let eyebrow: String
    let title: String
    let subtitle: String
    let icon: String
    let colors: [Color]
    let features: [(String, String, String)]
}
