import Foundation

/// Pure placement rules, shared by the SDK layer and the regression checks.
enum AdPolicy {
    static let appOpenCooldown: TimeInterval = 30
    static let interstitialCooldown: TimeInterval = 60
    static let appOpenLifetime: TimeInterval = 4 * 60 * 60
    static let interstitialLifetime: TimeInterval = 60 * 60
    static let bannerSlotHeight: Double = 60

    static func hasAdSupportedPlan(entitlementsResolved: Bool, isPaid: Bool) -> Bool {
        entitlementsResolved && !isPaid
    }

    static func mayRequestAds(entitlementsResolved: Bool, isPaid: Bool, consentAllowsAds: Bool) -> Bool {
        hasAdSupportedPlan(entitlementsResolved: entitlementsResolved, isPaid: isPaid) && consentAllowsAds
    }

    static func cooldownElapsed(lastPresentation: Date?, now: Date, interval: TimeInterval) -> Bool {
        guard let lastPresentation else { return true }
        return now.timeIntervalSince(lastPresentation) >= interval
    }

    static func isFresh(loadedAt: Date?, now: Date, lifetime: TimeInterval) -> Bool {
        guard let loadedAt else { return false }
        let age = now.timeIntervalSince(loadedAt)
        return age >= 0 && age < lifetime
    }

    static func insertsNative(afterRow row: Int) -> Bool { row > 0 && row.isMultiple(of: 3) }
}

enum AdUnits {
    #if DEBUG
    // Google's official iOS demo inventory for development and simulator testing.
    static let banner = "ca-app-pub-3940256099942544/2934735716"
    static let native = "ca-app-pub-3940256099942544/3986624511"
    static let interstitial = "ca-app-pub-3940256099942544/4411468910"
    static let appOpen = "ca-app-pub-3940256099942544/5575463023"
    #else
    // ChatCraft production inventory, compiled into Release / App Store archives only.
    static let banner = "ca-app-pub-3587863765939885/3504282612"
    static let native = "ca-app-pub-3587863765939885/2719657867"
    static let interstitial = "ca-app-pub-3587863765939885/5345821202"
    static let appOpen = "ca-app-pub-3587863765939885/6126576527"
    #endif
}
