.PHONY: run build-apk

DEFINES := $(shell python3 -c "import json; d=json.load(open('dart-defines.json')); print(' '.join(f'--dart-define={k}={v}' for k,v in d.items()))")

run:
	flutter run $(DEFINES) -d $(or $(DEVICE),iphone)

build-apk:
	flutter build apk --release $(DEFINES)
