import SwiftUI
import Combine
import GoogleMobileAds
import UserMessagingPlatform
import AppTrackingTransparency
import OSLog

@MainActor
final class AdsController: NSObject, ObservableObject, FullScreenContentDelegate {
    static let shared = AdsController()
    @Published private(set) var canRequestAds = false
    @Published private(set) var privacyOptionsRequired = false
    @Published private(set) var showingAppOpen = false
    @Published private(set) var isRewardedReady = false
    @Published var privacyError: String?

    private let logger = Logger(subsystem: "com.chatcraft", category: "Ads")
    private var isEligible = false
    private var consentStarted = false
    private var sdkStarted = false
    private var sdkReady = false
    private var presentedAd: AnyObject?
    private var presentedFormat = ""
    private var preparingConsent = false
    private var showingFullScreen = false

    // Cached ad instances
    private var appOpen: AppOpenAd?
    private var interstitial: InterstitialAd?
    private var rewarded: RewardedAd?

    // Load timestamps
    private var appOpenLoadedAt: Date?
    private var interstitialLoadedAt: Date?
    private var rewardedLoadedAt: Date?

    // In-flight loading flags
    private var loadingAppOpen = false
    private var loadingInterstitial = false
    private var loadingRewarded = false

    // Exponential backoff retry state
    private var interstitialRetryCount = 0
    private var appOpenRetryCount = 0
    private var rewardedRetryCount = 0
    private var interstitialRetryTask: Task<Void, Never>?
    private var appOpenRetryTask: Task<Void, Never>?
    private var rewardedRetryTask: Task<Void, Never>?

    // Presentation timestamps (independent tracking so formats do not cannibalize each other)
    private var lastAppOpenPresentation: Date? = UserDefaults.standard.object(forKey: "ads_last_app_open") as? Date
    private var lastInterstitialPresentation: Date? = UserDefaults.standard.object(forKey: "ads_last_interstitial") as? Date
    private var lastFullScreen: Date? = UserDefaults.standard.object(forKey: "ads_last_fullscreen") as? Date

    private var didBackground = false
    private var startedSession = false
    private var sessions = 0
    private var appOpenBlockers: Set<UUID> = []
    private var subscriptions: Set<AnyCancellable> = []
    private var onDismissCallback: (() -> Void)?
    private var onRewardEarnedCallback: (() -> Void)?

    func bind(to manager: SubscriptionManager) {
        guard subscriptions.isEmpty else { return }
        Publishers.CombineLatest3(manager.$currentPlan, manager.$hasResolvedEntitlements, manager.$isPurchasing)
            .receive(on: RunLoop.main)
            .sink { [weak self] plan, resolved, purchasing in
                self?.setEligibility(AdPolicy.hasAdSupportedPlan(entitlementsResolved: resolved, isPaid: plan != .free) && !purchasing)
            }.store(in: &subscriptions)
    }

    func startSession() {
        guard !startedSession else { return }
        startedSession = true
        sessions = UserDefaults.standard.integer(forKey: "ads_session_count") + 1
        UserDefaults.standard.set(sessions, forKey: "ads_session_count")
        if isEligible { gatherConsentIfNeeded() }
    }

    private func setEligibility(_ eligible: Bool) {
        isEligible = eligible
        if !eligible {
            canRequestAds = false
            appOpen = nil
            interstitial = nil
            rewarded = nil
            isRewardedReady = false
            cancelAllRetries()
        } else if startedSession {
            if consentStarted && !preparingConsent { activateIfPermitted() }
            else { gatherConsentIfNeeded() }
        }
    }

    private func cancelAllRetries() {
        interstitialRetryTask?.cancel()
        appOpenRetryTask?.cancel()
        rewardedRetryTask?.cancel()
    }

    private func gatherConsentIfNeeded() {
        guard !consentStarted, isEligible, startedSession else { return }
        consentStarted = true
        preparingConsent = true
        ConsentInformation.shared.requestConsentInfoUpdate(with: RequestParameters()) { [weak self] error in
            Task { @MainActor in
                guard let self else { return }
                defer { self.preparingConsent = false }
                if let error {
                    self.logger.error("Consent update failed: \(error.localizedDescription, privacy: .public)")
                } else if self.isEligible {
                    do { try await ConsentForm.loadAndPresentIfRequired(from: Self.presenter) }
                    catch { self.logger.error("Consent form failed: \(error.localizedDescription, privacy: .public)") }
                }
                self.privacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
                guard self.isEligible, ConsentInformation.shared.canRequestAds else { return }
                if UIApplication.shared.applicationState == .active,
                   ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
                    _ = await ATTrackingManager.requestTrackingAuthorization()
                }
                self.activateIfPermitted()
            }
        }
    }

    private func activateIfPermitted() {
        guard isEligible, ConsentInformation.shared.canRequestAds else {
            canRequestAds = false
            return
        }
        // Allow full advertiser demand across standard ratings for maximized fill rate & eCPM.
        // Google UMP handles IAB TCF strings and consent signals natively.
        if !sdkStarted {
            sdkStarted = true
            MobileAds.shared.start { [weak self] _ in
                Task { @MainActor in
                    self?.sdkReady = true
                    self?.finishSDKStartup()
                }
            }
        } else { finishSDKStartup() }
    }

    private func finishSDKStartup() {
        guard sdkReady else { return }
        canRequestAds = isEligible && ConsentInformation.shared.canRequestAds
        if canRequestAds {
            preloadAllAds()
        }
    }

    func presentPrivacyOptions() {
        guard !preparingConsent, !showingFullScreen else { return }
        preparingConsent = true
        canRequestAds = false
        appOpen = nil
        interstitial = nil
        rewarded = nil
        isRewardedReady = false
        Task {
            defer { preparingConsent = false }
            do { try await ConsentForm.presentPrivacyOptionsForm(from: Self.presenter) }
            catch { privacyError = "Privacy options could not be opened. Please try again." }
            privacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
            activateIfPermitted()
        }
    }

    func setAppOpenBlocked(_ blocked: Bool, id: UUID) {
        if blocked { appOpenBlockers.insert(id) } else { appOpenBlockers.remove(id) }
    }

    func sceneChanged(_ phase: ScenePhase) {
        if phase == .background {
            didBackground = !showingFullScreen && !preparingConsent
        } else if phase == .active, didBackground {
            didBackground = false
            showAppOpenIfReady()
            preloadAllAds()
        }
    }

    func preloadAllAds() {
        guard canRequestAds else { return }
        Task { await loadAppOpen() }
        Task { await loadInterstitial() }
        Task { await loadRewarded() }
    }

    func preloadFullScreenAds() {
        preloadAllAds()
    }

    // MARK: - App Open Ad Loading with Auto-Retry

    private func loadAppOpen() async {
        guard canRequestAds, !loadingAppOpen else { return }
        if let current = appOpen, AdPolicy.isFresh(loadedAt: appOpenLoadedAt, now: Date(), lifetime: AdPolicy.appOpenLifetime) {
            return
        }
        loadingAppOpen = true
        defer { loadingAppOpen = false }
        do {
            let ad = try await AppOpenAd.load(with: AdUnits.appOpen, request: Request())
            guard canRequestAds else { return }
            appOpen = ad
            appOpenLoadedAt = Date()
            appOpenRetryCount = 0
            appOpenRetryTask?.cancel()
            ad.fullScreenContentDelegate = self
            #if DEBUG
            NSLog("[Ads] App-open ad successfully cached and ready")
            #endif
        } catch {
            appOpen = nil
            logger.notice("App-open load failed: \(error.localizedDescription, privacy: .public)")
            scheduleAppOpenRetry()
        }
    }

    private func scheduleAppOpenRetry() {
        guard canRequestAds else { return }
        appOpenRetryCount += 1
        let delaySeconds = min(60.0, Double(appOpenRetryCount * 5 + 3))
        appOpenRetryTask?.cancel()
        appOpenRetryTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
            guard !Task.isCancelled, let self else { return }
            await self.loadAppOpen()
        }
    }

    // MARK: - Interstitial Ad Loading with Auto-Retry

    func preloadInterstitialIfNeeded() {
        guard canRequestAds else { return }
        if interstitial == nil || !AdPolicy.isFresh(loadedAt: interstitialLoadedAt, now: Date(), lifetime: AdPolicy.interstitialLifetime) {
            Task { await loadInterstitial(force: true) }
        }
    }

    private func loadInterstitial(force: Bool = false) async {
        guard canRequestAds, !loadingInterstitial else { return }
        if !force, let current = interstitial, AdPolicy.isFresh(loadedAt: interstitialLoadedAt, now: Date(), lifetime: AdPolicy.interstitialLifetime) {
            return
        }
        loadingInterstitial = true
        defer { loadingInterstitial = false }
        do {
            let ad = try await InterstitialAd.load(with: AdUnits.interstitial, request: Request())
            guard canRequestAds else { return }
            interstitial = ad
            interstitialLoadedAt = Date()
            interstitialRetryCount = 0
            interstitialRetryTask?.cancel()
            ad.fullScreenContentDelegate = self
            #if DEBUG
            NSLog("[Ads] Interstitial ad successfully cached and ready")
            #endif
        } catch {
            interstitial = nil
            logger.notice("Interstitial load failed: \(error.localizedDescription, privacy: .public)")
            scheduleInterstitialRetry()
        }
    }

    private func scheduleInterstitialRetry() {
        guard canRequestAds else { return }
        interstitialRetryCount += 1
        let delaySeconds = min(60.0, Double(interstitialRetryCount * 5 + 3))
        interstitialRetryTask?.cancel()
        interstitialRetryTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
            guard !Task.isCancelled, let self else { return }
            await self.loadInterstitial()
        }
    }

    // MARK: - Rewarded Ad Loading with Auto-Retry

    private func loadRewarded() async {
        guard canRequestAds, !loadingRewarded else { return }
        if let current = rewarded, AdPolicy.isFresh(loadedAt: rewardedLoadedAt, now: Date(), lifetime: AdPolicy.interstitialLifetime) {
            isRewardedReady = true
            return
        }
        loadingRewarded = true
        defer { loadingRewarded = false }
        do {
            let ad = try await RewardedAd.load(with: AdUnits.rewarded, request: Request())
            guard canRequestAds else { return }
            rewarded = ad
            rewardedLoadedAt = Date()
            rewardedRetryCount = 0
            rewardedRetryTask?.cancel()
            isRewardedReady = true
            ad.fullScreenContentDelegate = self
            #if DEBUG
            NSLog("[Ads] Rewarded ad successfully cached and ready")
            #endif
        } catch {
            rewarded = nil
            isRewardedReady = false
            logger.notice("Rewarded load failed: \(error.localizedDescription, privacy: .public)")
            scheduleRewardedRetry()
        }
    }

    private func scheduleRewardedRetry() {
        guard canRequestAds else { return }
        rewardedRetryCount += 1
        let delaySeconds = min(60.0, Double(rewardedRetryCount * 5 + 5))
        rewardedRetryTask?.cancel()
        rewardedRetryTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
            guard !Task.isCancelled, let self else { return }
            await self.loadRewarded()
        }
    }

    // MARK: - Presentation Safety & View Controller Hierarchy

    private var canPresentFullScreen: Bool {
        guard canRequestAds, !showingFullScreen, !preparingConsent,
              UIApplication.shared.applicationState == .active,
              let presenter = Self.topPresenter ?? Self.presenter,
              presenter.view.window != nil,
              !presenter.isBeingDismissed else {
            return false
        }
        return true
    }

    // MARK: - App Open Presentation

    private func showAppOpenIfReady() {
        guard canPresentFullScreen, sessions >= 1, appOpenBlockers.isEmpty,
              AdPolicy.cooldownElapsed(lastPresentation: lastAppOpenPresentation, now: Date(), interval: AdPolicy.appOpenCooldown),
              AdPolicy.isFresh(loadedAt: appOpenLoadedAt, now: Date(), lifetime: AdPolicy.appOpenLifetime),
              let ad = appOpen,
              let presenter = Self.topPresenter ?? Self.presenter,
              !presenter.isBeingDismissed else { return }

        do {
            try ad.canPresent(from: presenter)
            presentedAd = ad
            presentedFormat = "app_open"
            showingFullScreen = true
            showingAppOpen = true
            appOpen = nil
            lastAppOpenPresentation = Date()
            UserDefaults.standard.set(lastAppOpenPresentation, forKey: "ads_last_app_open")
            ad.fullScreenContentDelegate = self
            ad.present(from: presenter)
            Task { await loadAppOpen() }
        } catch {
            appOpen = nil
            logger.notice("App open cannot present: \(error.localizedDescription, privacy: .public)")
            Task { await loadAppOpen() }
        }
    }

    // MARK: - Interstitial Presentation

    /// Shows an interstitial ad if eligible and available, then invokes onDismiss after dismissal.
    /// If an ad is pre-cached, it displays instantly. If loading, waits up to 4s. Otherwise continues seamlessly.
    func showInterstitial(onDismiss: @escaping () -> Void) {
        #if DEBUG
        NSLog("[Ads] showInterstitial requested; canRequest=%d showingFS=%d ready=%d", canRequestAds, showingFullScreen, interstitial != nil)
        #endif
        guard canRequestAds, !showingFullScreen, !preparingConsent,
              UIApplication.shared.applicationState == .active else {
            onDismiss()
            return
        }

        // Fast path: cached & fresh interstitial ad ready for instant presentation
        if let ad = interstitial,
           AdPolicy.isFresh(loadedAt: interstitialLoadedAt, now: Date(), lifetime: AdPolicy.interstitialLifetime),
           let presenter = Self.topPresenter ?? Self.presenter,
           !presenter.isBeingDismissed {
            do {
                try ad.canPresent(from: presenter)
                self.onDismissCallback = onDismiss
                self.presentedAd = ad
                self.presentedFormat = "interstitial"
                self.showingFullScreen = true
                self.interstitial = nil
                self.lastInterstitialPresentation = Date()
                UserDefaults.standard.set(lastInterstitialPresentation, forKey: "ads_last_interstitial")
                ad.fullScreenContentDelegate = self
                ad.present(from: presenter)
                Task { await self.loadInterstitial() }
                return
            } catch {
                self.interstitial = nil
                logger.notice("Cached interstitial present failed: \(error.localizedDescription, privacy: .public)")
            }
        }

        // Fallback: brief bounded wait for load
        Task { @MainActor in
            await self.loadAndPresentInterstitial(onDismiss: onDismiss)
        }
    }

    private func loadAndPresentInterstitial(onDismiss: @escaping () -> Void) async {
        guard canRequestAds, !showingFullScreen, !preparingConsent,
              UIApplication.shared.applicationState == .active,
              let presenter = Self.topPresenter ?? Self.presenter,
              !presenter.isBeingDismissed else {
            onDismiss()
            return
        }

        loadingInterstitial = true
        defer { loadingInterstitial = false }

        let loadTask = Task { @MainActor () -> InterstitialAd in
            try await InterstitialAd.load(with: AdUnits.interstitial, request: Request())
        }

        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: 4_000_000_000)
            loadTask.cancel()
        }

        do {
            let ad = try await loadTask.value
            timeoutTask.cancel()

            guard canRequestAds, !showingFullScreen,
                  UIApplication.shared.applicationState == .active,
                  let currentPresenter = Self.topPresenter ?? Self.presenter,
                  !currentPresenter.isBeingDismissed else {
                self.interstitial = ad
                self.interstitialLoadedAt = Date()
                ad.fullScreenContentDelegate = self
                onDismiss()
                return
            }

            try ad.canPresent(from: currentPresenter)
            ad.fullScreenContentDelegate = self
            self.onDismissCallback = onDismiss
            self.presentedAd = ad
            self.presentedFormat = "interstitial"
            self.showingFullScreen = true
            self.lastInterstitialPresentation = Date()
            UserDefaults.standard.set(lastInterstitialPresentation, forKey: "ads_last_interstitial")
            ad.present(from: currentPresenter)
            Task { await self.loadInterstitial() }
        } catch {
            timeoutTask.cancel()
            logger.notice("Quick interstitial load skipped: \(error.localizedDescription, privacy: .public)")
            self.preloadFullScreenAds()
            onDismiss()
        }
    }

    /// Called at natural breaks in user workflows (e.g., Save & Close, switching from Editor to Preview, or completing a story).
    func completedNaturalBreak() {
        #if DEBUG
        NSLog("[Ads] Natural break requested; eligible=%d ready=%d canPresent=%d", canRequestAds, interstitial != nil, canPresentFullScreen)
        #endif
        guard canPresentFullScreen,
              AdPolicy.cooldownElapsed(lastPresentation: lastInterstitialPresentation, now: Date(), interval: AdPolicy.interstitialCooldown),
              let ad = interstitial,
              AdPolicy.isFresh(loadedAt: interstitialLoadedAt, now: Date(), lifetime: AdPolicy.interstitialLifetime),
              let presenter = Self.topPresenter ?? Self.presenter,
              !presenter.isBeingDismissed else {
            preloadFullScreenAds()
            return
        }

        do {
            try ad.canPresent(from: presenter)
            presentedAd = ad
            presentedFormat = "interstitial"
            showingFullScreen = true
            interstitial = nil
            lastInterstitialPresentation = Date()
            UserDefaults.standard.set(lastInterstitialPresentation, forKey: "ads_last_interstitial")
            ad.fullScreenContentDelegate = self
            ad.present(from: presenter)
            Task { await loadInterstitial() }
        } catch {
            interstitial = nil
            logger.notice("Natural break interstitial cannot present: \(error.localizedDescription, privacy: .public)")
            preloadFullScreenAds()
        }
    }

    // MARK: - Rewarded Ad Presentation

    /// Presents a rewarded ad. If an ad is cached, it presents immediately.
    /// If an ad is not currently cached, it requests and fetches one on demand while invoking onStartLoading,
    /// presents the ad upon retrieval, and ONLY calls onReward if the user finishes watching the ad.
    func showRewarded(
        onStartLoading: (() -> Void)? = nil,
        onReadyToPresent: (() -> Void)? = nil,
        onReward: @escaping () -> Void,
        onError: ((String) -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        guard canRequestAds, !showingFullScreen, !preparingConsent,
              UIApplication.shared.applicationState == .active else {
            onError?("Ad is currently unavailable.")
            onDismiss?()
            return
        }

        // Fast path: cached & fresh rewarded ad available
        if let ad = rewarded,
           AdPolicy.isFresh(loadedAt: rewardedLoadedAt, now: Date(), lifetime: AdPolicy.interstitialLifetime),
           let presenter = Self.topPresenter ?? Self.presenter,
           !presenter.isBeingDismissed {
            do {
                try ad.canPresent(from: presenter)
                onReadyToPresent?()
                self.onDismissCallback = {
                    onDismiss?()
                }
                self.presentedAd = ad
                self.presentedFormat = "rewarded"
                self.showingFullScreen = true
                self.rewarded = nil
                self.isRewardedReady = false
                ad.fullScreenContentDelegate = self
                ad.present(from: presenter) {
                    #if DEBUG
                    NSLog("[Ads] User earned reward from cached rewarded ad")
                    #endif
                    onReward()
                }
                Task { await self.loadRewarded() }
                return
            } catch {
                self.rewarded = nil
                self.isRewardedReady = false
                logger.notice("Cached rewarded cannot present: \(error.localizedDescription, privacy: .public)")
            }
        }

        // Slow path: Not yet cached, request and fetch ad with loader
        onStartLoading?()
        Task { @MainActor in
            await self.loadAndPresentRewarded(
                onReadyToPresent: onReadyToPresent,
                onReward: onReward,
                onError: onError,
                onDismiss: onDismiss
            )
        }
    }

    private func loadAndPresentRewarded(
        onReadyToPresent: (() -> Void)?,
        onReward: @escaping () -> Void,
        onError: ((String) -> Void)?,
        onDismiss: (() -> Void)?
    ) async {
        guard canRequestAds, !showingFullScreen, !preparingConsent,
              UIApplication.shared.applicationState == .active,
              let presenter = Self.topPresenter ?? Self.presenter,
              !presenter.isBeingDismissed else {
            onReadyToPresent?()
            onError?("Ad could not be presented at this time.")
            onDismiss?()
            return
        }

        loadingRewarded = true
        defer { loadingRewarded = false }

        let loadTask = Task { @MainActor () -> RewardedAd in
            try await RewardedAd.load(with: AdUnits.rewarded, request: Request())
        }

        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: 8_000_000_000)
            loadTask.cancel()
        }

        do {
            let ad = try await loadTask.value
            timeoutTask.cancel()

            guard canRequestAds, !showingFullScreen,
                  UIApplication.shared.applicationState == .active,
                  let currentPresenter = Self.topPresenter ?? Self.presenter,
                  !currentPresenter.isBeingDismissed else {
                onReadyToPresent?()
                self.rewarded = ad
                self.rewardedLoadedAt = Date()
                self.isRewardedReady = true
                ad.fullScreenContentDelegate = self
                onError?("Presentation cancelled.")
                onDismiss?()
                return
            }

            try ad.canPresent(from: currentPresenter)
            onReadyToPresent?()
            self.onDismissCallback = {
                onDismiss?()
            }
            self.presentedAd = ad
            self.presentedFormat = "rewarded"
            self.showingFullScreen = true
            self.rewarded = nil
            self.isRewardedReady = false
            ad.fullScreenContentDelegate = self
            ad.present(from: currentPresenter) {
                #if DEBUG
                NSLog("[Ads] User earned reward from on-demand rewarded ad")
                #endif
                onReward()
            }
            Task { await self.loadRewarded() }
        } catch {
            timeoutTask.cancel()
            onReadyToPresent?()
            logger.notice("On-demand rewarded load failed: \(error.localizedDescription, privacy: .public)")
            scheduleRewardedRetry()
            onError?("Ad is currently unavailable. Please check your internet connection and try again.")
            onDismiss?()
        }
    }

    // MARK: - GADFullScreenContentDelegate

    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        AppAnalytics.shared.track(.adPresentation, ["format": presentedFormat])
        lastFullScreen = Date()
        UserDefaults.standard.set(lastFullScreen, forKey: "ads_last_fullscreen")
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        finishPresentation()
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        logger.error("Full screen presentation failed: \(error.localizedDescription, privacy: .public)")
        finishPresentation()
    }

    private func finishPresentation() {
        presentedAd = nil
        showingAppOpen = false
        showingFullScreen = false
        didBackground = false
        lastFullScreen = Date()
        UserDefaults.standard.set(lastFullScreen, forKey: "ads_last_fullscreen")
        preloadAllAds()

        if let callback = onDismissCallback {
            onDismissCallback = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                callback()
            }
        }
    }

    // MARK: - View Controller Navigation Resolution

    static var presenter: UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first { $0.activationState == .foregroundActive }?.windows.first { $0.isKeyWindow }?.rootViewController
    }

    static var topPresenter: UIViewController? {
        topViewController(from: presenter)
    }

    static func topViewController(from root: UIViewController?) -> UIViewController? {
        guard let root else { return nil }
        if let nav = root as? UINavigationController {
            return topViewController(from: nav.visibleViewController ?? nav.topViewController)
        }
        if let tab = root as? UITabBarController {
            return topViewController(from: tab.selectedViewController)
        }
        if let presented = root.presentedViewController, !presented.isBeingDismissed {
            return topViewController(from: presented)
        }
        return root
    }
}
