# Mobile build (Flutter → APK)

## Project layout

```text
android/
  app/build.gradle.kts     # namespace + applicationId com.tapcare.app
  gradle/wrapper/          # committed wrapper — CI needs it
lib/                       # all Dart source (see AGENTS.md)
pubspec.yaml
.github/workflows/build-apk.yml
```

- **applicationId / namespace:** `com.tapcare.app`
- **minSdk:** Flutter default (21+); set to 23+ if you enable newer APIs
- **versionName / versionCode:** come from `pubspec.yaml`
  (`version: 1.0.0+1` → versionName `1.0.0`, versionCode `1`)

## Bumping a release

1. Edit `pubspec.yaml`: `version: 1.0.1+2`
   (name+build → versionName + versionCode; Android requires versionCode
   to increase on every upload).
2. Commit and push — Actions rebuilds the APK automatically.

## Where the APK lands

- **CI:** Actions run → Artifacts → `tapcare-apk`
  (`build/app/outputs/flutter-apk/app-debug.apk` inside the zip).
- **Local:** `flutter build apk --debug` → same path.

## Release signing (later)

Debug APKs are signed with the debug key — fine for sideloading/testing.
For Play Store:

```sh
keytool -genkey -v -keystore ~/tapcare.keystore -keyalg RSA \
  -keysize 2048 -validity 10000 -alias tapcare
```

Then in `android/key.properties` (git-ignored):

```properties
storePassword=...
keyPassword=...
keyAlias=tapcare
storeFile=/path/to/tapcare.keystore
```

Wire `signingConfigs` in `android/app/build.gradle.kts`, add the keystore as
a GitHub Actions secret, and switch the workflow to
`flutter build apk --release`. Commit the keystore only if the repo is
private — otherwise store it as an Actions secret.

## Install on a phone

```sh
adb install app-debug.apk
```

Or copy the file to the phone and allow "install from unknown sources".

## Web build (preview only)

```sh
flutter build web
```

The Freebuff hosted preview runs `flutter run -d web-server`. The
**deliverable remains the Android APK** built by GitHub Actions.
