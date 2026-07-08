# SGQR-style Deep Linking Simulation

Simulates SGQR/PayNow-style QR deep linking: one QR code that on Android goes
straight to the native app chooser, and on iOS lands on a web page for
picking a bank — and in both cases, the chosen bank app receives the payment
payload and prompts the user to pay, even if it's already open.

```
backend/       Node/Express server: payload store, QR generator,
               dashboard, and the iOS bank-picker page
bank_app_a/    Standalone Flutter app for Bank A
bank_app_b/    Standalone Flutter app for Bank B
bank_app_c/    Standalone Flutter app for Bank C
```

`bank_app_a/b/c` are 3 independent Flutter projects (each its own package
name, bundle ID, app name, color, and custom URL scheme), copied from one
shared source so their Dart code — deep-link handling, screens, API calls —
stays identical. This is what makes them install and run simultaneously as 3
distinct apps on both Android and iOS, which the picker page and Android
chooser both need to demo properly.

## How it works

The QR encodes a single link: `https://<host>/pay/:token`.

- **Android**: each bank app declares an *unverified* `BROWSABLE` intent-filter
  for the same host. Android only auto-opens a single app for a link when
  that app is verified as the sole owner — since none are verified here, the
  OS always shows its native disambiguation dialog (the "app drawer"),
  matching the "no default app chosen" assumption.
- **iOS**: Universal Links require a hosted `apple-app-site-association`
  file. This project deliberately doesn't serve one, so the link always falls
  through to Safari, landing on the bank-picker page. Tapping a bank there
  triggers that bank's custom URL scheme (e.g. `bankademo://pay?token=...`).
- **Payload delivery**: whichever bank app opens (via the Android chooser,
  the iOS picker page, or a raw custom-scheme link) reads `token` from the
  incoming URI and calls `GET /api/payload/:token` to fetch the full payment
  details, then shows a payment confirmation screen. This works on cold
  start, on warm start, and while the app is already open in the foreground
  (verified: sending a second deep link to an already-running app instance
  pushes a new confirm screen without restarting it).

## Real-world limitations (by design, for this simulation)

- Real Android App Link *verification* needs `.well-known/assetlinks.json`
  with the apps' real release-signing SHA-256 fingerprints, hosted on the
  same domain. We skip this on purpose — unverified links are what makes the
  chooser always appear.
- Real iOS Universal Links need `.well-known/apple-app-site-association`
  hosted over HTTPS and a paid Apple Developer Team ID baked into each app's
  entitlements. This project relies on the custom-scheme fallback instead,
  which is why iOS goes through the web picker page rather than opening an
  app directly.
- A phone's camera app needs a real HTTPS URL to scan (not `localhost`).
  Deploy the backend somewhere reachable (Render, Fly.io, a VPS) or tunnel it
  (`ngrok http 3000`) and set `BASE_URL` accordingly.

## Running the backend

```bash
cd backend
npm install
BASE_URL=http://localhost:3000 npm start   # or your ngrok/deployed URL
```

Open `http://localhost:3000` to create a demo payment and get a QR code.
Scanning it (or opening `/pay/:token` directly) shows the bank-picker page.

## Branding (logo + splash screen)

Each app has its own generated launcher icon and splash screen (a simple bank
pillar glyph + letter mark, in that bank's brand color: Bank A `#E63946`,
Bank B `#1D3557`, Bank C `#2A9D8F`). Source images live at
`bank_app_x/assets/branding/` (`icon.png`, `icon_foreground.png` for Android
adaptive icons, `splash.png`). They're wired up via `flutter_launcher_icons`
and `flutter_native_splash`, configured in each app's `pubspec.yaml`.

To regenerate after changing an asset:

```bash
cd bank_app_a   # or bank_app_b / bank_app_c
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Building the 3 Flutter bank apps

Each app is a normal, self-contained Flutter project — no flavors, no
`--dart-define=BANK=...` needed (each one already defaults to its own bank).
You only need `--dart-define=BACKEND_URL=...` if the default doesn't match
your setup:

- Default: `http://localhost:3000` — works for the iOS Simulator and any
  physical device where the backend is reachable at that host.
- Android **emulator**: override with `http://10.0.2.2:3000` (the emulator's
  alias for your host machine).

```bash
cd bank_app_a   # then bank_app_b, bank_app_c
flutter pub get
flutter run --dart-define=BACKEND_URL=http://10.0.2.2:3000   # Android emulator example
```

### Android

```bash
cd bank_app_a && flutter build apk --dart-define=BACKEND_URL=http://10.0.2.2:3000
cd ../bank_app_b && flutter build apk --dart-define=BACKEND_URL=http://10.0.2.2:3000
cd ../bank_app_c && flutter build apk --dart-define=BACKEND_URL=http://10.0.2.2:3000
```

Install all three on one emulator/device (`flutter install` from each
project, or `adb install` the APKs from `build/app/outputs/flutter-apk/`).
Each app (`com.sgqrdemo.bankaapp` / `.bankbapp` / `.bankcapp`) registers:

- Its own custom scheme (`bankademo://`, `bankbdemo://`, `bankcdemo://`)
- The same unverified `https://<deepLinkHost>/pay/*` intent-filter

Before testing the **real Android app-chooser** flow on a device, edit
`android/app/build.gradle.kts` in each app and set
`manifestPlaceholders["deepLinkHost"]` to your deployed backend's host (must
match the QR's URL), then rebuild.

### iOS

```bash
cd bank_app_a && flutter build ios --simulator
cd ../bank_app_b && flutter build ios --simulator
cd ../bank_app_c && flutter build ios --simulator
```

Each builds to its own bundle ID (`com.sgqrdemo.bankaapp` / `.bankbapp` /
`.bankcapp`) with its own display name and custom URL scheme, so all 3 can be
installed on the same Simulator or device at once. Install with:

```bash
xcrun simctl install booted bank_app_a/build/ios/iphonesimulator/Runner.app
xcrun simctl install booted bank_app_b/build/ios/iphonesimulator/Runner.app
xcrun simctl install booted bank_app_c/build/ios/iphonesimulator/Runner.app
```

(Building for a physical device instead of the simulator needs a Team ID set
in Xcode's Signing & Capabilities for each app.)

## End-to-end test

1. Start the backend, create a demo payment, note the QR/pay URL.
2. **Android**: install all 3 apps on an emulator. Open the pay URL
   (e.g. via `adb shell am start -a android.intent.action.VIEW -d "<payUrl>"`
   or by tapping the link from a messaging/notes app) — Android shows the
   chooser; picking a bank opens it straight to the confirm screen.
   With a bank app already running in the foreground, repeat the tap and
   confirm it navigates to the confirm screen without restarting the app.
3. **iOS**: open the pay URL in Safari — it loads the picker page showing the
   merchant/amount. Tap a bank button — it opens that bank app (if installed)
   straight to the confirm screen via its custom scheme. (Verified directly:
   `xcrun simctl openurl <device> "bankademo://pay?token=..."` correctly
   resolves to the Bank A app, `bankbdemo://` to Bank B, etc.)
4. Tap **Approve** in the bank app and confirm the success screen shows the
   correct merchant and amount.
