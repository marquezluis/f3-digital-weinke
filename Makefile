.PHONY: run build-apk

# Read compile-time config directly from the JSON. This is more robust than
# joining individual --dart-define flags: with the flag-joining approach the
# values failed to reach Dart's const evaluator (String.fromEnvironment came
# back empty), which silently disabled F3 auth/API and crashed token refresh.
DEFINES := --dart-define-from-file=dart-defines.json

run:
	flutter run $(DEFINES) -d $(or $(DEVICE),iphone)

build-apk:
	flutter build apk --release $(DEFINES)
