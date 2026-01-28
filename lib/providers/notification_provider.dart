import 'package:flutter/foundation.dart';
import 'dart:io';
import '../services/notification_service.dart';
import '../services/ticket_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final TicketService _ticketService = TicketService();

  int _badgeCount = 0;
  bool _isInitialized = false;

  int get badgeCount => _badgeCount;
  bool get isInitialized => _isInitialized;
  String? get deviceToken => _notificationService.deviceToken;

  NotificationProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _notificationService.initialize();
      _badgeCount = _notificationService.badgeCount;
      _isInitialized = true;
      notifyListeners();

      // Register device token with backend
      if (_notificationService.deviceToken != null) {
        await _registerDeviceToken(_notificationService.deviceToken!);
      }

      // Listen for new tickets
      _notificationService.onNewTicket.listen((data) {
        print('New ticket notification received: $data');
        _updateBadgeCount();
      });
    } catch (e) {
      print('Error initializing notification provider: $e');
    }
  }

  Future<void> _registerDeviceToken(String token) async {
    try {
      String platform = 'ios';
      if (Platform.isAndroid) {
        platform = 'android';
      } else if (Platform.isMacOS) {
        platform = 'macos';
      }

      await _ticketService.registerDeviceToken(token, platform);
      print('Device token registered with backend');
    } catch (e) {
      print('Error registering device token: $e');
    }
  }

  Future<void> _updateBadgeCount() async {
    _badgeCount = _notificationService.badgeCount;
    notifyListeners();
  }

  /// Call this when a ticket status changes from 'new'
  Future<void> markTicketAsViewed() async {
    await _notificationService.clearBadgeForTicket();
    await _updateBadgeCount();
  }

  /// Call this to reset badge count
  Future<void> resetBadge() async {
    await _notificationService.resetBadgeCount();
    await _updateBadgeCount();
  }

  /// Update badge count from server (e.g., after fetching tickets)
  Future<void> updateBadgeFromServer(int newTicketCount) async {
    await _notificationService.setBadgeCount(newTicketCount);
    await _updateBadgeCount();
  }

  @override
  void dispose() {
    _notificationService.dispose();
    super.dispose();
  }
}
