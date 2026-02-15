# Social Sign-In Setup Guide

This guide explains how to configure Google Sign-In and Apple Sign-In for the MyReminder app.

## 🔧 Firebase Console Configuration

### 1. Enable Authentication Providers

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (myreminder-93de0)
3. Navigate to **Authentication** → **Sign-in method**
4. Enable the following providers:
   - ✅ **Email/Password**
   - ✅ **Google**
   - ✅ **Apple**

---

## 🤖 Android Configuration (Google Sign-In)

### Step 1: Configure SHA-1 Fingerprint

1. Get your SHA-1 fingerprint:
   ```bash
   cd android
   ./gradlew signingReport
   ```
   
2. In Firebase Console → Project Settings → Your apps → Android app:
   - Add the SHA-1 fingerprint for debug and release

### Step 2: Download Updated google-services.json

1. In Firebase Console → Project Settings
2. Download the updated `google-services.json`
3. Place it in `android/app/google-services.json`

### Step 3: Update build.gradle.kts (if needed)

The dependencies are already configured. Just ensure minSdk is 21+:

```kotlin
// android/app/build.gradle.kts
android {
    defaultConfig {
        minSdk = 21  // Required for Google Sign-In
    }
}
```

---

## 🍎 iOS Configuration (Apple Sign-In)

### Step 1: Apple Developer Account Setup

1. Go to [Apple Developer Portal](https://developer.apple.com/)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Select **Identifiers** → Your App ID
4. Enable **Sign In with Apple** capability
5. Click **Configure** and set up the redirect URL

### Step 2: Firebase Console - Apple Provider

1. In Firebase Console → Authentication → Sign-in method → Apple
2. Add the following:
   - **Service ID**: Your Apple Service ID (e.g., `com.myre.myreminder.signin`)
   - **Apple Team ID**: Found in Apple Developer account
   - **Key ID**: From the key you created for Sign In with Apple
   - **Private Key**: Upload the .p8 file

### Step 3: Update Info.plist

Add to `ios/Runner/Info.plist`:

```xml
<!-- Add inside <dict> -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- Google Sign-In URL Scheme -->
            <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

### Step 4: Add Sign In with Apple Capability in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the Runner target
3. Go to **Signing & Capabilities**
4. Click **+ Capability**
5. Add **Sign In with Apple**

### Step 5: GoogleService-Info.plist

1. Download `GoogleService-Info.plist` from Firebase Console
2. Add it to `ios/Runner/` using Xcode (drag and drop, ensure "Copy if needed" is checked)

---

## 📱 Platform-Specific Behavior

The app automatically shows the appropriate sign-in options:

| Platform | Email/Password | Google Sign-In | Apple Sign-In |
|----------|----------------|----------------|---------------|
| Android  | ✅             | ✅             | ❌            |
| iOS      | ✅             | ✅             | ✅            |
| macOS    | ✅             | ❌             | ✅            |
| Windows  | ✅             | ❌             | ❌            |

---

## 🔐 Security Best Practices

1. **Never commit** `google-services.json` or `GoogleService-Info.plist` to public repos
2. Add them to `.gitignore` for public projects
3. Use environment-specific Firebase projects (dev, staging, prod)

---

## 🧪 Testing

### Test Google Sign-In (Android)
1. Run on Android emulator or device
2. Tap "Continue with Google"
3. Select a Google account
4. Verify successful login and navigation to home

### Test Apple Sign-In (iOS)
1. Run on iOS simulator or device (iOS 13+)
2. Tap "Continue with Apple"
3. Authenticate with Face ID/Touch ID
4. Verify successful login and navigation to home

---

## 🐛 Troubleshooting

### Google Sign-In Issues

**Error: PlatformException(sign_in_failed, ...)**
- Check SHA-1 fingerprint is added to Firebase
- Re-download `google-services.json`
- Clean and rebuild: `flutter clean && flutter pub get`

### Apple Sign-In Issues

**Error: AuthorizationError.canceled**
- User cancelled the sign-in flow (expected)

**Error: The operation couldn't be completed**
- Check Sign In with Apple capability is added in Xcode
- Verify Apple Developer account is properly configured
- Ensure the bundle ID matches

---

## ✅ Verification Checklist

- [ ] Firebase Authentication providers enabled
- [ ] SHA-1 fingerprint added (Android)
- [ ] google-services.json updated (Android)
- [ ] Sign In with Apple capability added (iOS)
- [ ] GoogleService-Info.plist added (iOS)
- [ ] Apple Sign-In configured in Firebase Console
- [ ] Test on Android device/emulator
- [ ] Test on iOS device/simulator

