import Foundation

var checks = 0
func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
    checks += 1
}

// Never request ads for subscribers, while entitlements are unresolved, or without UMP permission.
for resolved in [false, true] {
    for paid in [false, true] {
        for consent in [false, true] {
            expect(AdPolicy.mayRequestAds(entitlementsResolved: resolved, isPaid: paid, consentAllowsAds: consent) == (resolved && !paid && consent), "Entitlement/consent gate failed")
        }
    }
}
let now = Date(timeIntervalSince1970: 1_800_000_000)
expect(AdPolicy.cooldownElapsed(lastPresentation: nil, now: now, interval: 30), "First presentation should be eligible")
expect(!AdPolicy.cooldownElapsed(lastPresentation: now.addingTimeInterval(-29.99), now: now, interval: 30), "App-open shown before 30 seconds")
expect(AdPolicy.cooldownElapsed(lastPresentation: now.addingTimeInterval(-30), now: now, interval: 30), "30-second boundary failed")
expect(!AdPolicy.cooldownElapsed(lastPresentation: now.addingTimeInterval(20), now: now, interval: 30), "Clock rollback should not bypass cooldown")
expect(!AdPolicy.cooldownElapsed(lastPresentation: now.addingTimeInterval(-59), now: now, interval: AdPolicy.interstitialCooldown), "Interstitial too frequent")
expect(AdPolicy.cooldownElapsed(lastPresentation: now.addingTimeInterval(-60), now: now, interval: AdPolicy.interstitialCooldown), "Interstitial must be eligible at one minute")
expect(AdPolicy.interstitialCooldown == 60, "Interstitial cooldown must stay one minute")
expect(!AdPolicy.isFresh(loadedAt: nil, now: now, lifetime: AdPolicy.appOpenLifetime), "Missing ad is not fresh")
expect(AdPolicy.isFresh(loadedAt: now.addingTimeInterval(-14_399), now: now, lifetime: AdPolicy.appOpenLifetime), "Valid app-open rejected")
expect(!AdPolicy.isFresh(loadedAt: now.addingTimeInterval(-14_400), now: now, lifetime: AdPolicy.appOpenLifetime), "Expired app-open accepted")
expect(!AdPolicy.isFresh(loadedAt: now.addingTimeInterval(-3_600), now: now, lifetime: AdPolicy.interstitialLifetime), "Expired interstitial accepted")
expect(!AdPolicy.isFresh(loadedAt: now.addingTimeInterval(1), now: now, lifetime: 100), "Clock rollback invalidates cached ad")
expect((0...10).filter { AdPolicy.insertsNative(afterRow: $0) } == [3, 6, 9], "Native cadence must use completed content rows")
expect(AdPolicy.bannerSlotHeight == 60, "Banner slot must stay 60 points")
#if DEBUG
let expectedUnits = ["ca-app-pub-3940256099942544/2934735716", "ca-app-pub-3940256099942544/3986624511", "ca-app-pub-3940256099942544/4411468910", "ca-app-pub-3940256099942544/5575463023"]
#else
let expectedUnits = ["ca-app-pub-3587863765939885/3504282612", "ca-app-pub-3587863765939885/2719657867", "ca-app-pub-3587863765939885/5345821202", "ca-app-pub-3587863765939885/6126576527"]
#endif
for (actual, expected) in zip([AdUnits.banner, AdUnits.native, AdUnits.interstitial, AdUnits.appOpen], expectedUnits) {
    expect(actual == expected, "Wrong ad unit for build configuration")
}
print("Passed \(checks) ad policy regression checks")
