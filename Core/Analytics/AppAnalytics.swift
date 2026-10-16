import Foundation
import SwiftUI
import StoreKit
import FirebaseCore
import FirebaseAnalytics
import OSLog

enum AnalyticsScreen: String {
    case stories, projects, settings, onboarding, storyBuilder = "story_builder"
    case workspace, editor, preview, export, characters, themes, themePreview = "theme_preview"
    case allStyles = "all_styles", paywall, messageManager = "message_manager", messageEditor = "message_editor"
    case fullscreenPreview = "fullscreen_preview"
}

enum AppEvent: String {
    case onboardingStep = "onboarding_step", onboardingComplete = "onboarding_complete", onboardingSkip = "onboarding_skip"
    case storyCreate = "story_create", storyDuplicate = "story_duplicate", storyDelete = "story_delete", storyClose = "story_close"
    case themeSelect = "theme_select", themeApply = "theme_apply", themeCategory = "theme_category"
    case characterAdd = "character_add", characterDelete = "character_delete", characterSwitch = "character_switch"
    case messageAdd = "message_add", messageEdit = "message_edit", messageDelete = "message_delete", messageDuplicate = "message_duplicate"
    case previewReveal = "preview_reveal", previewComplete = "preview_complete", previewReset = "preview_reset"
    case previewAutoplay = "preview_autoplay", previewSpeed = "preview_speed", previewFullscreen = "preview_fullscreen"
    case exportStart = "export_start", exportSuccess = "export_success", exportFailure = "export_failure"
    case exportShareOpen = "export_share_open", exportShareResult = "export_share_result", exportOption = "export_option"
    case planSelect = "plan_select", billingSelect = "billing_select", purchaseStart = "purchase_start"
    case purchaseSuccess = "purchase_success", purchaseCancelled = "purchase_cancelled", purchasePending = "purchase_pending", purchaseFailed = "purchase_failed"
    case restoreStart = "restore_start", restoreComplete = "restore_complete", restoreFailed = "restore_failed"
    case adLoadResult = "ad_load_result", adPresentation = "ad_presentation"
    case settingsChange = "settings_change", externalLink = "external_link", featureLocked = "feature_locked"
}

/// One serial utility queue performs configuration, lightweight SDK calls and local deduplication.
/// No network wait, synchronous dispatch, user-content serialization or disk writes on the UI path.
final class AppAnalytics: @unchecked Sendable {
    static let shared = AppAnalytics()
    static let preferenceKey = "chatcraft_usage_analytics"
    private let queue = DispatchQueue(label: "com.chatcraft.analytics", qos: .utility)
    private let logger = Logger(subsystem: "com.chatcraft", category: "Analytics")
    private var configured = false
    private var started = false
    private var enabled = true
    private var screenStack: [(id: UUID, screen: AnalyticsScreen)] = []
    private var lastScreen: AnalyticsScreen?
    private var lastScreenAt = Date.distantPast
    private var transactions = AnalyticsTransactionLedger()

    func start() { queue.async { self.configure() } }

    private func configure() {
        guard !started else { return }
        started = true
        let configurationStarted = ProcessInfo.processInfo.systemUptime
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: path),
              options.bundleID == Bundle.main.bundleIdentifier else {
            logger.error("Analytics disabled: missing or mismatched Firebase configuration")
            #if DEBUG
            NSLog("[Analytics] Disabled: missing or mismatched Firebase configuration")
            #endif
            return
        }
        enabled = (UserDefaults.standard.object(forKey: Self.preferenceKey) as? Bool) ?? true
        if FirebaseApp.app() == nil { FirebaseApp.configure(options: options) }
        configured = true
        Analytics.setConsent([
            .analyticsStorage: enabled ? .granted : .denied,
            .adStorage: .denied, .adUserData: .denied, .adPersonalization: .denied
        ])
        Analytics.setAnalyticsCollectionEnabled(enabled)
        #if DEBUG
        Analytics.setDefaultEventParameters(["build_mode": "debug"])
        #else
        Analytics.setDefaultEventParameters(["build_mode": "release"])
        #endif
        transactions = AnalyticsTransactionLedger(storedIDs: UserDefaults.standard.stringArray(forKey: "analytics_recorded_transactions") ?? [])
        logger.notice("Firebase Analytics configured; collection enabled: \(self.enabled)")
        #if DEBUG
        NSLog("[Analytics] Configured off-main=%d enabled=%d elapsed_ms=%.1f", !Thread.isMainThread, enabled, (ProcessInfo.processInfo.systemUptime - configurationStarted) * 1000)
        #endif
    }

    func setEnabled(_ value: Bool) {
        queue.async {
            self.enabled = value
            UserDefaults.standard.set(value, forKey: Self.preferenceKey)
            guard self.configured else { return }
            Analytics.setConsent([.analyticsStorage: value ? .granted : .denied, .adStorage: .denied, .adUserData: .denied, .adPersonalization: .denied])
            Analytics.setAnalyticsCollectionEnabled(value)
            self.lastScreen = nil
        }
    }

    func appeared(_ screen: AnalyticsScreen, id: UUID) {
        queue.async {
            self.screenStack.removeAll { $0.id == id }
            self.screenStack.append((id, screen))
            self.logScreen(screen)
        }
    }

    func disappeared(id: UUID) {
        queue.async {
            let wasTop = self.screenStack.last?.id == id
            self.screenStack.removeAll { $0.id == id }
            if wasTop, let previous = self.screenStack.last?.screen { self.logScreen(previous) }
        }
    }

    private func logScreen(_ screen: AnalyticsScreen) {
        guard configured, enabled else { return }
        let now = Date()
        guard lastScreen != screen || now.timeIntervalSince(lastScreenAt) > 1 else { return }
        lastScreen = screen
        lastScreenAt = now
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [AnalyticsParameterScreenName: screen.rawValue, AnalyticsParameterScreenClass: screen.rawValue])
        #if DEBUG
        NSLog("[Analytics] screen_view %@", screen.rawValue)
        #endif
    }

    func track(_ event: AppEvent, _ parameters: [String: Any] = [:]) {
        queue.async {
            guard self.configured, self.enabled else { return }
            let safe = AnalyticsPayload.sanitize(parameters)
            Analytics.logEvent(event.rawValue, parameters: safe)
            #if DEBUG
            NSLog("[Analytics] event %@", event.rawValue)
            #endif
        }
    }

    /// Receives verified StoreKit transactions only. Restored entitlements are never revenue events.
    func verifiedPurchase(_ transaction: StoreKit.Transaction, plan: UserPlan) {
        queue.async {
            guard self.configured, self.enabled else { return }
            let id = String(transaction.id)
            guard transaction.revocationDate == nil, self.transactions.register(id) else { return }
            UserDefaults.standard.set(self.transactions.ids, forKey: "analytics_recorded_transactions")
            Analytics.logTransaction(transaction)
            Analytics.logEvent(AppEvent.purchaseSuccess.rawValue, parameters: ["plan": plan.rawValue, "product_id": transaction.productID])
        }
    }
}

private struct ScreenAnalyticsModifier: ViewModifier {
    let screen: AnalyticsScreen
    @State private var token = UUID()
    func body(content: Content) -> some View {
        content.onAppear { AppAnalytics.shared.appeared(screen, id: token) }
            .onDisappear { AppAnalytics.shared.disappeared(id: token) }
    }
}

extension View {
    func trackScreen(_ screen: AnalyticsScreen) -> some View { modifier(ScreenAnalyticsModifier(screen: screen)) }
    func trackLink(_ name: String) -> some View {
        simultaneousGesture(TapGesture().onEnded { AppAnalytics.shared.track(.externalLink, ["link": name]) })
    }
}
