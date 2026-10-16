# Firebase Analytics event catalogue

Firebase Analytics Core 13.0.1 is installed via Firebase's official Swift package. Only the Analytics Core product and FirebaseCore are linked; Analytics does not collect IDFA or enable advertising audiences/conversions. Existing AdMob consent/ATT behavior is separate.

The publisher's existing `App/GoogleService-Info.plist` is copied once into the bundle. Its BUNDLE_ID matches com.chatcraft. The supplied file has IS_ANALYTICS_ENABLED=false. The client explicitly enables collection according to the Usage analytics preference, but Firebase Console must have Google Analytics enabled and a GA4 property linked to see reports. Console-side configuration and remote receipt of events have not been verified from this environment.

## Screens

Manual `screen_view` with stable screen_name and screen_class values:

stories, projects, settings, onboarding, story_builder, editor, preview, export, characters, themes, theme_preview, all_styles, paywall, message_manager, message_editor, fullscreen_preview.

Screen observers run on appear/disappear, restore the underlying screen after a modal closes, and suppress immediate duplicate observations. Automatic UIViewController screen reporting is disabled so SwiftUI hosting controllers do not produce a second set of screen names. Export/render canvases do not have screen observers.

## Action events

| Flow | Events | Context |
| --- | --- | --- |
| Onboarding | onboarding_step, onboarding_complete, onboarding_skip | Step number only |
| Stories | story_create, story_duplicate, story_delete, story_close | Built-in theme/format, counts; no title/ID |
| Themes | theme_select, theme_apply, theme_category | Built-in theme/category IDs |
| Characters | character_add, character_delete, character_switch | Counts and source only |
| Editor | message_add, message_edit, message_delete, message_duplicate | Message type, count/source; manager reorder uses message_edit with source=reorder |
| Preview | preview_reveal, preview_complete, preview_reset, preview_autoplay, preview_speed, preview_fullscreen | Manual reveals, completion summary, controls; not one event per autoplay frame/message |
| Export | export_start, export_success, export_failure, export_option | Image/video, format, scope, counts, total elapsed milliseconds; failure category, never raw error text/file paths |
| Share | export_share_open, export_share_result | Media type and completed/cancelled flag; never the file contents/URL |
| Paywall | plan_select, billing_select, feature_locked | Plan, cadence and the source of the gated action |
| Purchase | purchase_start, purchase_success, purchase_cancelled, purchase_pending, purchase_failed | Plan/product ID/cadence; bounded failure categories |
| Restore | restore_start, restore_complete, restore_failed | Result and resulting plan; restoration is not a new revenue event |
| Settings | settings_change | Appearance, default theme/format, watermark |
| Legal/reviews | external_link | terms, privacy, eula, rate_app; click action only, not external browsing history |
| Ads | ad_load_result, ad_presentation | Loaded banner/native and presented full-screen format; not a second ad-revenue event |

Firebase may also collect its documented automatic app/session/device events. SDK-generated revenue events use `Analytics.logTransaction` only after StoreKit verification. No separate custom `purchase` revenue event is emitted. Custom purchase_success is a funnel signal, not another revenue report. Verified transactions arriving from an actual purchase or Transaction.updates are recorded; enumeration of current/restored entitlements does not log revenue. The last 500 transaction IDs are kept locally to prevent repeat logging through both purchase-result and transaction-update paths, including across process restarts. Payment details and Apple account information are never passed to custom analytics.

Some controls open a tracked screen rather than producing a separate click event. This is intentional: no generic automatic tap/keystroke/scroll capture is installed.

## UI responsiveness

- App initialization enqueues Firebase configuration on a dedicated serial utility queue.
- The app's UI/event handlers enqueue lightweight constant metadata and return; they do not await Firebase or network uploads.
- Configuration, SDK calls, payload filtering, and purchase deduplication persistence happen on that queue.
- Firebase handles its own event batching, persistence and upload. No custom polling, per-event URLSession request, synchronous dispatch or retry loop is added.
- There are no tracking calls on animation frames, scrolling, message typing, render frames, or auto-save updates.
- Simulator observation: configuration ran off-main in approximately 62 ms. This is one observed initialization timing, not a guarantee for every device or network. Actual image rendering remains the existing export work.

## Data controls

Settings > Usage analytics controls collection (default on for this integration). Turning it off sets analytics-storage consent to denied and disables collection; queued SDK calls are gated by the serial preference state. The ads-storage, ads-user-data and ad-personalization consents remain denied for Firebase Analytics even when usage analytics is on.

Allowed parameter keys are centralized in AnalyticsPayload. Unknown keys, binary/media data, unsupported object types and nonfinite numbers are dropped; strings are bounded to 100 characters. Instrumentation supplies only predefined IDs/options, counts, durations and outcome categories. There is no user ID, message text, story title, character name, email, photo, audio, video, export path or search query in custom events.

The SDK still uses its documented installation/app-instance and device data. Update hosted privacy disclosures and App Store Connect App Privacy answers for the actual analytics usage. The switch is not a substitute for any consent flow required for your distribution/region; configure the appropriate consent experience before production where required.

## Verification

- Debug build succeeded with Firebase linked; Release compilation checked.
- Bundled Firebase plist matches the app bundle ID. Analytics collection starts disabled in Info.plist, automatic screen reporting and IDFA collection are disabled.
- Simulator debug logs confirm off-main configuration, screen_view for stories/editor/preview/export, preview_reset, export_start/export_success, and ad load/presentation events.
- 15 standalone privacy/deduplication regression checks passed (unknown/private keys, binary data, length bounds, nonfinite values, duplicate transactions, process-restart reuse and bounded ledger).
- A real purchase was not made. Validate subscription purchase/cancellation/pending/restore using StoreKit sandbox and your configured products. Do not manufacture purchase_success events to test a production dashboard.
- Firebase Console / GA4 / DebugView receipt needs publisher account access and is not claimed as verified.

```sh
swiftc -module-cache-path /tmp/chatcraft-swift-test-cache Core/Analytics/AnalyticsPolicy.swift Tests/Analytics/main.swift -o /tmp/chatcraft-analytics-tests
/tmp/chatcraft-analytics-tests
```

For development, add `-FIRDebugEnabled` to Xcode launch arguments and inspect Firebase Analytics > DebugView. Use `-FIRDebugDisabled` to stop Firebase debug mode on a previously enabled device. Debug-only app diagnostics log event/screen names, never the payload. Default event parameter build_mode distinguishes debug and release.

Official implementation references checked 14 October 2026:

- https://firebase.google.com/docs/analytics/get-started?platform=ios
- https://firebase.google.com/docs/analytics/screenviews
- https://firebase.google.com/docs/analytics/ios/measure-in-app-purchases
- https://firebase.google.com/docs/analytics/ios/configure-data-collection
- https://github.com/firebase/firebase-ios-sdk/blob/main/FirebaseAnalytics/README.md
