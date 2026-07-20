.PHONY: run build-apk build-appbundle

# Read compile-time config directly from the JSON. This is more robust than
# joining individual --dart-define flags: with the flag-joining approach the
# values failed to reach Dart's const evaluator (String.fromEnvironment came
# back empty), which silently disabled F3 auth/API and crashed token refresh.
DEFINES := --dart-define-from-file=dart-defines.json

run:
	flutter run $(DEFINES) -d $(or $(DEVICE),iphone)

build-apk:
	flutter build apk --release $(DEFINES)

# Play Console requires an Android App Bundle (not a raw APK) for new
# listings — Play then serves each device a split APK (right ABI/density/
# language) instead of one universal file. Keep build-apk around for
# sideloading to test devices.
build-appbundle:
	flutter build appbundle --release $(DEFINES)
