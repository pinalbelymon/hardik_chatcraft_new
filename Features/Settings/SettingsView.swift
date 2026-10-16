import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var ads: AdsController
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    @AppStorage(AppAnalytics.preferenceKey) private var usageAnalytics = true
    @AppStorage("chatcraft_appearance") private var appearanceRawValue = AppAppearance.system.rawValue
    @AppStorage("chatcraft_default_export_format") private var defaultExportFormatRawValue = ExportFormat.vertical916.rawValue
    @AppStorage("chatcraft_default_theme") private var defaultThemeID = ChatTheme.defaultThemeID
    @AppStorage("chatcraft_default_watermark") private var defaultWatermark = true

    @State private var showPaywall = false
    @State private var statusMessage: String?

    private var isCompactDevice: Bool {
        DeviceSize.isCurrentCompactHeight
    }

    private var selectedAppearance: AppAppearance {
        AppAppearance(rawValue: appearanceRawValue) ?? .system
    }

    private var selectedFormat: ExportFormat {
        ExportFormat(rawValue: defaultExportFormatRawValue) ?? .vertical916
    }

    var body: some View {
        NavigationStack {
            ResponsiveContainer(maxWidth: 980) { width in
                VStack(alignment: .leading, spacing: isCompactDevice ? AppSpacing.sm : AppSpacing.lg) {
                    header(width: width)
                    planCard
                    VStack(spacing: 0) {
                        appearanceCard
                        NativeAdSlot(topSpacing: isCompactDevice ? AppSpacing.sm : AppSpacing.lg)
                    }
                    exportDefaultsCard(width: width)
                    Toggle("Usage analytics", isOn: $usageAnalytics)
                        .onChange(of: usageAnalytics) { AppAnalytics.shared.setEnabled($0) }
                    Text("Share app usage and purchase events to help improve ChatCraft. Chat content and photos are not included.")
                        .font(.caption).foregroundStyle(.secondary)
                    supportCard(width: width)
                    if ads.privacyOptionsRequired {
                        Button("Ad privacy choices") { ads.presentPrivacyOptions() }
                            .buttonStyle(.bordered)
                    }
                    Link("Report an inappropriate ad", destination: URL(string: "https://support.google.com/ads/answer/2662922")!)
                        .font(.subheadline)
                    Text("Use the ad’s AdChoices or info button to report that specific ad. You can also find reporting instructions above.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .alert("Ad Privacy", isPresented: Binding(get: { ads.privacyError != nil }, set: { if !$0 { ads.privacyError = nil } })) {
                Button("OK") { ads.privacyError = nil }
            } message: { Text(ads.privacyError ?? "") }
            .onChange(of: appearanceRawValue) { AppAnalytics.shared.track(.settingsChange, ["option": "appearance", "value": $0]) }
            .onChange(of: defaultExportFormatRawValue) { AppAnalytics.shared.track(.settingsChange, ["option": "default_export_format", "value": $0]) }
            .onChange(of: defaultThemeID) { AppAnalytics.shared.track(.settingsChange, ["option": "default_theme", "theme_id": $0]) }
            .onChange(of: defaultWatermark) { AppAnalytics.shared.track(.settingsChange, ["option": "watermark", "value": $0 ? 1 : 0]) }
            .trackScreen(.settings)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .background(PremiumBackdrop())
            .fullScreenCover(isPresented: $showPaywall) {
                NavigationStack { PaywallView() }
            }
        }
    }

    private func header(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Control Center")
                .font(AppFont.font(isCompactDevice ? 28 : 34, weight: .heavy, width: width))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
            Text("Manage appearance, export defaults, plan access, and support from one place.")
                .font(isCompactDevice ? AppFont.caption(width: width) : AppFont.body(width: width))
                .foregroundStyle(.secondary)
                .lineLimit(isCompactDevice ? 2 : nil)
                .minimumScaleFactor(0.84)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var planCard: some View {
        VStack(alignment: .leading, spacing: isCompactDevice ? AppSpacing.sm : AppSpacing.md) {
            HStack(alignment: .top, spacing: isCompactDevice ? AppSpacing.sm : AppSpacing.md) {
                Image(systemName: subscriptionManager.currentPlan == .pro ? "crown.fill" : "person.crop.circle.badge.checkmark")
                    .font((isCompactDevice ? Font.headline : Font.title2).weight(.bold))
                    .frame(width: isCompactDevice ? 42 : 54, height: isCompactDevice ? 42 : 54)
                    .foregroundStyle(.white)
                    .background(planTint, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: AppSpacing.xs) {
                        Text(subscriptionManager.currentPlan.title)
                            .font((isCompactDevice ? Font.headline : Font.title3).weight(.heavy))
                        Text("Current")
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(planTint)
                            .padding(.horizontal, AppSpacing.xs)
                            .padding(.vertical, 4)
                            .background(planTint.opacity(0.1), in: Capsule())
                    }

                    Text(subscriptionManager.planLimitDescription())
                        .font((isCompactDevice ? Font.caption : Font.subheadline).weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(isCompactDevice ? 2 : nil)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            HStack(spacing: isCompactDevice ? AppSpacing.xs : AppSpacing.sm) {
                Button {
                    showPaywall = true
                } label: {
                    Label("Upgrade Plan", systemImage: "arrow.up.circle.fill")
                        .font(.subheadline.weight(.heavy))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, isCompactDevice ? AppSpacing.xs : AppSpacing.sm)
                        .foregroundStyle(.white)
                        .background(AppColors.appTint, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                }
                .buttonStyle(InteractiveScaleButtonStyle())

                Button {
                    subscriptionManager.restorePurchases()
                    showStatus("Purchases restored in mock mode.")
                } label: {
                    Label("Restore", systemImage: "arrow.clockwise")
                        .font(.subheadline.weight(.heavy))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, isCompactDevice ? AppSpacing.xs : AppSpacing.sm)
                        .foregroundStyle(AppColors.appTint)
                        .background(AppColors.appTint.opacity(0.08), in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                }
                .buttonStyle(InteractiveScaleButtonStyle())
            }
        }
        .premiumSurface()
    }

    private var appearanceCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionTitleRow(title: "Appearance")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: isCompactDevice ? 104 : 126), spacing: AppSpacing.sm)], spacing: AppSpacing.sm) {
                ForEach(AppAppearance.allCases) { option in
                    SettingsChoiceTile(
                        title: option.title,
                        subtitle: appearanceSubtitle(for: option),
                        iconName: appearanceIcon(for: option),
                        isSelected: selectedAppearance == option
                    ) {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                            appearanceRawValue = option.rawValue
                        }
                    }
                }
            }
        }
        .premiumSurface()
    }

    private func exportDefaultsCard(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionTitleRow(title: "Export Defaults")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: isCompactDevice ? 118 : 142), spacing: AppSpacing.sm)], spacing: AppSpacing.sm) {
                ForEach(ExportFormat.allCases) { format in
                    SettingsChoiceTile(
                        title: format.title,
                        subtitle: format.sizeLabel,
                        iconName: exportIcon(for: format),
                        isSelected: selectedFormat == format
                    ) {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                            defaultExportFormatRawValue = format.rawValue
                        }
                    }
                }
            }

            NavigationLink {
                ThemeSelectionView(
                    selectedThemeID: Binding(
                        get: { ChatTheme.normalizedID(for: defaultThemeID) },
                        set: { defaultThemeID = ChatTheme.normalizedID(for: $0) }
                    )
                )
            } label: {
                DefaultThemeSettingsCard(theme: ChatTheme.theme(for: defaultThemeID))
            }
            .buttonStyle(InteractiveScaleButtonStyle())

            Button {
                if subscriptionManager.canExportWithoutWatermark() {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                        defaultWatermark.toggle()
                    }
                } else {
                    defaultWatermark = true
                    showPaywall = true
                }
            } label: {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: defaultWatermark ? "checkmark.seal.fill" : "seal")
                        .font(.title3.weight(.bold))
                        .frame(width: 44, height: 44)
                        .foregroundStyle(defaultWatermark ? AppColors.appTint : AppColors.success)
                        .background((defaultWatermark ? AppColors.appTint : AppColors.success).opacity(0.1), in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: AppSpacing.xs) {
                            Text("Watermark")
                                .font(.headline.weight(.heavy))
                            if !subscriptionManager.canExportWithoutWatermark() {
                                LockBadgeView(label: subscriptionManager.currentPlan.title)
                            }
                        }
                        Text(defaultWatermark ? "Enabled by default" : "Removed by default")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: defaultWatermark ? "togglepower" : "power")
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(defaultWatermark ? AppColors.appTint : AppColors.success)
                }
                .padding(AppSpacing.sm)
                .background(AppColors.panelBackground.opacity(0.65), in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                        .stroke(AppColors.hairline, lineWidth: 1)
                )
            }
            .buttonStyle(InteractiveScaleButtonStyle())
        }
        .premiumSurface()
    }

    private func supportCard(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionTitleRow(title: "Support")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: isCompactDevice ? 116 : 138), spacing: AppSpacing.sm)], spacing: AppSpacing.sm) {
                Link(destination: AppLegalLinks.privacyPolicy) {
                    SettingsActionLabel(title: "Privacy", iconName: "hand.raised.fill")
                }
                .trackLink("privacy")
                .buttonStyle(InteractiveScaleButtonStyle())
                Link(destination: AppLegalLinks.termsOfUse) {
                    SettingsActionLabel(title: "Terms", iconName: "doc.text.fill")
                }
                .trackLink("terms")
                .buttonStyle(InteractiveScaleButtonStyle())
                Link(destination: AppLegalLinks.eula) {
                    SettingsActionLabel(title: "EULA", iconName: "doc.badge.gearshape")
                }
                .trackLink("eula")
                .buttonStyle(InteractiveScaleButtonStyle())
                Link(destination: AppStoreLinks.writeReview) {
                    SettingsActionLabel(title: "Rate App", iconName: "star.fill")
                }
                .trackLink("rate_app")
                .buttonStyle(InteractiveScaleButtonStyle())
                ShareLink(item: "ChatCraft - Chat Story Maker") {
                    SettingsActionLabel(title: "Share App", iconName: "square.and.arrow.up.fill")
                }
                .buttonStyle(InteractiveScaleButtonStyle())
            }

            if let statusMessage {
                Text(statusMessage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(AppSpacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.panelBackground.opacity(0.65), in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .premiumSurface()
    }

    private var planTint: Color {
        switch subscriptionManager.currentPlan {
        case .free: return AppColors.violet
        case .lite: return AppColors.mint
        case .pro: return AppColors.amber
        }
    }

    private func appearanceIcon(for option: AppAppearance) -> String {
        switch option {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    private func appearanceSubtitle(for option: AppAppearance) -> String {
        switch option {
        case .system: return "Follow iPhone"
        case .light: return "Bright workspace"
        case .dark: return "Low-light editing"
        }
    }

    private func exportIcon(for format: ExportFormat) -> String {
        switch format {
        case .vertical916: return "rectangle.portrait.fill"
        case .square11: return "square.fill"
        case .portrait45: return "rectangle.fill"
        }
    }

    private func showStatus(_ message: String) {
        withAnimation(.easeInOut(duration: 0.18)) {
            statusMessage = message
        }
    }
}

private struct SettingsChoiceTile: View {
    let title: String
    let subtitle: String
    let iconName: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Image(systemName: iconName)
                        .font(.headline.weight(.bold))
                        .frame(width: 38, height: 38)
                        .foregroundStyle(isSelected ? .white : AppColors.appTint)
                        .background(isSelected ? AppColors.appTint : AppColors.appTint.opacity(0.1), in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(isSelected ? AppColors.success : .secondary)
                }

                Text(title)
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.sm)
            .background(isSelected ? AppColors.appTint.opacity(0.08) : AppColors.panelBackground.opacity(0.65), in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .stroke(isSelected ? AppColors.appTint.opacity(0.5) : AppColors.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(InteractiveScaleButtonStyle())
    }
}

private struct DefaultThemeSettingsCard: View {
    let theme: ChatTheme

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            ViewThatFits(in: .horizontal) {
                horizontalContent
                verticalContent
            }

            HStack(spacing: AppSpacing.xs) {
                ThemeSwatchStrip(theme: theme)
                SettingsThemePill(title: theme.category.title, iconName: categoryIconName)
                if theme.requiredPlan != .free {
                    SettingsThemePill(title: theme.requiredPlan.title, iconName: "crown.fill")
                }
            }
        }
        .padding(AppSpacing.md)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .stroke(borderColor, lineWidth: 1.2)
        )
        .shadow(color: Color(hex: theme.style.accentHex).opacity(colorScheme == .dark ? 0.18 : 0.1), radius: 18, y: 9)
    }

    private var horizontalContent: some View {
        HStack(alignment: .center, spacing: AppSpacing.md) {
            themeIcon

            themeText
                .layoutPriority(1)

            Spacer(minLength: AppSpacing.xs)

            changePill
        }
    }

    private var verticalContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                themeIcon
                themeText
                    .layoutPriority(1)
            }

            changePill
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var themeIcon: some View {
        ThemeIdentityBadge(theme: theme)
            .frame(width: 62, height: 62)
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(AppColors.appTint, in: Circle())
                    .overlay(Circle().stroke(AppColors.panelBackground, lineWidth: 2))
                    .offset(x: 5, y: 5)
            }
    }

    private var themeText: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Default Theme")
                .font(.caption.weight(.heavy))
                .foregroundStyle(AppColors.appTint)
                .textCase(.uppercase)

            Text(theme.name)
                .font(.title3.weight(.heavy))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
                .fixedSize(horizontal: false, vertical: true)

            Text(theme.subtitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var changePill: some View {
        HStack(spacing: AppSpacing.xs) {
            Text("Change")
                .font(.subheadline.weight(.heavy))
            Image(systemName: "chevron.right")
                .font(.caption.weight(.heavy))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.appTint, in: Capsule())
    }

    private var cardBackground: some ShapeStyle {
        LinearGradient(
            colors: [
                Color(hex: theme.style.accentHex).opacity(colorScheme == .dark ? 0.2 : 0.13),
                AppColors.panelBackground.opacity(colorScheme == .dark ? 0.82 : 0.9),
                Color(hex: theme.style.wallpaperAccentHex).opacity(colorScheme == .dark ? 0.08 : 0.12),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var borderColor: Color {
        Color(hex: theme.style.accentHex).opacity(colorScheme == .dark ? 0.42 : 0.32)
    }

    private var categoryIconName: String {
        switch theme.category {
        case .basic: return "square.grid.2x2.fill"
        case .social: return "bubble.left.and.bubble.right.fill"
        case .premium: return "sparkles"
        case .dark: return "moon.stars.fill"
        case .custom: return "slider.horizontal.3"
        }
    }
}

private struct SettingsThemePill: View {
    let title: String
    let iconName: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: iconName)
                .font(.caption2.weight(.heavy))
            Text(title)
                .font(.caption.weight(.heavy))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, 6)
        .background(AppColors.panelBackground.opacity(0.72), in: Capsule())
    }
}

private struct SettingsActionTile: View {
    let title: String
    let iconName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SettingsActionLabel(title: title, iconName: iconName)
        }
        .buttonStyle(InteractiveScaleButtonStyle())
    }
}

private struct SettingsActionLabel: View {
    let title: String
    let iconName: String

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: iconName)
                .font(.headline.weight(.bold))
                .frame(width: 36, height: 36)
                .foregroundStyle(AppColors.appTint)
                .background(AppColors.appTint.opacity(0.1), in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
            Text(title)
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
            Spacer()
        }
        .padding(AppSpacing.sm)
        .background(AppColors.panelBackground.opacity(0.65), in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .stroke(AppColors.hairline, lineWidth: 1)
        )
    }
}
