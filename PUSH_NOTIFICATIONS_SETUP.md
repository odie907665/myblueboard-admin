# Push Notifications Setup for Admin App

This document explains how to set up push notifications for the myblueboard admin app, including badge counts for new support tickets.

## Overview

The system now supports:
- ✅ Push notifications when new tickets are created
- ✅ Push notifications when existing tickets receive customer replies
- ✅ App badge showing count of tickets with 'new' status
- ✅ Badge persists until ticket status changes from 'new'
- ✅ Sound and vibration with notifications
- ✅ Support for iOS, Android, and macOS

## Flutter App Setup

### 1. Install Dependencies

Already added to `pubspec.yaml`:
```yaml
firebase_core: ^3.8.1
firebase_messaging: ^15.1.5
flutter_local_notifications: ^18.0.1
flutter_app_badger: ^1.5.0
```

Run:
```bash
cd myblueboard-admin
flutter pub get
```

### 2. Configure Firebase

#### Option A: Use FlutterFire CLI (Recommended)

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Login to Firebase
firebase login

# Configure your app
cd myblueboard-admin
flutterfire configure --project=myblueboard-f559b
```

This will automatically:
- Create/update `firebase_options.dart`
- Add necessary config files for each platform

#### Option B: Manual Configuration

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (myblueboard-f559b)
3. Add iOS, Android, and macOS apps
4. Download configuration files:
   - iOS: `GoogleService-Info.plist` → `ios/Runner/`
   - macOS: `GoogleService-Info.plist` → `macos/Runner/`
   - Android: `google-services.json` → `android/app/`
5. Update `lib/firebase_options.dart` with your project details

### 3. Platform-Specific Setup

#### iOS Setup

1. Add to `ios/Runner/AppDelegate.swift`:
```swift
import UIKit
import Flutter
import FirebaseCore
import FirebaseMessaging

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  override func application(_ application: UIApplication, 
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
  }
}
```

2. Enable Push Notifications in Xcode:
   - Open `ios/Runner.xcworkspace`
   - Select Runner target
   - Go to "Signing & Capabilities"
   - Click "+ Capability"
   - Add "Push Notifications"
   - Add "Background Modes" → Enable "Remote notifications"

3. Configure APNs in Firebase Console:
   - Go to Project Settings → Cloud Messaging → iOS
   - Upload your APNs authentication key or certificate

#### macOS Setup

1. Add to `macos/Runner/AppDelegate.swift`:
```swift
import Cocoa
import FlutterMacOS
import FirebaseCore
import FirebaseMessaging

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    FirebaseApp.configure()
    
    if #available(macOS 10.14, *) {
      UNUserNotificationCenter.current().delegate = self
    }
  }
  
  override func application(_ application: NSApplication, 
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
  }
}
```

2. Enable Push Notifications in Xcode:
   - Open `macos/Runner.xcworkspace`
   - Select Runner target
   - Go to "Signing & Capabilities"
   - Add "Push Notifications"

#### Android Setup

1. Add to `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'
```

2. Add to `android/build.gradle`:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.3.15'
    }
}
```

3. Update `android/app/src/main/AndroidManifest.xml`:
```xml
<manifest>
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    
    <application>
        <!-- Add this for notification icon -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@mipmap/ic_launcher" />
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_color"
            android:resource="@color/colorAccent" />
    </application>
</manifest>
```

## Backend Setup

### 1. Add Firebase Admin SDK

```bash
cd myblueboard
pip install firebase-admin
```

Add to `requirements.txt`:
```
firebase-admin==6.4.0
```

### 2. Configure Firebase Server Key

Get your Firebase Server Key:
1. Go to Firebase Console → Project Settings → Cloud Messaging
2. Copy the "Server key" under Cloud Messaging API (Legacy)

Add to `.env`:
```env
FCM_SERVER_KEY=your_firebase_server_key_here
```

Add to Django settings:
```python
# settings.py or settings_local.py
FCM_SERVER_KEY = os.environ.get('FCM_SERVER_KEY', '')
```

### 3. Run Migrations

```bash
cd myblueboard
python manage.py makemigrations admin_api
python manage.py migrate admin_api
```

This creates the `AdminDeviceToken` model.

## How It Works

### Registration Flow

1. **App Launch**: 
   - NotificationService initializes on app start
   - Requests notification permissions
   - Obtains FCM device token
   - Registers token with backend via `/api/admin/register-device/`

2. **Token Management**:
   - Device tokens stored in `AdminDeviceToken` model
   - Tokens linked to admin user accounts
   - Supports multiple devices per user
   - Auto-deactivates invalid tokens

### Notification Flow

1. **New Ticket Created**:
   - Email arrives via SES webhook
   - Ticket created with status='new'
   - `send_new_ticket_notification()` called
   - Push notification sent to all admin users
   - Badge count incremented

2. **Ticket Updated**:
   - Customer replies to ticket
   - Ticket status changed to 'open'
   - `send_ticket_update_notification()` called
   - Notification sent to assigned user or all admins

3. **Badge Updates**:
   - Badge shows count of tickets with status='new'
   - Updated when:
     - App fetches ticket list
     - New notification received
     - Ticket status changes

### Badge Clearing

Badge count decreases when:
- Ticket status changes from 'new' to anything else
- Admin marks ticket as viewed (automatically synced)
- Can be manually cleared via `NotificationProvider.resetBadge()`

## API Endpoints

### Register Device Token
```http
POST /api/admin/register-device/
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "device_token": "fcm_token_here",
  "platform": "ios|android|macos"
}
```

## Testing

### Test Push Notification

Use Firebase Console to send test notification:
1. Go to Cloud Messaging → Send test message
2. Add your FCM token
3. Send notification

### Test Badge Count

1. Create a new ticket via email
2. Check that badge appears on app icon
3. Open ticket and change status to 'open'
4. Verify badge decreases

## Troubleshooting

### No Notifications Received

1. Check device token is registered:
   ```bash
   python manage.py shell
   from admin_api.models import AdminDeviceToken
   AdminDeviceToken.objects.filter(user__email='your_email@example.com')
   ```

2. Verify FCM_SERVER_KEY is set in backend

3. Check Firebase Console → Cloud Messaging for errors

4. Ensure platform (iOS/macOS) has APNs configured

### Badge Not Updating

1. Verify badge permissions granted
2. Check `flutter_app_badger` is supported on device
3. Review logs for badge update errors
4. Manually sync: Pull to refresh on tickets screen

### iOS Notifications Not Working

1. Ensure APNs certificate/key uploaded to Firebase
2. Check device has notification permissions
3. Verify app is code signed with proper provisioning profile
4. Test on physical device (simulator may not work)

## Security Considerations

1. **Token Storage**: Device tokens stored securely in database
2. **Authentication**: All API endpoints require JWT authentication
3. **Authorization**: Only admin/staff users can register devices
4. **Token Validation**: Invalid tokens auto-deactivated
5. **Rate Limiting**: Consider adding rate limits to prevent abuse

## Future Enhancements

- [ ] Custom notification sounds
- [ ] Rich notifications with images
- [ ] Interactive notification actions
- [ ] Notification preferences per user
- [ ] Silent notifications for badge updates only
- [ ] Analytics on notification delivery
- [ ] Support for notification channels (Android)
- [ ] Scheduled/delayed notifications
