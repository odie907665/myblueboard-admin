import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase_options.dart';

/// Background message handler - must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Update badge count in background
  await NotificationService._updateBadgeCount();
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _badgeCountKey = 'new_ticket_count';
  static const String _deviceTokenKey = 'fcm_device_token';

  int _badgeCount = 0;
  String? _deviceToken;

  // Stream controller for new tickets
  final StreamController<Map<String, dynamic>> _newTicketController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onNewTicket => _newTicketController.stream;

  /// Initialize the notification service
  Future<void> initialize() async {
    try {
      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Request permissions
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Initialize local notifications
        await _initializeLocalNotifications();

        // Set up background handler
        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );

        // Get device token
        _deviceToken = await _firebaseMessaging.getToken();

        // Save token to preferences
        if (_deviceToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_deviceTokenKey, _deviceToken!);
        }

        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          _deviceToken = newToken;
          _saveDeviceToken(newToken);
        });

        // Load current badge count
        await _loadBadgeCount();

        // Set up message handlers
        _setupMessageHandlers();
      }
    } catch (e) {}
  }

  /// Initialize local notifications (for foreground notifications)
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    final DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    final DarwinInitializationSettings macOSSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    final initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: macOSSettings,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Set up message handlers for foreground and background
  void _setupMessageHandlers() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      // Update badge count
      await _incrementBadgeCount();

      // Show local notification
      await _showLocalNotification(message);

      // Notify listeners
      _newTicketController.add(message.data);
    });

    // When app is opened from notification (background/terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _newTicketController.add(message.data);
    });

    // Check for initial message (app opened from terminated state)
    _firebaseMessaging.getInitialMessage().then((message) {
      if (message != null) {
        _newTicketController.add(message.data);
      }
    });
  }

  /// Show local notification for foreground messages
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'support_tickets',
      'Support Tickets',
      channelDescription: 'Notifications for new support tickets',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const macOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: macOSDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'New Support Ticket',
      message.notification?.body ?? 'You have a new support ticket',
      notificationDetails,
      payload: message.data.toString(),
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Parse and emit the notification data
    if (response.payload != null) {
      // You can navigate to the ticket detail screen here
    }
  }

  /// Increment badge count for new ticket
  Future<void> _incrementBadgeCount() async {
    _badgeCount++;
    await _updateBadgeCount();
  }

  /// Update badge count
  static Future<void> _updateBadgeCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_badgeCountKey) ?? 0;

    // Update app badge
    if (await FlutterAppBadger.isAppBadgeSupported()) {
      if (count > 0) {
        FlutterAppBadger.updateBadgeCount(count);
      } else {
        FlutterAppBadger.removeBadge();
      }
    }
  }

  /// Load badge count from storage
  Future<void> _loadBadgeCount() async {
    final prefs = await SharedPreferences.getInstance();
    _badgeCount = prefs.getInt(_badgeCountKey) ?? 0;
    await _updateBadgeCount();
  }

  /// Save badge count to storage
  Future<void> _saveBadgeCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_badgeCountKey, _badgeCount);
    await _updateBadgeCount();
  }

  /// Clear badge when tickets are viewed/resolved
  Future<void> clearBadgeForTicket() async {
    if (_badgeCount > 0) {
      _badgeCount--;
      await _saveBadgeCount();
    }
  }

  /// Reset badge count (e.g., when all new tickets are handled)
  Future<void> resetBadgeCount() async {
    _badgeCount = 0;
    await _saveBadgeCount();
  }

  /// Set badge count explicitly (based on actual new ticket count from server)
  Future<void> setBadgeCount(int count) async {
    _badgeCount = count;
    await _saveBadgeCount();
  }

  /// Get current badge count
  int get badgeCount => _badgeCount;

  /// Get device token for registering with backend
  String? get deviceToken => _deviceToken;

  /// Save device token
  Future<void> _saveDeviceToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deviceTokenKey, token);
    // TODO: Send this token to your backend server
  }

  /// Dispose resources
  void dispose() {
    _newTicketController.close();
  }
}
