# Ciel Mobile

Flutter client for **Ciel Social** (iOS + Android). Layered architecture: `app/` (shell, DI, router, theme), `core/`, `domain/`, `data/`, `features/`, `ui/`.

## Prerequisites

- Flutter SDK (see `pubspec.yaml` `environment.sdk`)
- Ciel backend running locally or a reachable `API_BASE_URL`
- **iOS**: [CocoaPods](https://cocoapods.org/) (`brew install cocoapods` or `gem install cocoapods`). Native plugins (e.g. `flutter_secure_storage`) require installing pods after dependencies change.
- **Android**: Android Studio (or Android SDK + platform tools) + a configured emulator/device.

### iOS: CocoaPods workflow (read this before `pod install`)

The Podfile’s `post_install` hook calls Flutter tooling that expects the **iOS engine** to already be on disk. **Always run these from the app root** (`ciel_mobile/`), not only inside `ios/`:

```bash
flutter pub get
flutter precache --ios
cd ios && pod install
```

Then open **`ios/Runner.xcworkspace`** in Xcode, or run **`flutter run`** from the app root (recommended — it runs the right steps).

### iOS: `Flutter.xcframework must exist` (post-install hook failed)

That means the iOS engine cache is missing. From the app root:

```bash
flutter precache --ios
cd ios && pod install
```

If it still fails, repair the SDK cache: `flutter doctor -v`, then `flutter precache --ios` again.

### iOS: `Module 'flutter_secure_storage' not found`

1. Use the **CocoaPods workflow** above (including `flutter precache --ios`).
2. Open **`Runner.xcworkspace`**, not **`Runner.xcodeproj`**.
3. If needed: `cd ios && pod repo update && pod install`, then Xcode **Product → Clean Build Folder**.

The Runner **Profile** build uses `ios/Flutter/Profile.xcconfig`, which pulls in `Pods-Runner.profile.xcconfig`, so CocoaPods should not warn that the Profile base configuration is missing pod settings.

If the module error persists after Podfile changes, clean and reinstall pods (still run **`flutter precache --ios`** first):

```bash
flutter clean && flutter pub get && flutter precache --ios
cd ios && rm -rf Pods Podfile.lock build && pod install
cd .. && flutter run
```

Optional: clear Xcode Derived Data for this app if paths look stale (`~/Library/Developer/Xcode/DerivedData/Runner-*`).

### iOS: `flutter run` works but Xcode fails (e.g. `flutter_secure_storage` search path / module)

`flutter run` drives Xcode with a build order that usually finishes **Pods** before compiling **`GeneratedPluginRegistrant.m`**. Plain Xcode builds can compile **Runner** in parallel before the pod framework folder exists under **DerivedData**, which produces **“Search path …/flutter_secure_storage not found”**.

This repo sets **non-parallel scheme builds** (`Runner.xcscheme` + `BuildIndependentTargetsInParallel = NO`) and disables **explicit Swift modules** for pods (`SWIFT_ENABLE_EXPLICIT_MODULES = NO` in the Podfile `post_install`). After changing the Podfile, run **`pod install`** again.

Still failing?

1. Open **`ios/Runner.xcworkspace`** (never **`Runner.xcodeproj`** alone).
2. **Product → Clean Build Folder**, quit Xcode, delete the **`Runner-*`** folder under **Derived Data**, reopen the **workspace**, build again.
3. **Edit Scheme… → Build**: confirm **Find Implicit Dependencies** is enabled (Build Options in newer Xcode).

## Android

### Android: setup

- Install **Android Studio** and ensure the **Android SDK** is installed.
- Confirm toolchains are visible to Flutter:

```bash
flutter doctor -v
```

### Android: run

From the repo root:

```bash
flutter pub get
flutter run
```

### Android: build APK / App Bundle

```bash
flutter build apk
flutter build appbundle
```

### Android: local backend networking

- **Android emulator → host machine**: use `http://10.0.2.2:8080/v1`
- **Physical device → host machine**: use your machine’s LAN IP, e.g. `http://192.168.1.10:8080/v1`

Debug Android builds merge `usesCleartextTraffic=true` for HTTP local development.

### Android: release signing (public repo note)

This repo intentionally does **not** include any signing keys.

- Add your local `key.properties` and keystore under `android/` as needed.
- Keep them out of git (common patterns are already ignored by default Flutter `.gitignore`, but always verify before publishing).

## API base URL

Defaults to `https://api.ciel-social.eu/v1` (see `lib/core/config/app_config.dart`). Override at compile time:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/v1
```

- **Android emulator**: use `http://10.0.2.2:8080/v1` to reach the host machine’s Docker API on port 8080.
- **iOS Simulator**: `http://127.0.0.1:8080/v1` is allowed for cleartext via `Info.plist` ATS exceptions for local dev.
- **Physical device**: use your machine’s LAN IP, e.g. `http://192.168.1.10:8080/v1`.

Debug Android builds merge `usesCleartextTraffic=true` for HTTP local development.

## Verify (analyze + import rules + tests)

[`tool/verify.sh`](tool/verify.sh) runs `dart analyze --fatal-infos` using [very_good_analysis](https://pub.dev/packages/very_good_analysis), then `import_lint`, then `flutter test`.

```bash
chmod +x tool/verify.sh
./tool/verify.sh
```

## Architecture notes

- **State / DI**: [Riverpod](https://pub.dev/packages/flutter_riverpod) for UI state and service wiring (`app/providers/dependency_providers.dart` composition root).
- **Navigation**: [go_router](https://pub.dev/packages/go_router) with auth redirect; main shell matches Swift tabs (Create opens `/create` overlay).
- **HTTP**: [Dio](https://pub.dev/packages/dio) with refresh-on-401 + single retry, aligned with Swift `APIClient`.

## Resources

- [Flutter app architecture](https://docs.flutter.dev/app-architecture)
- [Flutter documentation](https://docs.flutter.dev/)

## License

Licensed under the **GNU Affero General Public License v3.0** (AGPL-3.0-or-later). See [`LICENSE`](LICENSE).
