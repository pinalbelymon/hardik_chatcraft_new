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
    private var appOpen: AppOpenAd?
    private var interstitial: InterstitialAd?
    private var appOpenLoadedAt: Date?
    private var interstitialLoadedAt: Date?
    private var loadingAppOpen = false
    private var loadingInterstitial = false
    private var lastAppOpenAttempt: Date?
    private var lastInterstitialAttempt: Date?
    private var lastFullScreen: Date? = UserDefaults.standard.object(forKey: "ads_last_fullscreen") as? Date
    private var didBackground = false
    private var startedSession = false
    private var sessions = 0
    private var appOpenBlockers: Set<UUID> = []
    private var subscriptions: Set<AnyCancellable> = []

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
        } else if startedSession {
            if consentStarted && !preparingConsent { activateIfPermitted() }
            else { gatherConsentIfNeeded() }
        }
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
                // UMP can retain valid consent after a network error. Never bypass canRequestAds.
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
        // ATT denial never blocks app features. Do not enable personalized ads without ATT approval.
        MobileAds.shared.requestConfiguration.publisherPrivacyPersonalizationState =
            ATTrackingManager.trackingAuthorizationStatus == .authorized ? .default : .disabled
        MobileAds.shared.requestConfiguration.maxAdContentRating = .general
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
        if canRequestAds { preloadFullScreenAds() }
    }

    func presentPrivacyOptions() {
        guard !preparingConsent, !showingFullScreen else { return }
        preparingConsent = true
        canRequestAds = false
        appOpen = nil
        interstitial = nil
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
            // Returning from an ad click / consent form must not trigger another full-screen ad.
            didBackground = !showingFullScreen && !preparingConsent
        } else if phase == .active, didBackground {
            didBackground = false
            showAppOpenIfReady()
            preloadFullScreenAds()
        }
    }

    private func preloadFullScreenAds() {
        guard canRequestAds else { return }
        Task { await loadAppOpen() }
        Task { await loadInterstitial() }
    }

    private func loadAppOpen() async {
        guard canRequestAds, !loadingAppOpen,
              !AdPolicy.isFresh(loadedAt: appOpenLoadedAt, now: Date(), lifetime: AdPolicy.appOpenLifetime) || appOpen == nil,
              AdPolicy.cooldownElapsed(lastPresentation: lastAppOpenAttempt, now: Date(), interval: 60) else { return }
        loadingAppOpen = true
        lastAppOpenAttempt = Date()
        defer { loadingAppOpen = false }
        do {
            let ad = try await AppOpenAd.load(with: AdUnits.appOpen, request: Request())
            guard canRequestAds else { return }
            appOpen = ad
            #if DEBUG
            NSLog("[Ads] App-open test ad ready")
            #endif
            appOpenLoadedAt = Date()
            ad.fullScreenContentDelegate = self
        } catch {
            appOpen = nil
            logger.notice("App-open unavailable: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func loadInterstitial() async {
        guard canRequestAds, !loadingInterstitial,
              !AdPolicy.isFresh(loadedAt: interstitialLoadedAt, now: Date(), lifetime: AdPolicy.interstitialLifetime) || interstitial == nil,
              AdPolicy.cooldownElapsed(lastPresentation: lastInterstitialAttempt, now: Date(), interval: 60) else { return }
        loadingInterstitial = true
        lastInterstitialAttempt = Date()
        defer { loadingInterstitial = false }
        do {
            let ad = try await InterstitialAd.load(with: AdUnits.interstitial, request: Request())
            guard canRequestAds else { return }
            interstitial = ad
            #if DEBUG
            NSLog("[Ads] Interstitial test ad ready")
            #endif
            interstitialLoadedAt = Date()
            ad.fullScreenContentDelegate = self
        } catch {
            interstitial = nil
            logger.notice("Interstitial unavailable: \(error.localizedDescription, privacy: .public)")
        }
    }

    private var safeToPresent: Bool {
        canRequestAds && !showingFullScreen && !preparingConsent &&
        UIApplication.shared.applicationState == .active &&
        Self.presenter?.presentedViewController == nil && Self.presenter?.view.window != nil
    }

    private func showAppOpenIfReady() {
        // Warm resumes only; never show a late network response over usable content.
        guard safeToPresent, sessions >= 3, appOpenBlockers.isEmpty,
              AdPolicy.cooldownElapsed(lastPresentation: lastFullScreen, now: Date(), interval: AdPolicy.appOpenCooldown),
              AdPolicy.isFresh(loadedAt: appOpenLoadedAt, now: Date(), lifetime: AdPolicy.appOpenLifetime),
              let ad = appOpen else { return }
        do { try ad.canPresent(from: Self.presenter) } catch { appOpen = nil; return }
        presentedAd = ad
        presentedFormat = "app_open"
        showingFullScreen = true
        showingAppOpen = true
        appOpen = nil
        ad.present(from: Self.presenter)
    }

    /// Called after a successful export or an explicit Save & Close, at a natural break.
    func completedNaturalBreak() {
        #if DEBUG
        NSLog("[Ads] Natural break; eligible=%d ready=%d safe=%d", canRequestAds, interstitial != nil, safeToPresent)
        #endif
        guard safeToPresent,
              AdPolicy.cooldownElapsed(lastPresentation: lastFullScreen, now: Date(), interval: AdPolicy.interstitialCooldown),
              AdPolicy.isFresh(loadedAt: interstitialLoadedAt, now: Date(), lifetime: AdPolicy.interstitialLifetime),
              let ad = interstitial else { preloadFullScreenAds(); return }
        do { try ad.canPresent(from: Self.presenter) } catch { interstitial = nil; return }
        presentedAd = ad
        presentedFormat = "interstitial"
        showingFullScreen = true
        interstitial = nil
        ad.present(from: Self.presenter)
    }

    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        AppAnalytics.shared.track(.adPresentation, ["format": presentedFormat])
        // Preserve frequency protection even if the process is killed while an ad is open.
        lastFullScreen = Date()
        UserDefaults.standard.set(lastFullScreen, forKey: "ads_last_fullscreen")
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) { finishPresentation() }
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        finishPresentation()
    }
    private func finishPresentation() {
        presentedAd = nil
        showingAppOpen = false
        showingFullScreen = false
        didBackground = false
        lastFullScreen = Date()
        UserDefaults.standard.set(lastFullScreen, forKey: "ads_last_fullscreen")
        preloadFullScreenAds()
    }

    static var presenter: UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first { $0.activationState == .foregroundActive }?.windows.first { $0.isKeyWindow }?.rootViewController
    }
}
