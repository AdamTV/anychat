# iOS Deployment Guide for AnyChat Translator

Since the production build for iOS requires macOS and Xcode, follow these steps on a Mac to deploy the app to the Apple App Store.

## 1. Environment Setup
Ensure you have the following installed:
- Flutter SDK (matching version 3.19.6)
- Xcode (Latest stable)
- CocoaPods (`sudo gem install cocoapods`)

## 2. Project Preparation
Clone the repository and run:
```bash
flutter pub get
cd ios
pod install
cd ..
```

## 3. Code Signing & Provisioning
1. Open `ios/Runner.xcworkspace` in Xcode.
2. Select the **Runner** project in the Project Navigator.
3. Under the **Signing & Capabilities** tab:
   - Select your Apple Developer Team.
   - Ensure the **Bundle Identifier** matches your App Store Connect record.
   - Enable "Automatically manage signing".

## 4. Production Build
Run the following command from the root of the project:
```bash
flutter build ipa --release
```
This will generate a `.ipa` file in `build/ios/ipa/`.

## 5. Upload to App Store Connect
1. Open **Transporter** (available on the Mac App Store).
2. Drag and drop the `app-release.ipa` file into Transporter.
3. Click **Deliver**.

## 5. Finalize in App Store Connect
1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com).
2. Select **My Apps** -> **AnyChat Translator**.
3. Under **TestFlight**, select the build you just uploaded.
4. Complete the app metadata, screenshots, and submit for review.
