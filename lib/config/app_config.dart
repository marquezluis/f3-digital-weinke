// lib/config/app_config.dart
// App-level constants injected at build time via --dart-define.
// Never hardcode keys here — pass them at build time:
//   flutter run --dart-define=GEMINI_API_KEY=AIza...
const kGeminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
