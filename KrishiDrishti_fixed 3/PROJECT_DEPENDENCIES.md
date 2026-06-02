# Krishi Drishti Project Dependencies

This project currently uses Apple-native frameworks only. There is no CocoaPods, Carthage, or Swift Package Manager dependency required for the app to run.

## Apple Frameworks Used

- `SwiftUI`
  Used for the full app UI.
- `PhotosUI`
  Used for selecting crop images from the photo library.
- `Vision`
  Used for offline crop and image classification.
- `AVFoundation`
  Used for speech playback and offline voice guidance.
- `CoreLocation`
  Used for local weather lookup by current location.
- `Network`
  Used for online/offline connectivity detection.
- `Foundation`
  Used for persistence, networking, dates, JSON decoding, and caching.
- `Combine`
  Used by observable services and model updates.
- `UIKit`
  Used only where `UIImage` interop is needed for Vision/photo workflows.

## External APIs

- `Open-Meteo`
  Purpose: live weather
  API key required: No
  Current integration: already in project

- `Google Gemini`
  Purpose: optional cloud KrishiBot answers
  API key required: Yes
  Add key in: `Config/Secrets.xcconfig` as `GEMINI_API_KEY`
  Current integration: already in project

- `Sarvam AI`
  Purpose: optional cloud text-to-speech
  API key required: Yes
  Add key in: `Config/Secrets.xcconfig` as `SARVAM_API_KEY`
  Current integration: already in project

## Dependency Status

- Third-party package manager required: `No`
- Manual framework embedding required: `No`
- Apple framework imports already present in source files: `Yes`
- Optional API keys still needed for cloud features: `Yes`

## What You Still Need To Add

- A valid `GEMINI_API_KEY` in `Config/Secrets.xcconfig` if you want cloud AI responses
- A valid `SARVAM_API_KEY` in `Config/Secrets.xcconfig` if you want Sarvam cloud voice
- Your Apple Developer signing team
- Your final bundle identifier
- Final App Store icon set
