   # Recipe Tadka

Modern recipe discovery experience with guest browsing, VIP unlocks, and AI-enhanced visuals.

## Gemini image generation

Some upstream recipe feeds do not ship images. We fill the gaps using Google Gemini’s free image endpoint.

1. Create a Gemini API key (https://aistudio.google.com/app/apikey).
2. Pass it to Flutter via `--dart-define`:
   ```bash
   flutter run --dart-define=GEMINI_API_KEY=your_key_here
   ```
   or add it to your IDE run configuration.
3. When no image is provided, the app will request a photorealistic dish photo from Gemini. If the key is missing, a curated placeholder image is shown instead.

## Development

- `flutter pub get`
- `flutter run`

VIP flows require Firebase auth. Configure Firebase (Android/iOS/Web) via `flutterfire configure` before running on devices.