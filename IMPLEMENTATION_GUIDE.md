# MyReminder - Complete Flutter Reminder App

A modern reminder and to-do calendar app for Android and iOS with alarm notifications, lock screen widgets, and Firebase backend.

## 📋 Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Setup Instructions](#setup-instructions)
- [Firebase Configuration](#firebase-configuration)
- [Android Configuration](#android-configuration)
- [iOS Configuration](#ios-configuration)
- [Lock Screen Widgets](#lock-screen-widgets)
- [Notification System](#notification-system)
- [Database Schema](#database-schema)
- [Implementation Status](#implementation-status)

## ✨ Features

### Core Features
- ✅ **Horizontal Scrolling Calendar** - Smooth date navigation centered on today
- ✅ **Time-based Reminder Status**
  - 🔴 RED: Overdue (past time or previous days, not completed)
  - 🟢 GREEN: Completed
  - ⚪ NORMAL: Upcoming (not completed)
- ✅ **Rich Reminder Creation**
  - Title, description, date/time
  - Multiple image attachments (Firebase Storage)
  - Point-wise subtasks checklist
  - Early reminder options (5, 10, 30, 60 minutes before)
  - Custom alarm sounds
  - Snooze options
- ✅ **Alarm Notifications**
  - Exact alarm scheduling (Android)
  - Scheduled notifications with custom sounds (iOS)
  - Notification actions: Complete, Snooze, Open
  - Deep linking to reminder details
- ✅ **Lock Screen Widgets** (Android + iOS)
- ✅ **Firebase Integration**
  - Authentication (email/password)
  - Firestore database
  - Firebase Storage (images)

### Authentication
- Email/password login
- User registration
- Persistent authentication state

### UI/UX
- Material Design 3
- Dark mode support
- Clean, modern interface
- Smooth animations
- Haptic feedback (calendar selection)

## 🏗️ Architecture

### Clean Architecture (3 Layers)

```
lib/
├── core/                      # Shared utilities
│   ├── config/
│   │   ├── constants.dart     # App constants
│   │   ├── theme.dart         # Material theme
│   │   └── routes.dart        # GoRouter configuration
│   ├── services/
│   │   └── notification_service.dart  # Notification handling
│   └── utils/
│       └── date_utils.dart    # Date/time utilities
│
├── features/
│   ├── auth/                  # Authentication feature
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── screens/
│   │       └── widgets/
│   │
│   └── reminders/             # Reminders feature
│       ├── data/
│       ├── domain/
│       └── presentation/
│
└── main.dart                  # App entry point
```

### State Management
- **Riverpod** for state management
- Provider-based dependency injection
- Reactive UI updates

### Navigation
- **GoRouter** for declarative routing
- Deep linking support for notifications/widgets
- Type-safe navigation

## 🚀 Setup Instructions

### Prerequisites
- Flutter SDK ^3.5.4
- Dart SDK ^3.5.4
- Firebase account
- Android Studio / Xcode
- CocoaPods (for iOS)

### 1. Clone and Install Dependencies

```bash
cd myreminder
flutter pub get
```

### 2. Firebase Setup (Required)

See [Firebase Configuration](#firebase-configuration) section below.

### 3. Platform-Specific Setup

#### Android
See [Android Configuration](#android-configuration) section.

#### iOS
See [iOS Configuration](#ios-configuration) section.

### 4. Run the App

```bash
# Development
flutter run

# Release
flutter build apk  # Android
flutter build ios  # iOS
```

## 🔥 Firebase Configuration

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: `myreminder-app`
4. Follow setup wizard

### Step 2: Add Android App

1. In Firebase Console, click "Add app" → Android
2. Package name: `com.myre.myreminder`
3. Download `google-services.json`
4. Place in `android/app/google-services.json`

### Step 3: Add iOS App

1. In Firebase Console, click "Add app" → iOS
2. Bundle ID: `com.myre.myreminder`
3. Download `GoogleService-Info.plist`
4. Place in `ios/Runner/GoogleService-Info.plist`

### Step 4: Enable Firebase Services

#### Authentication
1. Go to Authentication → Sign-in method
2. Enable "Email/Password"

#### Firestore Database
1. Go to Firestore Database → Create database
2. Start in **production mode**
3. Choose location (closest to your users)

#### Storage
1. Go to Storage → Get started
2. Start in **production mode**

### Step 5: Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User documents
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Reminders subcollection
      match /reminders/{reminderId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

### Step 6: Storage Security Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Step 7: Create Firestore Indexes

```javascript
// Composite index for querying reminders by date
Collection: users/{userId}/reminders
Fields:
  - scheduledAt (Ascending)
  - isCompleted (Ascending)
```

Create this index in Firestore Console → Indexes → Composite

## 📱 Android Configuration

### 1. Update `android/build.gradle.kts`

Add Google services plugin:

```kotlin
plugins {
    id("com.android.application") version "8.1.0" apply false
    id("org.jetbrains.kotlin.android") version "1.9.0" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
}
```

### 2. Update `android/app/build.gradle.kts`

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // Add this
}

android {
    namespace = "com.myre.myreminder"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.myre.myreminder"
        minSdk = 23
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }
}

dependencies {
    implementation("com.google.firebase:firebase-bom:33.7.0")
    implementation("com.google.firebase:firebase-analytics")
}
```

### 3. Add Permissions in `android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>

    <application
        android:label="MyReminder"
        android:icon="@mipmap/ic_launcher">
        
        <!-- Notification receiver -->
        <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" android:exported="false"/>
        <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver" android:exported="false">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
            </intent-filter>
        </receiver>
    </application>
</manifest>
```

### 4. Add Alarm Sounds

Create `android/app/src/main/res/raw/` directory and add sound files:
- `default_sound.mp3`
- `bell_sound.mp3`
- `chime_sound.mp3`
- `radar_sound.mp3`

## 🍎 iOS Configuration

### 1. Update `ios/Runner/Info.plist`

```xml
<dict>
    <!-- Existing keys -->
    
    <!-- Notification permissions -->
    <key>UIBackgroundModes</key>
    <array>
        <string>remote-notification</string>
        <string>fetch</string>
    </array>
    
    <!-- Camera/Photo permissions -->
    <key>NSCameraUsageDescription</key>
    <string>We need camera access to attach photos to reminders</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>We need photo library access to attach images to reminders</string>
    
    <!-- Notification category -->
    <key>UIUserNotificationSettings</key>
    <dict>
        <key>UIUserNotificationTypesAllowed</key>
        <array>
            <string>Alert</string>
            <string>Sound</string>
            <string>Badge</string>
        </array>
    </dict>
</dict>
```

### 2. Add Custom Sounds

Place sound files in `ios/Runner/` :
- `default.aiff`
- `bell.aiff`
- `chime.aiff`
- `radar.aiff`

### 3. iOS Limitations & Best Practices

**⚠️ IMPORTANT: iOS Background Alarm Limitations**

iOS does NOT support true "ringing alarm after app kill" due to OS security restrictions. This is intentional by Apple.

**What iOS ALLOWS:**
- ✅ Scheduled local notifications (UNUserNotificationCenter)
- ✅ Custom notification sounds
- ✅ Notification actions (Complete, Snooze)
- ✅ Critical Alerts (requires special entitlement from Apple)
- ✅ Lock screen widgets

**What iOS DOES NOT ALLOW:**
- ❌ Persistent ringing alarm when app is killed
- ❌ Hardware button (power/volume) detection in background
- ❌ Forcing screen wake-up reliably
- ❌ Background process running indefinitely

**Best Practice Implementation:**
1. Use `UNUserNotificationCenter` for scheduled notifications
2. Request Critical Alerts entitlement (if needed for high-priority reminders)
3. Use custom sounds to make notifications more noticeable
4. Provide clear notification actions
5. Educate users about iOS limitations

**Critical Alerts Setup (Optional):**
1. Request entitlement from Apple: https://developer.apple.com/contact/request/notifications-critical-alerts-entitlement/
2. Add to `ios/Runner/Runner.entitlements`:
```xml
<key>com.apple.developer.usernotifications.critical-alerts</key>
<true/>
```

## 📱 Lock Screen Widgets

### Android Widget

#### 1. Create Widget Layout

Create `android/app/src/main/res/layout/reminder_widget.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:orientation="vertical"
    android:padding="16dp"
    android:background="@drawable/widget_background">

    <TextView
        android:id="@+id/widget_title"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="Next Reminder"
        android:textSize="14sp"
        android:textStyle="bold"/>

    <TextView
        android:id="@+id/widget_time"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="Today, 3:00 PM"
        android:textSize="12sp"
        android:layout_marginTop="4dp"/>

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        android:layout_marginTop="8dp">

        <Button
            android:id="@+id/widget_complete"
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:text="Complete"/>

        <Button
            android:id="@+id/widget_snooze"
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:text="Snooze"
            android:layout_marginStart="8dp"/>
    </LinearLayout>
</LinearLayout>
```

#### 2. Create Widget Provider

Create `android/app/src/main/kotlin/com/myre/myreminder/ReminderWidgetProvider.kt`:

```kotlin
package com.myre.myreminder

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

class ReminderWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.reminder_widget)
        
        // TODO: Fetch next reminder from Firestore
        views.setTextViewText(R.id.widget_title, "Next Reminder")
        views.setTextViewText(R.id.widget_time, "Today, 3:00 PM")
        
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
```

#### 3. Register Widget in AndroidManifest.xml

```xml
<receiver android:name=".ReminderWidgetProvider" android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE"/>
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/reminder_widget_info"/>
</receiver>
```

### iOS Widget (WidgetKit)

#### 1. Add Widget Extension

In Xcode:
1. File → New → Target → Widget Extension
2. Name: `ReminderWidget`
3. Include Configuration Intent: Yes

#### 2. Create Widget Code

Create `ios/ReminderWidget/ReminderWidget.swift`:

```swift
import WidgetKit
import SwiftUI

struct ReminderEntry: TimelineEntry {
    let date: Date
    let title: String
    let time: String
}

struct ReminderWidgetEntryView : View {
    var entry: ReminderEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Next Reminder")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(entry.title)
                .font(.headline)
            
            Text(entry.time)
                .font(.subheadline)
                .foregroundColor(.blue)
            
            HStack {
                Button(intent: CompleteReminderIntent()) {
                    Text("Complete")
                }
                .buttonStyle(.bordered)
                
                Button(intent: SnoozeReminderIntent()) {
                    Text("Snooze")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}

@main
struct ReminderWidget: Widget {
    let kind: String = "ReminderWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ReminderWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Next Reminder")
        .description("Shows your next upcoming reminder")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
```

#### 3. Setup App Groups (for data sharing)

In Xcode:
1. Select Runner target → Signing & Capabilities
2. Add capability: App Groups
3. Add group: `group.com.myre.myreminder`
4. Repeat for Widget Extension target

## 🔔 Notification System

### Scheduling Flow

1. **User creates reminder** → Save to Firestore
2. **Schedule notifications**:
   - Main notification at scheduled time
   - Early reminder notification (if set)
3. **Store notification IDs** in Firestore
4. **When notification fires**:
   - Show notification with actions
   - User can: Complete, Snooze, or Open app

### Notification Actions

#### Complete
- Updates Firestore: `isCompleted = true`
- Cancels all future notifications
- Shows confirmation

#### Snooze
- Cancels current notification
- Schedules new notification after snooze duration
- Updates Firestore with new notification ID

#### Open
- Opens app
- Navigates to reminder detail screen using deep link

### Deep Linking

Notification payload contains `reminderId`:
```dart
payload: reminderId
```

App handles navigation:
```dart
static void _onNotificationTapped(NotificationResponse response) {
  final reminderId = response.payload;
  // Navigate to /reminder/:reminderId
}
```

## 💾 Database Schema

### Firestore Structure

```
users/{uid}
├── uid: string
├── email: string
├── name: string
└── createdAt: timestamp

users/{uid}/reminders/{reminderId}
├── reminderId: string
├── title: string
├── description: string
├── scheduledAt: timestamp
├── timezone: string
├── isCompleted: bool
├── completedAt: timestamp | null
├── createdAt: timestamp
├── updatedAt: timestamp
├── priority: int (0=normal, 1=high)
├── colorTag: string | null
├── earlyReminderMinutes: int | null
├── alarmSound: string
├── snoozeDefaultMinutes: int
├── images: string[] (Firebase Storage URLs)
├── subtasks: {id, text, isDone}[]
├── notificationIds: int[]
└── platformMeta: map
```

### Firebase Storage Structure

```
users/{uid}/reminders/{reminderId}/
├── image_1.jpg
├── image_2.jpg
└── ...
```

## 📊 Implementation Status

### ✅ Completed
- [x] Project structure and dependencies
- [x] Theme and styling (light + dark mode)
- [x] Navigation with GoRouter
- [x] Date utilities with overdue logic
- [x] Domain entities (User, Reminder, Subtask)
- [x] Data models with Firestore serialization
- [x] Notification service (Android + iOS)
- [x] Authentication screens (Login, Register)
- [x] Home screen with horizontal calendar
- [x] Add/Edit reminder screen (UI)
- [x] Reminder detail screen (UI)

### 🔨 TODO: Implementation Needed

1. **Firebase Integration**
   - [ ] Connect Firebase Auth to login/register screens
   - [ ] Implement Firestore repositories
   - [ ] Implement Firebase Storage for images
   - [ ] Add authentication state management with Riverpod

2. **Reminder Functionality**
   - [ ] Fetch reminders from Firestore
   - [ ] Create/update/delete reminders
   - [ ] Schedule notifications on create/update
   - [ ] Handle notification actions (Complete, Snooze)
   - [ ] Implement subtask toggle
   - [ ] Image upload/download

3. **Lock Screen Widgets**
   - [ ] Complete Android widget implementation
   - [ ] Complete iOS WidgetKit implementation
   - [ ] Setup App Groups for iOS widget data sharing
   - [ ] Implement widget update on reminder changes

4. **Permissions**
   - [ ] Request notification permissions on first launch
   - [ ] Request exact alarm permission (Android 12+)
   - [ ] Request camera/photo permissions for images

5. **Testing**
   - [ ] Test overdue logic (RED status)
   - [ ] Test notification scheduling
   - [ ] Test deep linking from notifications
   - [ ] Test widget updates

## 🚀 Next Steps

1. **Setup Firebase** following the configuration guide above
2. **Implement Firebase services** (Auth, Firestore, Storage repositories)
3. **Connect UI to Firebase** using Riverpod providers
4. **Test notification scheduling** on physical devices
5. **Implement widgets** following platform-specific guides
6. **Add custom sounds** to assets
7. **Test on both Android and iOS**

## 📝 Notes

### Hardware Button Limitation
Both Android and iOS **restrict hardware button detection** (power, volume) in background for security reasons. This cannot be bypassed. Users must interact with notifications through the UI.

### iOS Background Alarm
iOS does NOT support persistent alarms when app is killed. This is by design. Use Critical Alerts entitlement if high-priority reminders are essential.

### Testing Notifications
Always test on **physical devices**, as simulators/emulators have limited notification support.

---

**Built with ❤️ using Flutter**
