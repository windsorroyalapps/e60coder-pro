# E60Coder Pro 🚗

**BMW E60 / N54-N55 Advanced OBD Coding, Live Gauges & AI Tuning Command Center**

Cross-platform Flutter app → native Android APK + iOS + Desktop.

## Features

- Bluetooth OBD-II (ELM327, OBDLink, Vgate, etc.)
- Real-time gauges: RPM, Boost, Speed, Coolant, Throttle, AFR
- AI Tuning suggestion profiles (Sport / Track / Eco)
- NCS-style coding shortcuts (seatbelt chime, DVD in motion, etc.)
- Demo mode when no hardware present
- Full Bluetooth + NFC permissions ready
- GitHub Actions auto-builds APK on every push

## Quick Start

```bash
flutter pub get
flutter run                    # debug on device / emulator
flutter build apk --release --split-per-abi
```

APKs appear in:
`build/app/outputs/flutter-apk/`

## Legal

This tool is for **educational and legitimate personal vehicle use only**.  
Use only on vehicles you own. Comply with all local laws.  
No unauthorized financial transactions, ATM interaction, or security bypass features are included or supported.

## Structure

```
lib/
  main.dart
  services/obd_service.dart
  screens/
    home_screen.dart
    connect_screen.dart
    gauges_screen.dart
    tune_screen.dart
    code_screen.dart
```

## GitHub Actions

Push to `main` → automatic APK + AAB artifacts uploaded.

---

Built by an Android + BMW hacking enthusiast.  
Ship it. Tune it. Drive it.
