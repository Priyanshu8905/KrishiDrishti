# Krishi Drishti Publish Checklist

## Project Identity

- App name: `Krishi Drishti`
- Bundle ID: `Com.KrishiDrishti`
- Team ID: `73B8W4ZN6V`
- Version: `1.0.0`
- Build: `1`

## Already Configured

- Bundle identifier is set in the Xcode target
- Development team is set in the Xcode target
- Signing style is `Automatic`
- Gemini key is injected from `Config/Secrets.xcconfig`
- Sarvam key is injected from `Config/Secrets.xcconfig`
- App icon asset catalog exists
- Offline fallback paths exist for scan, bot, voice, and cached weather

## Still To Verify In Xcode

- Open Signing & Capabilities and confirm the correct Apple account is selected
- Confirm the explicit App ID `Com.KrishiDrishti` matches the one shown in Apple Developer
- Build once on a real iPhone
- Archive once in Xcode Organizer
- Validate the archive before upload

## App Store Connect To-Do

- Create the app in App Store Connect using `Com.KrishiDrishti`
- Add app subtitle, description, keywords, support URL, and privacy policy URL
- Upload screenshots for iPhone
- Choose category and age rating
- Fill App Privacy answers
- Fill export compliance if prompted

## Assets

- Current app icon set includes a 1024x1024 iOS universal icon and dark/tinted variants
- Verify the icon is the final production brand asset before submission

## Release Recommendation

- Keep `Config/Secrets.xcconfig` private
- Do not commit real API keys
- Keep `Config/Secrets.template.xcconfig` as the shareable setup file
