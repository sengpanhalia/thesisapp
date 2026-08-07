import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  try {
    if (await AppBadgePlus.isSupported()) {
      AppBadgePlus.updateBadge(1);
    }
  } catch (_) {}
  if (kDebugMode) {
    print("Background message received: ${message.messageId}");
  }
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static int _badgeCount = 0;

  static Future<void> initialize() async {
    // 1. Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 2. Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Request permissions
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 4. Setup Local Notifications for Foreground Popups
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(),
    );

    await _localNotificationsPlugin.initialize(settings: initSettings);

    // 5. Subscribe to "news_alerts" topic for broadcast news notifications
    await _messaging.subscribeToTopic('news_alerts');

    // 6. Listen for incoming messages while app is in Foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _showForegroundNotification(notification.title, notification.body);
      }
    });

    // 7. Listen when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      removeBadge();
    });
  }

  /// Displays head-up notification banner when app is open
  static void _showForegroundNotification(String? title, String? body) {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      channelShowBadge: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    _localNotificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title ?? 'Notification',
      body: body ?? '',
      notificationDetails: platformDetails,
    );

    _badgeCount++;
    updateBadgeCount(_badgeCount);
  }

  /// Updates app icon launcher badge count on phone home screen
  static Future<void> updateBadgeCount(int count) async {
    try {
      _badgeCount = count;
      final isSupported = await AppBadgePlus.isSupported();
      if (isSupported) {
        await AppBadgePlus.updateBadge(count);
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Error updating badge: $e");
    }
  }

  /// Clears app icon launcher badge count
  static Future<void> removeBadge() async {
    try {
      _badgeCount = 0;
      final isSupported = await AppBadgePlus.isSupported();
      if (isSupported) {
        await AppBadgePlus.updateBadge(0);
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Error removing badge: $e");
    }
  }

  /// Get device token for target notifications (e.g. Order Completed)
  static Future<String?> getFcmToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      if (kDebugMode) {
        print("Error getting FCM Token: $e");
      }
      return null;
    }
  }
}
