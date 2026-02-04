# MyReminder App - Quick Start Guide

## 🚀 Get Started in 5 Minutes

This guide will help you get the app running quickly for development and testing.

## Prerequisites Checklist

- [ ] Flutter SDK installed (^3.5.4)
- [ ] Android Studio or Xcode installed
- [ ] Firebase account created
- [ ] Physical device for testing (recommended for notifications)

## Step-by-Step Setup

### 1. Install Dependencies (2 minutes)

```bash
cd "c:\Flutter Projects\myreminder"
flutter pub get
```

### 2. Firebase Setup (10 minutes)

#### Create Firebase Project
1. Visit: https://console.firebase.google.com/
2. Click "Create Project" → Name it `myreminder-app`
3. Disable Google Analytics (optional)
4. Wait for project creation

#### Add Android App
1. In Firebase Console, click "Add app" → Android icon
2. **Android package name**: `com.myre.myreminder`
3. Download `google-services.json`
4. Move to: `android/app/google-services.json`

#### Add iOS App
1. Click "Add app" → iOS icon
2. **iOS bundle ID**: `com.myre.myreminder`
3. Download `GoogleService-Info.plist`
4. Move to: `ios/Runner/GoogleService-Info.plist`

#### Enable Firebase Services
1. **Authentication**:
   - Go to: Authentication → Get started
   - Sign-in method → Enable "Email/Password"

2. **Firestore Database**:
   - Go to: Firestore Database → Create database
   - Start in **test mode** (for development)
   - Choose location: `us-central1` or closest

3. **Storage**:
   - Go to: Storage → Get started
   - Start in **test mode** (for development)

#### Deploy Security Rules
1. In Firebase Console → Firestore Database → Rules
2. Copy content from `firestore.rules` file
3. Click "Publish"

4. In Firebase Console → Storage → Rules
5. Copy content from `storage.rules` file
6. Click "Publish"

### 3. Android Configuration (5 minutes)

#### Update `android/build.gradle.kts`

Change the plugins section:

```kotlin
plugins {
    id("com.android.application") version "8.1.0" apply false
    id("org.jetbrains.kotlin.android") version "1.9.0" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
}
```

#### Update `android/app/build.gradle.kts`

Add to plugins:
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // ADD THIS LINE
}
```

Add to dependencies section:
```kotlin
dependencies {
    implementation("com.google.firebase:firebase-bom:33.7.0")
    implementation("com.google.firebase:firebase-analytics")
}
```

#### Update `android/app/src/main/AndroidManifest.xml`

Add permissions before `<application>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```

### 4. iOS Configuration (5 minutes)

#### Update `ios/Runner/Info.plist`

Add before closing `</dict>`:

```xml
<!-- Notification permissions -->
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>

<!-- Camera/Photo permissions -->
<key>NSCameraUsageDescription</key>
<string>We need camera access to attach photos to reminders</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access to attach images to reminders</string>
```

#### Install CocoaPods Dependencies

```bash
cd ios
pod install
cd ..
```

### 5. Run the App! (1 minute)

#### On Android:
```bash
flutter run
```

#### On iOS:
```bash
flutter run
```

Or use your IDE's run button.

## 🎉 You're Done!

The app should now launch. You'll see:
- **Login Screen** → Register a new account
- **Home Screen** → Horizontal calendar strip
- **Add Reminder** → Floating action button

## Testing Checklist

- [ ] Register a new account
- [ ] Login successfully
- [ ] See horizontal calendar on home screen
- [ ] Tap dates to select different days
- [ ] Tap "Add Reminder" button
- [ ] Fill reminder form
- [ ] Save reminder

## Common Issues & Solutions

### Issue: "google-services.json not found"
**Solution**: Make sure you downloaded and placed the file in `android/app/` directory

### Issue: "GoogleService-Info.plist not found"
**Solution**: Make sure you downloaded and placed the file in `ios/Runner/` directory

### Issue: Firebase error when running
**Solution**: 
1. Make sure Firebase services are enabled in console
2. Check that package name/bundle ID matches exactly
3. Try `flutter clean` then `flutter pub get`

### Issue: Notifications not working
**Solution**:
1. Test on **physical device** (emulators have limited support)
2. Grant notification permissions when prompted
3. For Android 12+, grant "Alarms & reminders" permission in Settings

### Issue: iOS build fails
**Solution**:
1. Make sure CocoaPods is installed: `sudo gem install cocoapods`
2. Run `pod install` in the `ios/` directory
3. Open `ios/Runner.xcworkspace` in Xcode and build from there

## Next Steps

### Implement Full Functionality

The current codebase has **UI scaffolding** complete. To make it fully functional:

1. **Implement Firebase Repositories**
   - Create `AuthRepository` for login/register
   - Create `ReminderRepository` for CRUD operations
   - Create `StorageRepository` for image uploads

2. **Add State Management**
   - Create Riverpod providers
   - Connect UI to Firebase data

3. **Enable Notifications**
   - Test notification scheduling on device
   - Implement notification action handlers

See `IMPLEMENTATION_GUIDE.md` for detailed instructions.

## Development Tips

### Hot Reload
Press `r` in terminal or use IDE's hot reload button to see changes instantly.

### Check Logs
- Android: `flutter logs` or Android Studio Logcat
- iOS: `flutter logs` or Xcode Console

### Debugging
- Add breakpoints in VS Code/Android Studio
- Use Flutter DevTools: `flutter run` then open provided URL

### Firebase Console
Keep Firebase Console open to:
- View Firestore data in real-time
- Check Authentication users
- Monitor Storage files
- Read error logs

## Resources

- **Flutter Docs**: https://docs.flutter.dev
- **Firebase Docs**: https://firebase.google.com/docs
- **Riverpod Docs**: https://riverpod.dev
- **GoRouter Docs**: https://pub.dev/packages/go_router

## Need Help?

Check the detailed guides in:
- `IMPLEMENTATION_GUIDE.md` - Complete feature implementation
- `README.md` - Project overview
- Firebase Console → Documentation

---

**Happy Coding! 🎊**
