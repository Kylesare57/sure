## Add an iOS home screen widget for account balances

### Problem

There's no way to glance at balances on iOS without opening the app.

### What this adds

A WidgetKit extension (`SureWidget`) that lists account balances:

- Sizes: small, medium, large, and Lock Screen (accessory rectangular).
- Assets first, then liabilities, largest balances first. Medium and large show
  the server-computed net worth from `GET /api/v1/balance_sheet`.
- "Edit Widget" options to hide liabilities or net worth.
- Refreshes on its own (requested every 15 minutes; iOS decides the actual
  cadence) and through a refresh button (interactive widget, iOS 17+), without
  opening the app.
- Account names and balances are marked `privacySensitive()`, so iOS redacts
  them on a locked device when the user has turned off widget access when
  locked (Settings → Face ID & Passcode → Lock Screen Widgets).
- Footer icons: offline when the server can't be reached, and a key icon when
  no API key is set (auto-refresh is off).

How it gets data:

- The Flutter app sends the server URL, custom proxy headers, the latest
  account list and net worth to the widget over a method channel
  (`am.sure.mobile/widget`). `AppDelegate` writes them as JSON into the shared
  App Group `group.am.sure.mobile`. Accounts loaded from the offline cache are
  shared too, but only fill an empty widget; they never replace newer data.
- To refresh without the app, the widget calls `GET /api/v1/accounts` and
  `GET /api/v1/balance_sheet` itself with an **API key**. It never uses the
  app's OAuth tokens, because refreshing those from the widget would rotate
  them out from under the app.
- The key is either the one the app is logged in with (API-key login mode), or
  a separate key, ideally read-only, saved under **More → Home Screen Widget**.
  That screen tests the key against `/api/v1/accounts` before saving it.
- Logging out removes the widget's key and clears the shared files. A shared
  generation number is bumped first, and the app's key changes and channel
  calls run in one ordered queue, so nothing written before logout can bring
  the old account's data back.
- App Transport Security: the extension uses `NSAllowsLocalNetworking` (not
  `NSAllowsArbitraryLoads`). On iOS 17+ that allows plain HTTP to IP
  addresses, `.local` names and unqualified hostnames; any other server needs
  HTTPS. The settings screen warns when the configured server needs HTTPS.
  (The app itself is unaffected: Dart's networking doesn't go through ATS.)

### Changes

- `mobile/ios/SureWidget/`: widget extension (SwiftUI/WidgetKit/AppIntents),
  its Info.plist and entitlements.
- `mobile/ios/Runner/`: App Group entitlement, `SureAppGroup` Info.plist key,
  method channel handler in `AppDelegate`.
- `mobile/ios/Runner.xcodeproj`: new `SureWidget` target (iOS 17.0+), embedded
  in Runner before Flutter's script phases.
- `mobile/lib/services/widget_bridge_service.dart`: new bridge.
- `mobile/lib/screens/widget_settings_screen.dart`: new screen, linked from More
  (iOS only).
- `accounts_provider.dart`: shares accounts and net worth with the widget.
  `auth_provider.dart`: clears widget data on logout. `api_config.dart`:
  exposes the API key used in API-key login mode.
- `.github/workflows/ios-testflight.yml`: signs the widget extension with its
  own profile (see below).

### Signing (needs maintainer setup)

`ios-testflight.yml` now signs the `SureWidget` target with its own bundle ID
and provisioning profile, includes that profile in `ExportOptions.plist`, and
applies the App Group to both targets. Only you can create the Apple-side
pieces, so before the next TestFlight build:

1. Register the App Group `group.am.sure.mobile` and enable it on the
   `am.sure.mobile` App ID.
2. Create the App ID `am.sure.mobile.SureWidget` with the same App Group.
3. Regenerate the app's App Store profile (so it includes the App Group), and
   create one for the widget.
4. Add secrets `IOS_WIDGET_PROVISIONING_PROFILE_BASE64` and
   `IOS_WIDGET_PROVISIONING_PROFILE_NAME`, and update
   `IOS_PROVISIONING_PROFILE_BASE64` with the regenerated app profile.
   Optional repo variables: `IOS_WIDGET_BUNDLE_ID` (default
   `<IOS_APP_BUNDLE_ID>.SureWidget`) and `IOS_APP_GROUP` (default
   `group.am.sure.mobile`).

Until the widget secrets exist, the workflow skips the upload with its
existing "missing credentials" summary rather than failing. I checked the
signing patch against a copy of the project (both targets end up with manual
signing, their own bundle IDs and profiles, and the App Group swapped), but I
can't run a signed build without your credentials.

### Out of scope: UIScene migration (iOS 27 SDK)

Apps built with the iOS 27 SDK (Xcode 27) won't launch unless they adopt the
UIScene lifecycle. This applies to Sure with or without the widget, and the
TestFlight workflow pins Xcode 26.4, so current builds aren't affected. I've
kept that migration out of this PR and opened a follow-up: [#ISSUE].

### Validation

- CI: Sure's `Flutter Mobile Build` workflow passes on this branch (`flutter
  analyze`, `flutter test`, Android release APK, and the unsigned iOS build,
  which compiles the widget extension): https://github.com/Kylesare57/sure/actions/runs/41772800689
- Device: tested on an iPhone running iOS 27.0.1 against a self-hosted Sure
  server with Plaid sandbox data (14 accounts, including loans and a
  mortgage), using a sideloaded build of the same widget code from my fork.
  That build differs only in bundle IDs/App Group (my signing setup) and the
  UIScene migration above.
  - Small, medium and large widgets render; net worth matches the app.
  - Refresh works on its own and with the button, over Wi-Fi and cellular; in
    airplane mode it keeps the last balances and shows the offline icon.
  - Logging out switches the widget to its setup message, and the old
    balances don't come back after refreshing.

### AI disclosure

The code and this description were written with Claude Opus 5.5 (Anthropic),
working through Claude Code, at my direction. I tested it on my device as
described above.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_019GAJgb6sseXpdGea77L4WY
