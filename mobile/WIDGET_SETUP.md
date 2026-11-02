# Sure home screen widget: setup

The widget shows all your account balances in four sizes: small, medium,
large, and Lock Screen. It refreshes on its own about every 15 minutes, and the
↻ button refreshes it right away without opening the app. Tapping anywhere else
opens Sure.

You do this once on the Mac (macOS side). After that, rebuilding is one command.

## 1. Install Flutter and CocoaPods (one time)

1. Download the Flutter SDK for macOS (Apple Silicon) from
   docs.flutter.dev/get-started/install/macos, unzip it to `~/development/flutter`.
2. In Terminal:
   ```bash
   echo 'export PATH="$HOME/development/flutter/bin:$PATH"' >> ~/.zprofile
   source ~/.zprofile
   sudo gem install cocoapods
   flutter doctor
   ```
   `flutter doctor` should show Xcode and CocoaPods with green checks. If
   `sudo gem install cocoapods` fails, run `xcode-select --install` first.

## 2. Get the code

```bash
mkdir -p ~/Projects && cd ~/Projects
git clone https://github.com/we-promise/sure
```

Unzip `sure-widget.zip` and drag its `mobile` folder onto `~/Projects/sure`,
choosing **Merge** (or run `ditto ~/Downloads/sure-widget/mobile ~/Projects/sure/mobile`).
That adds the widget files and updates 7 existing app files. Then:

```bash
cd ~/Projects/sure/mobile
flutter pub get
open ios/Runner.xcworkspace
```

If `Runner.xcworkspace` doesn't exist yet, run `cd ios && pod install && cd ..`
and open it again.

## 3. Add the widget target in Xcode (one time)

The widget's code is in `ios/SureWidget-files/`. Xcode needs a target for it:

1. **File → New → Target… → iOS → Widget Extension → Next.**
2. Product Name: **`SureWidget`** (exactly). Uncheck **Include Live Activity**,
   **Include Control**, and **Include Configuration App Intent**. Click
   **Finish**, then **Activate** (or Don't Activate; either is fine).
3. Xcode created `ios/SureWidget/` with sample files. In Finder:
   - Delete every `.swift` file inside `ios/SureWidget/` (keep its
     `Assets.xcassets`).
   - Copy everything from `ios/SureWidget-files/` into `ios/SureWidget/`,
     replacing `Info.plist` if asked.

   Xcode picks up the new files automatically. In the left sidebar, the
   SureWidget folder should now list `SureAccountsWidget.swift`,
   `SureWidgetShared.swift`, and `RefreshAccountsIntent.swift`.
4. Back in Xcode, select the **SureWidget** target → **General** → set
   **Minimum Deployments** to **iOS 17.0** or newer.
   On the same tab, set **Bundle Identifier** to exactly
   **`com.google.ios.youtube.ShareExtension`**. The app itself is already set to
   `com.google.ios.youtube`. These reuse your old YouTube app ID slots, so the
   install needs no new app IDs. Sure still shows up as "Sure Finances" on your
   phone.
5. Select the **SureWidget** target → **Build Settings**, search for
   `Info.plist File`, and make sure it is `SureWidget/Info.plist`.
6. Select the **Runner** target → **Build Phases**. Drag **Embed Foundation
   Extensions** (or "Embed App Extensions") so it sits **above** the
   **Run Script** and **Thin Binary** phases. Flutter builds fail with a
   "Cycle inside Runner" error otherwise.
7. Quit Xcode (it saves the project).

You don't need to sign in or pick a team in Xcode; the build is unsigned and
SideStore/iloader sign it.

## 4. Build the IPA

```bash
cd ~/Projects/sure/mobile
bash ios/build_sideload_ipa.sh
```

It prints the path of `build/sideload/Sure-with-widget.ipa`.

## 5. Install

Install with **SideStore**: AirDrop the IPA to your phone, open it with
SideStore (LocalDevVPN on). SideStore is what created your YouTube IDs
(`com.google.ios.youtube.YP36K86R24` and `...YP36K86R24.ShareExtension`), so it
names the new install the same way and lands on those existing slots. If SideStore
still says 0 app IDs remaining, check the two bundle IDs from step 3.

It uses one of your 3 active-app slots. Don't install Sure inside LiveContainer,
or the widget won't appear.

## 6. Turn on auto refresh

1. In Sure on the web: **Settings → API Keys** → create a key with **Read**
   access.
2. In the iPhone app: **More → Home Screen Widget** → paste the key → **Test and
   save**.
3. Long-press the home screen → **+** → **Sure** → pick a size. Long-press the
   widget → **Edit Widget** to hide liabilities or net worth.

If you logged into the app with an API key instead of email/password, step 6 is
optional: the widget reuses that key.

## Troubleshooting

- **Widget says "Open Sure, then More → Home Screen Widget":** no API key yet;
  do step 6.
- **"Couldn't reach your Sure server" or a 📶 slash icon:** the widget is
  showing the last saved balances. It needs the server reachable, so check that
  Tailscale is on (it's off while LocalDevVPN is running).
- **The settings screen says it can't reach shared storage:** the App Group
  didn't survive signing. Reinstall with iloader (or a newer SideStore) and
  make sure you're installing the IPA from the build script, not a plain
  `flutter build` output.
