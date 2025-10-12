Structural Stability Assessment Tool - Flutter Prototype
-------------------------------------------------------
This is a minimal prototype scaffold for the SIH problem "Structural Stability Assessment Tool for Collapsed Structures".
It includes:
- Flutter app skeleton (lib/main.dart)
- pubspec.yaml listing required packages
- A simple local JSON save representing offline capability
- Map interaction using flutter_map (OpenStreetMap)
- Image picker integration (for photo upload)

How to run:
1. Ensure Flutter SDK is installed and configured.
2. From the project root, run: `flutter pub get`
3. Then run: `flutter run` on an emulator or device.

Notes:
- Mapbox integration is left as a placeholder. Replace the map widget with Mapbox plugin if needed and add your token.
- Stability calculation is a placeholder function `estimateStabilityScore(...)` in `lib/main.dart`. Replace with your engineering logic or ML model.
- This prototype intentionally keeps platform-specific files out. It's a simple scaffold meant for rapid iteration.
