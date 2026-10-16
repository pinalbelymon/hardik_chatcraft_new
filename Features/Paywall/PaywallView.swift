import SwiftUI
import UIKit

struct PaywallView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedPlan: UserPlan = .free
    @State private var billingCadence = "Yearly"
    @State private var statusMessage: String?

    private let comparedFeatures: [FeatureAccess] = [
        .unlimitedStories,
        .imageMessages,
        .videoMessages,
        .voiceMessages,
        .typingIndicators,
        .messageReactions,
        .autoplay,
        .premiumThemes,
        .customThemes,
        .watermarkRemoval,
        .videoExport,
        .allExportFormats
    ]

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var isCompactDevice: Bool {
        DeviceSize.isCurrentCompactHeight
    }

    private var paywallMaxWidth: CGFloat {
        isPad ? 1180 : 980
    }

    var body: some View {
        ResponsiveContainer(maxWidth: paywallMaxWidth) { width in
            VStack(alignment: .leading, spacing: isCompactDevice ? AppSpacing.sm : AppSpacing.md) {
                header(width: width)
                planCards(width: width)
                billingSection
                selectedPlanFeatures
                comparisonTable
            }
        }
        .suppressAppOpenAds()
        .trackScreen(.paywall)
        .navigationTitle("Upgrade")
        .navigationBarTitleDisplayMode(.inline)
        .background(PremiumBackdrop())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            fixedBottomBar
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
        .onAppear {
            syncSelectionWithCurrentPlan()
        }
        .task {
            await subscriptionManager.loadProducts()
            await subscriptionManager.refreshPurchasedPlan()
            syncSelectionWithCurrentPlan()
        }
        .onChange(of: billingCadence) { value in
            AppAnalytics.shared.track(.billingSelect, ["plan": selectedPlan.rawValue, "cadence": value])
        }
        .onChange(of: subscriptionManager.currentPlan) { newPlan in
            selectPlan(newPlan)
        }
    }

    private func header(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Make bigger chat stories")
                .font(AppFont.font(isCompactDevice ? 24 : 30, weight: .heavy, width: width))
            Text("Unlock more projects, richer message types, premium themes, advanced playback, and cleaner exports.")
                .font(isCompactDevice ? AppFont.caption(width: width) : AppFont.body(width: width))
                .foregroundStyle(.secondary)
                .lineLimit(isCompactDevice ? 2 : nil)
                .minimumScaleFactor(0.86)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func planCards(width: CGFloat) -> some View {
        let isWide = width > 680
        return Group {
            if isPad {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: AppSpacing.md),
                        GridItem(.flexible(), spacing: AppSpacing.md)
                    ],
                    alignment: .leading,
                    spacing: AppSpacing.md
                ) {
                    ForEach(UserPlan.allCases) { plan in
                        planButton(plan)
                    }
                }
            } else if isWide {
                HStack(alignment: .top, spacing: AppSpacing.sm) {
                    ForEach(UserPlan.allCases) { plan in
                        planButton(plan)
                    }
                }
            } else {
                VStack(spacing: isCompactDevice ? AppSpacing.xxs : AppSpacing.xs) {
                    ForEach(UserPlan.allCases) { plan in
                        planButton(plan)
                    }
                }
            }
        }
    }

    private func planButton(_ plan: UserPlan) -> some View {
        Button {
            AppAnalytics.shared.track(.planSelect, ["plan": plan.rawValue])
            selectPlan(plan)
        } label: {
            PlanCardView(
                plan: plan,
                price: price(for: plan),
                subtitle: subtitle(for: plan),
                isSelected: selectedPlan == plan,
                badge: displayBadge(for: plan),
                trialText: trialText(for: plan),
                highlights: Array(featureHighlights(for: plan).prefix(2))
            )
        }
        .buttonStyle(.plain)
    }

    private var billingSection: some View {
        VStack(alignment: .leading, spacing: isCompactDevice ? AppSpacing.xs : AppSpacing.sm) {
            Text("Billing")
                .font(.headline.weight(.bold))

            if selectedPlan == .free {
                HStack {
                    Text("Forever")
                        .font(.subheadline.weight(.bold))
                    Spacer()
                    Text("₹0")
                        .font(.subheadline.weight(.heavy))
                }
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.sm)
                .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            } else {
                Picker("Billing", selection: $billingCadence) {
                    ForEach(cadences(for: selectedPlan), id: \.self) { cadence in
                        Text(cadence).tag(cadence)
                    }
                }
                .pickerStyle(.segmented)
            }

            Text(billingNote)
                .font((isCompactDevice ? Font.caption2 : Font.footnote).weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(isCompactDevice ? 3 : nil)
                .minimumScaleFactor(0.82)
                .fixedSize(horizontal: false, vertical: true)
        }
        .premiumSurface(padding: isCompactDevice ? AppSpacing.xs : AppSpacing.sm)
    }

    private var selectedPlanFeatures: some View {
        VStack(alignment: .leading, spacing: isCompactDevice ? AppSpacing.xs : AppSpacing.sm) {
            Text("\(selectedPlan.title) Includes")
                .font(.headline.weight(.bold))

            ForEach(featureHighlights(for: selectedPlan), id: \.self) { title in
                FeatureRowView(title: title, isIncluded: true)
            }
        }
        .premiumSurface(padding: isCompactDevice ? AppSpacing.sm : AppSpacing.md)
    }

    private var comparisonTable: some View {
        VStack(alignment: .leading, spacing: isCompactDevice ? AppSpacing.xs : AppSpacing.sm) {
            VStack(alignment: .leading, spacing: isCompactDevice ? 4 : AppSpacing.xs) {
                HStack(spacing: AppSpacing.sm) {
                    Label("Compare plans", systemImage: "square.grid.2x2.fill")
                        .font(.headline.weight(.heavy))

                    Spacer()

                    Text("\(includedFeatureCount)/\(comparedFeatures.count)")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppSpacing.xs)
                        .padding(.vertical, 6)
                        .background(tint(for: selectedPlan), in: Capsule())
                }

                Text("Switch plans below to see exactly what unlocks.")
                    .font((isCompactDevice ? Font.caption2 : Font.caption).weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: AppSpacing.xs) {
                ForEach(UserPlan.allCases) { plan in
                    comparisonPlanChip(plan)
                }
            }

            selectedPlanSummary

            VStack(spacing: isCompactDevice ? 5 : 7) {
                ForEach(comparedFeatures) { feature in
                    comparisonFeatureRow(feature)
                }
            }
        }
        .premiumSurface(padding: isCompactDevice ? AppSpacing.xs : AppSpacing.sm)
    }

    private var selectedPlanSummary: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: selectedPlan == .pro ? "crown.fill" : selectedPlan == .lite ? "bolt.fill" : "sparkles")
                    .font(.headline.weight(.heavy))
                    .frame(width: 38, height: 38)
                    .foregroundStyle(.white)
                    .background(actionGradient, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(selectedPlan.title) coverage")
                        .font(.subheadline.weight(.heavy))
                    Text("\(includedFeatureCount) of \(comparedFeatures.count) premium capabilities available")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                }

                Spacer(minLength: AppSpacing.xs)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(colorScheme == .dark ? 0.10 : 0.07))

                    Capsule()
                        .fill(actionGradient)
                        .frame(width: max(8, proxy.size.width * comparisonProgress))
                }
            }
            .frame(height: 9)
        }
        .padding(AppSpacing.sm)
        .background(
            LinearGradient(
                colors: [
                    tint(for: selectedPlan).opacity(colorScheme == .dark ? 0.20 : 0.12),
                    Color.primary.opacity(colorScheme == .dark ? 0.045 : 0.025)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .stroke(tint(for: selectedPlan).opacity(0.28), lineWidth: 1)
        )
    }

    private func comparisonPlanChip(_ plan: UserPlan) -> some View {
        Button {
            AppAnalytics.shared.track(.planSelect, ["plan": plan.rawValue])
            selectPlan(plan)
        } label: {
            VStack(spacing: 3) {
                Image(systemName: plan == .pro ? "crown.fill" : plan == .lite ? "bolt.fill" : "sparkles")
                    .font(.caption.weight(.heavy))
                Text(plan.title)
                    .font(.caption.weight(.heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .frame(height: isPad ? 64 : (isCompactDevice ? 48 : 54))
            .foregroundStyle(selectedPlan == plan ? .white : tint(for: plan))
            .background(
                selectedPlan == plan
                    ? AnyShapeStyle(LinearGradient(colors: [tint(for: plan), tint(for: plan).opacity(0.78)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    : AnyShapeStyle(Color.primary.opacity(colorScheme == .dark ? 0.075 : 0.045)),
                in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .stroke(selectedPlan == plan ? tint(for: plan).opacity(0.42) : AppColors.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(InteractiveScaleButtonStyle())
    }

    private func selectPlan(_ plan: UserPlan) {
        selectedPlan = plan
        // Free displays its own Forever label; it must not overwrite paid billing selection.
        if plan != .free && !cadences(for: plan).contains(billingCadence) {
            billingCadence = "Yearly"
        }
    }

    private func syncSelectionWithCurrentPlan() {
        selectPlan(subscriptionManager.currentPlan)
    }

    private func comparisonFeatureRow(_ feature: FeatureAccess) -> some View {
        HStack(spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: icon(for: feature))
                    .font((isPad ? Font.subheadline : Font.caption).weight(.heavy))
                    .foregroundStyle(tint(for: selectedPlan))
                    .frame(width: isPad ? 32 : 24, height: isPad ? 32 : 24)
                    .background(tint(for: selectedPlan).opacity(0.11), in: Circle())

                Text(feature.title)
                    .font((isPad ? Font.subheadline : Font.caption).weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(UserPlan.allCases) { plan in
                availabilityBadge(included: planIncludes(plan, feature), plan: plan)
            }
        }
        .padding(.horizontal, AppSpacing.xs)
        .padding(.horizontal, isCompactDevice ? 6 : AppSpacing.xs)
        .padding(.vertical, isPad ? 10 : (isCompactDevice ? 6 : 8))
        .background(comparisonRowBackground, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .stroke(AppColors.hairline.opacity(0.8), lineWidth: 1)
        )
    }

    private func availabilityBadge(included: Bool, plan: UserPlan) -> some View {
        Image(systemName: included ? "checkmark" : "lock.fill")
            .font((isPad ? Font.caption : Font.caption2).weight(.heavy))
            .foregroundStyle(included ? tint(for: plan) : .secondary.opacity(0.65))
            .frame(width: isPad ? 54 : (isCompactDevice ? 36 : 42), height: isPad ? 34 : (isCompactDevice ? 24 : 28))
            .background(
                included
                    ? tint(for: plan).opacity(selectedPlan == plan ? 0.18 : 0.10)
                    : Color.primary.opacity(colorScheme == .dark ? 0.07 : 0.045),
                in: Capsule()
            )
    }

    private var fixedBottomBar: some View {
        VStack(spacing: isCompactDevice ? AppSpacing.xs : AppSpacing.sm) {
            HStack(spacing: isCompactDevice ? AppSpacing.xs : AppSpacing.sm) {
                Image(systemName: selectedPlan == .pro ? "crown.fill" : selectedPlan == .lite ? "bolt.fill" : "sparkles")
                    .font(.headline.weight(.heavy))
                    .frame(width: isCompactDevice ? 36 : 42, height: isCompactDevice ? 36 : 42)
                    .foregroundStyle(.white)
                    .background(actionGradient, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(selectedPlan.title)
                        .font(.headline.weight(.heavy))
                    Text(actionSubtitle)
                        .font(selectedPlan == .free ? .caption.weight(.semibold) : .subheadline.weight(.heavy))
                        .foregroundStyle(selectedPlan == .free ? Color.secondary : tint(for: selectedPlan))
                        .lineLimit(2)
                        .minimumScaleFactor(0.86)
                }

                Spacer(minLength: AppSpacing.xs)
            }

            Button {
                Task {
                    await handlePrimaryAction()
                }
            } label: {
                HStack(spacing: isCompactDevice ? AppSpacing.xs : AppSpacing.sm) {
                    if subscriptionManager.isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: selectedPlan == .free ? "arrow.right.circle.fill" : "gift.fill")
                            .font((isCompactDevice ? Font.headline : Font.title3).weight(.heavy))
                    }

                    Text(subscriptionManager.isPurchasing ? "Processing..." : actionTitle)
                        .font((isPad ? Font.title2 : isCompactDevice ? Font.headline : Font.title3).weight(.heavy))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Image(systemName: "chevron.right")
                        .font(.headline.weight(.heavy))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, isCompactDevice ? AppSpacing.sm : AppSpacing.md)
                .frame(height: isPad ? 64 : (isCompactDevice ? 50 : 58))
                .background(actionGradient, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
                .shadow(color: tint(for: selectedPlan).opacity(colorScheme == .dark ? 0.22 : 0.18), radius: 16, y: 8)
            }
            .buttonStyle(InteractiveScaleButtonStyle())
            .disabled(subscriptionManager.isPurchasing || subscriptionManager.isLoadingProducts)

            HStack(spacing: AppSpacing.xs) {
                Button("Restore Purchase") {
                    Task {
                        await handleRestore()
                    }
                }
                .font(.caption.weight(.heavy))
                .foregroundStyle(tint(for: selectedPlan))
                .padding(.horizontal, AppSpacing.xs)
                .padding(.vertical, 7)
                .background(tint(for: selectedPlan).opacity(0.12), in: Capsule())
                .disabled(subscriptionManager.isPurchasing)

                Spacer()


            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.78)

            HStack(spacing: AppSpacing.md) {
                Link("Terms of Use", destination: AppLegalLinks.termsOfUse).trackLink("terms")
                Link("Privacy Policy", destination: AppLegalLinks.privacyPolicy).trackLink("privacy")
                Link("EULA", destination: AppLegalLinks.eula).trackLink("eula")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)

            if let statusMessage {
                Text(statusMessage)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, isCompactDevice ? AppSpacing.sm : AppSpacing.md)
        .padding(.top, isCompactDevice ? AppSpacing.xxs : AppSpacing.xs)
        .padding(.bottom, isCompactDevice ? AppSpacing.xs : AppSpacing.sm)
        .frame(maxWidth: paywallMaxWidth)
        .frame(maxWidth: .infinity)
        .background {
            bottomBarBackground
                .ignoresSafeArea(edges: .bottom)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(AppColors.hairline)
                        .frame(height: 1)
                }
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.28 : 0.10), radius: 18, y: -8)
        }
        .zIndex(50)
    }

    private var bottomBarBackground: Color {
        colorScheme == .dark
            ? Color(hex: "#272625")
            : Color(hex: "#F7F7F5")
    }

    private func price(for plan: UserPlan) -> String {
        guard plan != .free else { return "₹0" }
        return subscriptionManager.priceText(for: plan, cadence: billingCadence)
    }

    private func handlePrimaryAction() async {
        statusMessage = nil

        guard selectedPlan != subscriptionManager.currentPlan else {
            dismiss()
            return
        }

        guard selectedPlan != .free else {
            await subscriptionManager.refreshPurchasedPlan()
            if subscriptionManager.currentPlan == .free {
                dismiss()
            } else {
                statusMessage = "\(subscriptionManager.currentPlan.title) is active from the App Store."
            }
            return
        }

        let completed = await subscriptionManager.purchase(plan: selectedPlan, cadence: billingCadence)
        if completed {
            statusMessage = "\(selectedPlan.title) is active."
            dismiss()
        } else if let message = subscriptionManager.purchaseErrorMessage {
            statusMessage = message
        }
    }

    private func handleRestore() async {
        statusMessage = nil
        await subscriptionManager.restorePurchasesFromStore()

        if let message = subscriptionManager.purchaseErrorMessage {
            statusMessage = message
        } else if subscriptionManager.currentPlan == .free {
            statusMessage = "No active subscription found."
        } else {
            statusMessage = "\(subscriptionManager.currentPlan.title) restored."
        }
    }

    private func subtitle(for plan: UserPlan) -> String {
        switch plan {
        case .free:
            return "3 stories, 2 characters, text-only, watermarked image export."
        case .lite:
            return "25 stories, 5 characters, images, typing, reactions, and more themes."
        case .pro:
            return "Unlimited creation, all message types, all themes, custom builder, no watermark."
        }
    }

    private func badge(for plan: UserPlan) -> String? {
        switch plan {
        case .free: return nil
        case .lite: return "Popular"
        case .pro: return "Best Value"
        }
    }

    private func displayBadge(for plan: UserPlan) -> String? {
        plan == subscriptionManager.currentPlan ? "Current Plan" : badge(for: plan)
    }

    private func trialText(for plan: UserPlan) -> String? {
        switch plan {
        case .free:
            return "Free forever"
        case .lite, .pro:
            return "3-day free trial included"
        }
    }

    private var billingNote: String {
        switch selectedPlan {
        case .free:
            return "Free plan does not start a subscription."
        case .lite, .pro:
            return "All ads are removed while your subscription is active. Includes 3 free days. After the trial, the selected subscription renews automatically unless canceled in App Store settings before renewal."
        }
    }

    private func cadences(for plan: UserPlan) -> [String] {
        switch plan {
        case .free: return ["Forever"]
        case .lite: return ["Weekly", "Monthly", "Yearly"]
        case .pro: return ["Weekly", "Monthly", "Yearly"]
        }
    }

    private func featureHighlights(for plan: UserPlan) -> [String] {
        switch plan {
        case .free:
            return [
                "Create up to 3 stories",
                "Maximum 2 characters per story",
                "Text messages only",
                "Apple Messages and WhatsApp themes",
                "Screenshot export with watermark"
            ]
        case .lite:
            return [
                "Ad-free — all ads removed",
                "Create up to 25 stories",
                "Up to 5 characters per story",
                "Text, image, typing, separator, and reaction messages",
                "Facebook Messenger, Telegram, SMS, and Instagram themes",
                "Basic auto-play preview"
            ]
        case .pro:
            return [
                "Ad-free — all ads removed",
                "Unlimited stories and characters",
                "All message types including video, voice, calls, system, and stickers",
                "All themes plus Custom Theme Builder",
                "Adjustable playback speed and premium animations",
                "Screenshot export without watermark and video export placeholder access"
            ]
        }
    }

    private func planIncludes(_ plan: UserPlan, _ feature: FeatureAccess) -> Bool {
        switch plan {
        case .free:
            return [.textMessages, .screenshotExport].contains(feature)
        case .lite:
            return [
                .textMessages,
                .imageMessages,
                .typingIndicators,
                .dateSeparators,
                .messageReactions,
                .autoplay,
                .screenshotExport
            ].contains(feature)
        case .pro:
            return true
        }
    }

    private var actionTitle: String {
        guard selectedPlan != subscriptionManager.currentPlan else {
            return selectedPlan == .free ? "Continue Free" : "Current Plan Active"
        }
        return selectedPlan == .free ? "Continue Free" : "Start 3-Day Free Trial"
    }

    private var actionSubtitle: String {
        guard selectedPlan != subscriptionManager.currentPlan else {
            return selectedPlan == .free ? "No subscription required" : "\(selectedPlan.title) is active now"
        }
        switch selectedPlan {
        case .free:
            return "No subscription required"
        case .lite, .pro:
            return "3-day free trial, then \(price(for: selectedPlan))"
        }
    }

    private var actionGradient: LinearGradient {
        switch selectedPlan {
        case .free:
            return LinearGradient(colors: [AppColors.electricBlue, Color(hex: "#1D4ED8")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .lite:
            return LinearGradient(colors: [Color(hex: "#0F766E"), Color(hex: "#0EA5E9")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .pro:
            return LinearGradient(colors: [Color(hex: "#B7791F"), Color(hex: "#F59E0B")], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var comparisonRowBackground: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.045)
            : Color.black.opacity(0.032)
    }

    private var includedFeatureCount: Int {
        comparedFeatures.filter { planIncludes(selectedPlan, $0) }.count
    }

    private var comparisonProgress: CGFloat {
        guard !comparedFeatures.isEmpty else { return 0 }
        return CGFloat(includedFeatureCount) / CGFloat(comparedFeatures.count)
    }

    private func tint(for plan: UserPlan) -> Color {
        switch plan {
        case .free: return AppColors.electricBlue
        case .lite: return AppColors.mint
        case .pro: return AppColors.amber
        }
    }

    private func icon(for feature: FeatureAccess) -> String {
        switch feature {
        case .unlimitedStories: return "folder.badge.plus"
        case .unlimitedCharacters: return "person.2.fill"
        case .textMessages: return "text.bubble.fill"
        case .imageMessages: return "photo.fill"
        case .videoMessages: return "play.rectangle.fill"
        case .voiceMessages: return "waveform"
        case .typingIndicators: return "ellipsis.message.fill"
        case .dateSeparators: return "calendar"
        case .messageReactions: return "face.smiling.fill"
        case .missedCallMessages: return "phone.down.fill"
        case .systemMessages: return "info.circle.fill"
        case .stickerMessages: return "sparkles"
        case .autoplay: return "play.fill"
        case .adjustablePlaybackSpeed: return "speedometer"
        case .premiumAnimations: return "wand.and.stars"
        case .screenshotExport: return "photo.on.rectangle"
        case .videoExport: return "video.fill"
        case .watermarkRemoval: return "checkmark.seal.fill"
        case .customThemes: return "slider.horizontal.3"
        case .premiumThemes: return "paintpalette.fill"
        case .allExportFormats: return "square.resize"
        }
    }
}
