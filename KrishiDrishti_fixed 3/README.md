# Krishi Drishti — Xcode Project

**AI-powered crop disease detection app for Indian farmers.**  
Converted from Swift Playgrounds (.swiftpm) → full Xcode project.

See [PROJECT_DEPENDENCIES.md](/Users/priyanshukumarsingh/Desktop/KrishiDrishti_Xcode/PROJECT_DEPENDENCIES.md) for the exact frameworks, APIs, and dependency status used by the app.

---

## 📁 Project Structure

```
KrishiDrishti_Xcode/
├── KrishiDrishti.xcodeproj/          ← Open THIS in Xcode
│   └── xcshareddata/xcschemes/
│       └── KrishiDrishti.xcscheme
└── KrishiDrishti/
    ├── Info.plist                    ← Privacy keys & API keys go here
    ├── App/
    │   ├── KrishiDrishtiApp.swift
    │   └── AppTheme.swift
    ├── Models/
    │   ├── CropProblem.swift
    │   ├── WeatherModel.swift
    │   ├── UserProfile.swift
    │   └── TreatmentStep.swift
    ├── Services/
    │   ├── GeminiService.swift       ← Online: Gemini 1.5 Flash AI
    │   ├── SarvamTTSService.swift    ← Online: Hindi/Indian TTS
    │   ├── VisionAnalysisService.swift ← OFFLINE: Apple Vision
    │   ├── WeatherService.swift      ← Online + offline cache
    │   ├── NetworkMonitor.swift      ← NEW: Detects connectivity
    │   └── OfflineCacheService.swift ← NEW: Persistent cache
    ├── Utils/
    │   └── FuzzySearch.swift
    ├── ViewModels/
    │   ├── ScannerViewModel.swift
    │   └── KrishiBotViewModel.swift
    ├── Views/
    │   ├── Home/
    │   ├── Scanner/
    │   ├── Bot/
    │   ├── Profile/
    │   ├── Onboarding/
    │   └── Components/
    └── Resources/
        ├── Assets.xcassets
        └── Diseases.json
```

---

## 🚀 Opening in Xcode

1. **Unzip** the downloaded `KrishiDrishti_Xcode.zip`
2. **Double-click** `KrishiDrishti.xcodeproj` — Xcode opens automatically
3. Select your **Team** in: Target → Signing & Capabilities → Team
4. Choose a **Simulator** or plug in your **iPhone**
5. Press **⌘R** to build and run

---

## 🔑 Adding API Keys (Optional — app works offline without them)

Keys are injected through Xcode config files now, not stored directly in `Info.plist`.

Setup:

1. Copy `Config/Secrets.template.xcconfig` to `Config/Secrets.xcconfig`
2. Add your real keys in that file
3. `Secrets.xcconfig` is ignored by git

At build time, those values are passed into `Info.plist`.

| Key | Where to get it | What it enables |
|-----|----------------|-----------------|
| `GEMINI_API_KEY` | [aistudio.google.com](https://aistudio.google.com) → Get API Key | KrishiBot AI answers (free: 1500/day) |
| `SARVAM_API_KEY` | [sarvam.ai](https://sarvam.ai) → Sign up → API Keys | Natural Indian-language TTS voice |

**The app works 100% without these keys** — it falls back to the offline expert engine and AVSpeechSynthesizer.

---

## 🌐 Online vs Offline Features

| Feature | Online | Offline |
|---------|--------|---------|
| Crop disease scan | ✅ Apple Vision (always offline) | ✅ Same |
| KrishiBot answers | ✅ Gemini AI (smarter) | ✅ Built-in expert engine |
| Voice readout | ✅ Sarvam AI (Indian voice) | ✅ AVSpeechSynthesizer |
| Weather | ✅ Live from Open-Meteo | ✅ Cached (up to 24h) |
| Scan history | ✅ Saved to device | ✅ Persisted locally |
| Farmer profile | ✅ UserDefaults | ✅ UserDefaults |

---

## 🛠 Requirements

- **Xcode 15** or later
- **iOS 16.0** deployment target
- **Swift 5.9**
- No third-party dependencies — pure Apple frameworks only

---

## 📋 Frameworks Used

- `SwiftUI` — UI
- `Vision` — offline crop image classification
- `CoreLocation` — GPS for weather
- `AVFoundation` — text-to-speech (offline fallback)
- `Network` — connectivity monitoring (`NetworkMonitor`)
- `Foundation` — networking & caching

---

## 🏪 App Store Submission Checklist

- [ ] Set your **Team** in Signing & Capabilities
- [ ] Add a valid `GEMINI_API_KEY` in `Config/Secrets.xcconfig` if you want cloud KrishiBot answers
- [ ] Add a valid `SARVAM_API_KEY` in `Config/Secrets.xcconfig` if you want Sarvam cloud voice
- [ ] Add proper **App Icon** images to Assets.xcassets/AppIcon.appiconset
- [ ] Set **Bundle Identifier** to your own reverse-DNS ID
- [ ] Test on a real device (Vision framework performs better on device)
- [ ] Archive → Distribute App → App Store Connect

---

## ✅ Current Pages In The App

- Onboarding
- Home dashboard
- Weather + advisory summary
- Offline/online readiness summary
- Photo-based crop scanning
- Diagnosis detail with treatment checklist
- Scan history
- KrishiBot chat
- Farmer profile + edit screen

---

## 🔌 Dependencies You Need

No CocoaPods, no SPM packages, and no third-party SDK imports are required.

The app uses Apple frameworks only:

- `SwiftUI`
- `PhotosUI`
- `Vision`
- `AVFoundation`
- `CoreLocation`
- `Network`
- `Foundation`

Optional external APIs:

- `Open-Meteo`
  Used for live weather. No API key required.
- `Google Gemini`
  Optional. Add `GEMINI_API_KEY` in `Config/Secrets.xcconfig`.
- `Sarvam AI`
  Optional. Add `SARVAM_API_KEY` in `Config/Secrets.xcconfig`.
