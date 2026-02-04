# MyReminder - Technical Architecture & Design Document

## 📐 System Architecture

### High-Level Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter Application                      │
├─────────────────────────────────────────────────────────────┤
│  Presentation Layer (UI)                                     │
│  ├── Screens (Login, Home, Add/Edit, Detail)               │
│  ├── Widgets (Calendar Strip, Reminder Cards)              │
│  └── Providers (Riverpod State Management)                 │
├─────────────────────────────────────────────────────────────┤
│  Domain Layer (Business Logic)                              │
│  ├── Entities (User, Reminder, Subtask)                    │
│  ├── Repositories (Abstract Interfaces)                     │
│  └── Use Cases (Business Rules)                            │
├─────────────────────────────────────────────────────────────┤
│  Data Layer (Infrastructure)                                │
│  ├── Models (Firestore Serialization)                      │
│  ├── Data Sources (Firebase APIs)                          │
│  └── Repositories (Implementation)                         │
├─────────────────────────────────────────────────────────────┤
│  Core Layer (Shared)                                        │
│  ├── Services (Notifications, DI)                          │
│  ├── Utils (Date, Validators)                              │
│  └── Config (Theme, Routes, Constants)                     │
└─────────────────────────────────────────────────────────────┘
                           ↕
┌─────────────────────────────────────────────────────────────┐
│                    External Services                         │
├─────────────────────────────────────────────────────────────┤
│  Firebase                                                    │
│  ├── Authentication (User Management)                       │
│  ├── Firestore (Database)                                  │
│  └── Storage (Images)                                       │
├─────────────────────────────────────────────────────────────┤
│  Platform APIs                                               │
│  ├── Local Notifications (iOS/Android)                     │
│  ├── Alarm Manager (Android)                               │
│  └── UNUserNotificationCenter (iOS)                        │
├─────────────────────────────────────────────────────────────┤
│  Lock Screen Widgets                                         │
│  ├── Android Widget (Home Screen Widget)                   │
│  └── iOS WidgetKit (Lock Screen Widget)                    │
└─────────────────────────────────────────────────────────────┘
```

## 🎯 Feature Breakdown

### 1. Authentication Flow

```
User Opens App
     ├─→ Check Auth State
     │    ├─→ Authenticated → Home Screen
     │    └─→ Not Authenticated → Login Screen
     │
Login Screen
     ├─→ Email/Password Input
     ├─→ Validate Credentials
     ├─→ Firebase Auth Sign In
     ├─→ Create/Fetch User Doc in Firestore
     └─→ Navigate to Home Screen
     
Register Screen
     ├─→ Name, Email, Password Input
     ├─→ Validate Input
     ├─→ Firebase Auth Create User
     ├─→ Create User Doc in Firestore
     └─→ Navigate to Home Screen
```

### 2. Reminder Creation Flow

```
User Taps "Add Reminder"
     ├─→ Show Add Reminder Screen
     ├─→ Fill Form Fields:
     │    ├─→ Title (required)
     │    ├─→ Description (optional)
     │    ├─→ Date & Time (picker)
     │    ├─→ Alarm Sound (dropdown)
     │    ├─→ Early Reminder (dropdown)
     │    ├─→ Subtasks (list)
     │    └─→ Images (gallery/camera)
     │
User Taps "Save"
     ├─→ Validate Input
     ├─→ Upload Images to Firebase Storage
     ├─→ Get Download URLs
     ├─→ Create Reminder Doc in Firestore
     ├─→ Schedule Notifications:
     │    ├─→ Main notification at scheduledAt
     │    └─→ Early notification (if set)
     ├─→ Store notification IDs in Firestore
     └─→ Navigate Back to Home Screen
```

### 3. Notification Scheduling Flow

```
Schedule Reminder Notification
     ├─→ Calculate Notification Time(s)
     │    ├─→ Main Time: scheduledAt
     │    └─→ Early Time: scheduledAt - earlyReminderMinutes
     │
     ├─→ Create Notification Details
     │    ├─→ Title: reminder.title
     │    ├─→ Body: reminder.description
     │    ├─→ Sound: reminder.alarmSound
     │    ├─→ Actions: [Complete, Snooze, Open]
     │    └─→ Payload: reminderId
     │
     ├─→ Platform-Specific Scheduling:
     │    ├─→ Android:
     │    │    ├─→ Use AlarmManager for exact timing
     │    │    ├─→ Full-screen intent for alarm style
     │    │    └─→ Custom notification actions
     │    │
     │    └─→ iOS:
     │         ├─→ Use UNUserNotificationCenter
     │         ├─→ Schedule with custom sound
     │         ├─→ Add notification category actions
     │         └─→ Critical alerts (if entitlement)
     │
     └─→ Return Notification IDs
```

### 4. Notification Action Handling

```
Notification Fires
     ├─→ User Sees Notification
     ├─→ User Chooses Action:
     │    │
     │    ├─→ "Complete"
     │    │    ├─→ Update Firestore: isCompleted = true
     │    │    ├─→ Set completedAt = now
     │    │    ├─→ Cancel all notifications for reminder
     │    │    └─→ Show success message
     │    │
     │    ├─→ "Snooze"
     │    │    ├─→ Show snooze options (10 min, 1 hr, custom)
     │    │    ├─→ Cancel current notification
     │    │    ├─→ Schedule new notification after snooze time
     │    │    ├─→ Update notification IDs in Firestore
     │    │    └─→ Show confirmation
     │    │
     │    └─→ "Open" / Tap
     │         ├─→ Deep link to app
     │         ├─→ Parse payload (reminderId)
     │         ├─→ Navigate to Reminder Detail Screen
     │         └─→ Show reminder details
```

### 5. Overdue Status Logic

```
Display Reminder in Timeline
     ├─→ Get Current Date/Time
     ├─→ Get Reminder scheduledAt
     ├─→ Get Reminder isCompleted
     │
     ├─→ Determine Status:
     │    │
     │    ├─→ If isCompleted == true
     │    │    └─→ Status = COMPLETED (GREEN)
     │    │
     │    ├─→ Else If scheduledAt < now
     │    │    └─→ Status = OVERDUE (RED)
     │    │         Examples:
     │    │         - Today 6:00 PM, scheduled 3:00 PM → RED
     │    │         - Today, scheduled yesterday → RED
     │    │
     │    └─→ Else (scheduledAt >= now)
     │         └─→ Status = UPCOMING (NORMAL)
     │
     └─→ Apply Color:
          ├─→ GREEN border + icon for completed
          ├─→ RED border + icon for overdue
          └─→ Default styling for upcoming
```

## 📱 Platform-Specific Implementation

### Android

#### Notification Strategy
```kotlin
// AndroidNotificationDetails
- Channel: "reminder_channel" (high importance)
- Sound: Custom sound from res/raw/
- Full-screen intent: true (for alarm-like behavior)
- Category: ALARM
- Priority: HIGH
- Actions: [Complete, Snooze]
- Auto-cancel: false (persistent until interaction)
```

#### Permissions Required
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```

#### Widget Flow
```
1. User adds widget to home screen
2. Widget broadcasts request for data
3. App queries Firestore for next reminder
4. Widget displays:
   - Reminder title
   - Scheduled time
   - [Complete] button
   - [Snooze] button
5. On button tap:
   - Complete: Update Firestore + cancel notification
   - Snooze: Schedule new notification
6. Widget auto-updates every 15 minutes
```

### iOS

#### Notification Strategy
```swift
// UNNotificationRequest
- Category: "reminder_category"
- Sound: UNNotificationSound.default / custom .aiff file
- Interruption Level: .critical (if entitlement granted)
- Actions: [Complete, Snooze]
- Thread ID: reminderId (for grouping)
```

#### Limitations & Workarounds
```
LIMITATION: No persistent alarm when app is killed
WORKAROUND:
1. Use Critical Alerts (requires entitlement)
2. Custom notification sounds (louder/longer)
3. Multiple repeat notifications
4. Educate users to keep app in background

LIMITATION: Cannot detect hardware buttons in background
WORKAROUND:
1. Provide clear notification actions
2. Use foreground notification handling
3. Accept OS restrictions (security feature)
```

#### Widget Flow (WidgetKit)
```swift
1. User adds widget to lock screen/home screen
2. Widget timeline provider queries data
3. Data fetched from App Group shared container
4. Widget displays:
   - Next reminder title
   - Scheduled time
   - [Complete] [Snooze] buttons (App Intents)
5. On button tap:
   - App Intent executes in background
   - Updates Firestore
   - Refreshes widget timeline
6. Widget auto-refreshes based on timeline policy
```

## 🗄️ Data Models

### User Entity
```dart
class UserEntity {
  final String uid;
  final String email;
  final String name;
  final DateTime createdAt;
}
```

### Reminder Entity
```dart
class ReminderEntity {
  final String reminderId;
  final String userId;
  final String title;
  final String? description;
  final DateTime scheduledAt;
  final String timezone;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int priority;
  final String? colorTag;
  final int? earlyReminderMinutes;
  final String alarmSound;
  final int snoozeDefaultMinutes;
  final List<String> images;
  final List<Subtask> subtasks;
  final List<int> notificationIds;
  final Map<String, dynamic>? platformMeta;
}
```

### Subtask
```dart
class Subtask {
  final String id;
  final String text;
  final bool isDone;
}
```

## 🎨 UI Components

### Home Screen Components
1. **AppBar**: Title + Search + Menu
2. **Calendar Strip**: Horizontal scrolling date selector
3. **Date Header**: Selected date + reminder count
4. **Timeline List**: Time-sorted reminders with status colors
5. **FAB**: Add reminder button

### Calendar Day Item
- Weekday (Mon, Tue, etc.)
- Day number (1, 2, 3, etc.)
- Selection state (highlighted pill)
- Today indicator (dot or border)
- Haptic feedback on tap

### Reminder Card
- Time (left side)
- Title (bold)
- Description (truncated)
- Status indicator (colored edge)
- Subtask progress (if any)
- Image thumbnails (if any)
- Tap to open detail

## 🔐 Security Rules

### Firestore Rules
```javascript
// Users can only access their own data
match /users/{userId} {
  allow read, write: if request.auth.uid == userId;
  
  match /reminders/{reminderId} {
    allow read, write: if request.auth.uid == userId;
  }
}
```

### Storage Rules
```javascript
// Users can only access their own images
match /users/{userId}/reminders/{reminderId}/{fileName} {
  allow read, write: if request.auth.uid == userId;
  allow create: if request.resource.size < 10 * 1024 * 1024; // 10MB max
}
```

## 🧪 Testing Strategy

### Unit Tests
- Date utility functions (isOverdue, isToday, etc.)
- Entity creation and copying
- Model serialization/deserialization

### Widget Tests
- Calendar strip renders correctly
- Reminder cards show correct status colors
- Forms validate input properly

### Integration Tests
- Login/register flow
- Create reminder end-to-end
- Notification scheduling
- Deep linking from notification

### Manual Testing Checklist
- [ ] Overdue logic (set reminder in past, check RED status)
- [ ] Notification fires at scheduled time
- [ ] Notification actions work (Complete, Snooze)
- [ ] Deep linking opens correct reminder
- [ ] Widget shows next reminder
- [ ] Widget actions work
- [ ] Images upload and display
- [ ] Subtasks toggle correctly

## 📊 Performance Considerations

### Firestore Queries
- Index on `scheduledAt` for date-range queries
- Limit queries to selected date range
- Use pagination for large lists

### Image Optimization
- Compress images before upload
- Use thumbnails for grid display
- Lazy load full-size images

### Widget Updates
- Avoid frequent updates (battery drain)
- Update only when data changes
- Use efficient timeline policies

### Notification Scheduling
- Batch schedule/cancel operations
- Store IDs to avoid duplicates
- Clean up old notifications

## 🚀 Future Enhancements

### Planned Features
- [ ] Recurring reminders (daily, weekly, monthly)
- [ ] Reminder categories/tags
- [ ] Search and filter
- [ ] Export reminders (CSV, iCal)
- [ ] Share reminders with others
- [ ] Voice input for quick add
- [ ] Location-based reminders
- [ ] Integration with calendar apps

### Platform Features
- [ ] Android: Wear OS complication
- [ ] iOS: Siri shortcuts
- [ ] iOS: Live Activities for active reminders
- [ ] Android: Quick settings tile

## 📈 Analytics & Monitoring

### Key Metrics
- Daily active users
- Reminders created per user
- Notification open rate
- Widget usage stats
- Crash-free sessions

### Error Tracking
- Firebase Crashlytics integration
- Log critical errors to Firestore
- Monitor notification delivery failures

---

## 📚 References

- [Flutter Documentation](https://docs.flutter.dev)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Android Notifications Guide](https://developer.android.com/develop/ui/views/notifications)
- [iOS UNUserNotificationCenter](https://developer.apple.com/documentation/usernotifications)
- [iOS WidgetKit](https://developer.apple.com/documentation/widgetkit)
- [Riverpod Documentation](https://riverpod.dev)
- [GoRouter Documentation](https://pub.dev/packages/go_router)

---

**Document Version**: 1.0  
**Last Updated**: January 26, 2026  
**Status**: Implementation Ready
