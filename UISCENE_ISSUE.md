Title: iOS: adopt the UIScene lifecycle before building with the iOS 27 SDK

Apple requires the UIScene lifecycle for apps built with the iOS 27 SDK; apps that don't adopt it won't launch ([TN3187](https://developer.apple.com/documentation/technotes/tn3187-migrating-to-the-uikit-scene-based-life-cycle), [Apple forum answer](https://developer.apple.com/forums/thread/813300)). Sure's iOS app still uses the app-delegate lifecycle.

Today this doesn't affect releases, because `ios-testflight.yml` pins Xcode 26.4 (iOS 26 SDK). It will block moving to Xcode 27, and Apple doesn't guarantee iOS 26 SDK builds stay problem-free on future iOS versions.

What I've seen: a build made with Xcode 27 crashes immediately at launch on iOS 27.0.1 in `_UIApplicationEvaluateRuntimeIssueForNoSceneLifecycleAdoption` (EXC_BREAKPOINT).

What the migration involves (it fixed the crash in my build):

- Flutter 3.38+ (UIScene support); CI currently pins 3.32.4, and `pubspec.yaml` allows `>=3.27.0`.
- `Info.plist`: add `UIApplicationSceneManifest` with `FlutterSceneDelegate`.
- `AppDelegate`: conform to `FlutterImplicitEngineDelegate` and register plugins (and any method channels) in `didInitializeImplicitFlutterEngine` instead of `didFinishLaunchingWithOptions`.
- Check plugins that rely on app-delegate callbacks (e.g. `app_links` for SSO deep links) after the migration.

See Flutter's guide: https://docs.flutter.dev/release/breaking-changes/uiscenedelegate

Found while working on #[PR NUMBER] (iOS home screen widget). This was written with Claude Opus 5.5.
