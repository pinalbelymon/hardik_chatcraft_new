# AdMob integration and review

## Installed

Google Mobile Ads 13.11.0 and Google User Messaging Platform 3.1.0 via official Swift Package Manager repositories. Versions are recorded in `ChatCraft.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`.

Debug builds use Google's sample iOS app ID and four official demo ad units. Release builds and App Store archives use the publisher-provided ChatCraft app ID and production ad units. The app ID is selected through the ADMOB_APP_ID Xcode build setting; unit IDs use the Swift DEBUG condition. Production configuration is verified without requesting or clicking live ads. There is no mediation or custom ad-click handling.

## Placements

- Banner: New Story, story workspace (Export only; Editor and Preview have no banner), Theme Studio, Characters, and the home All Styles gallery. The workspace banner appears only on Export; switching to Editor or Preview removes the banner and its reserved space. No banners in exported media, fullscreen story playback, onboarding, or the purchase screen. Standard unmodified 320 × 50 creative inside a 60-point slot, 5 points above/below; hidden while the software keyboard is open.
- Native: one small 180-point card on Stories after the project/message statistics, and on Settings after Appearance. Additional cards appear after every three content rows in Projects, Theme Studio, and All Styles. A two-column grid counts pairs of items as a row. There are no ads inserted into fictional conversation messages or export canvases. SDK MediaView is 120 × 120; headline, available body/advertiser, CTA, Ad attribution and SDK AdChoices remain visible. SDK owns all click handling.
- Interstitial: attempted after every successful image/video export, once its UI updates; failed exports do not show an ad. Also attempted when the user explicitly taps the workspace Done (Save & Close) button and navigation has finished. Sharing alone and normal back/tab navigation do not trigger it. Must already be cached; no waiting for a network response. A 60-second shared full-screen cooldown prevents frequent interruptions.
- App open: cached warm-foreground only, after the first two sessions. Minimum 30 seconds after the last full-screen dismissal, persisted across launches. No periodic timer, no late-loaded/cold-start interruption. A branded resume surface is behind the ad. Skip while editing, previewing, exporting, building, purchasing, consenting, another modal is open, or any full-screen ad is already showing. Returning from an ad click does not trigger another ad.

## Eligibility and privacy

- StoreKit current entitlements are resolved before any ads are eligible. Both Lite and Pro suppress every format. Expired and revoked subscriptions are excluded. Purchase/restore in progress suppresses requests too; loaded inventory is cleared when eligibility changes.
- Subscription refresh precedes StoreKit product fetching so product network latency cannot cause a subscriber to see ads.
- UMP requests an update per process/session startup and presents a required consent form before starting the ads SDK. `canRequestAds` remains a mandatory gate. Valid consent retained by UMP may be used after a network error, as Google documents; consent is never bypassed.
- ATT is requested only when applicable, after the UMP gate. Denial leaves app functionality available and publisher personalization disabled. Max content rating is General.
- Settings exposes Ad privacy choices when UMP requires it, and instructions for reporting an inappropriate ad using the creative's AdChoices/info control.
- No conversation contents, characters, titles, photos or exported files are supplied to ad requests. The Google SDK can still collect its own device/network/advertising data; the release privacy policy and App Privacy disclosures must describe that.

## Performance and no-fill

SDK initialization and ad loading do not block navigation. One cached app-open and one cached interstitial; overlapping loads are deduplicated. Failed full-screen loads have a 60-second retry backoff and retry only on a later natural lifecycle/action event. App-open inventory expires after four hours; interstitial after one hour.

Banner/native have a 12-second loading bound with Reduce Motion-aware shimmer. A failed, timed-out or ineligible placement is an empty view with no reserved height, padding, or ad-specific gap. Native requests are owned by lazily created content rows, not recreated by every view update. Late callbacks cannot restore an ad after an eligibility change. Banner views stay attached while loading; no ad stretching or cropping.

## Verification

- Debug iOS simulator build, arm64 and x86_64. Optimized Release simulator build also checked.
- 26 pure policy/configuration regression checks per build mode: entitlement/consent matrix, 30-second and 60-second cooldowns, clock rollback, cache expiry, row cadence, and 60-point banner slot.
- Simulator: banner test creative visible on New Story / workspace. Initial loading and collapsed failure state inspected.
- Simulator: native test creative after the third Basic theme row. Google's native validator reported “No implementation issues found”.
- Simulator: image export succeeds with no ad in the rendered image. The previous share-completion placement was verified with a test creative; current placements are export success and explicit Save & Close, with a one-minute cooldown.
- Simulator: app-open test creative appears on home-screen warm resume and SDK Continue returns to the app; immediate re-foreground does not show another ad.

Run policy checks from the repository root:

```sh
swiftc -D DEBUG -module-cache-path /tmp/chatcraft-swift-test-cache Core/Ads/AdPolicy.swift Tests/Ads/main.swift -o /tmp/chatcraft-debug-ad-tests
/tmp/chatcraft-debug-ad-tests
swiftc -module-cache-path /tmp/chatcraft-swift-test-cache Core/Ads/AdPolicy.swift Tests/Ads/main.swift -o /tmp/chatcraft-release-ad-tests
/tmp/chatcraft-release-ad-tests
```

A real purchased subscription, production UMP messages in EEA/UK/Switzerland, ATT on a physical device, and live inventory cannot be certified by simulator/policy checks alone. Test those with your configured AdMob app and StoreKit sandbox before release. App Store / AdMob approval is not guaranteed by an integration.

## Release setup owned by the publisher

1. Production IDs are configured for Release. Keep registered test devices for pre-release testing of Release builds; never click live ads. Debug builds retain Google demo inventory.
2. Configure applicable messages under AdMob Privacy & messaging. Test consent accept/deny, privacy options and offline startup for each applicable region. Confirm age/audience treatment for the app's actual audience; the integration does not assume the user is a child or adult.
3. Privacy Policy and Terms of Use now link to the publisher-provided belymoninfotech.com pages on both Paywall and Settings; Apple Standard EULA is also linked in both places. Review the hosted policy for current Google SDK disclosures and update App Store Connect privacy details. Settings Rate App opens the App Store write-review destination for Apple ID 6786126568.
4. Publish the correct app-ads.txt entry on the domain listed as the app's developer website; obtain it from your AdMob account rather than using Google's demo publisher ID.
5. Verify Lite and Pro purchase, restore, renewal, expiration and revocation using StoreKit sandbox. Confirm all loaded/loading placements disappear after purchase and no app-open is shown on returning from the purchase sheet.
6. Test smallest iPhone/iPad, landscape, Dynamic Type, Reduce Motion, keyboard, no internet, no fill, repeated foregrounds, export/share cancellation and full-screen ad close controls on physical devices.
7. Review App Store age rating and ads disclosures and verify the ad reporting affordance works for your production creative.

## Current official references (checked 14 October 2026)

- https://developers.google.com/admob/ios/quick-start
- https://developers.google.com/admob/ios/test-ads
- https://developers.google.com/admob/ios/privacy
- https://developers.google.com/admob/ios/banner/fixed-size
- https://developers.google.com/admob/ios/native/advanced
- https://developers.google.com/admob/ios/app-open
- https://developers.google.com/admob/ios/interstitial
- https://developer.apple.com/app-store/review/guidelines/ (2.5.18, 5.1)
- https://developer.apple.com/app-store/user-privacy-and-data-use/
