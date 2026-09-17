import 'dart:io' show Platform;

import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color, ValueNotifier;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:thesisapp/model/reservation.dart' show ReservationStatus;
import 'package:thesisapp/service/inventory_api.dart';
import 'package:thesisapp/service/student_session_store.dart';
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
  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);
  static int get badgeCount => unreadCountNotifier.value;

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
        AndroidInitializationSettings('ic_notification');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(),
    );

    await _localNotificationsPlugin.initialize(settings: initSettings);


    // last add 
    
    // Create High Importance Android Notification Channel for background heads-up alerts
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important push notifications.',
      importance: Importance.max,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 5. Subscribe to "news_alerts" topic for broadcast news notifications
    await _subscribeToTopicWithRetry('news_alerts');

    /*
     * 5b. Keep the server's delivery address up to date.
     *
     * Firebase rotates a registration token while the app is running, and the
     * old one stops working the moment it does. Registering only at sign-in
     * would therefore leave a student quietly unreachable until they next
     * signed out and in, which students do about once a semester.
     *
     * Registering is skipped when there is no student session — nobody is
     * signed in, so there is nobody to register the handset to, and
     * `devices.php` would answer 401. `registerWithServer()` is called again
     * by the sign-in screen once there is one.
     */
    _messaging.onTokenRefresh.listen((token) {
      registerWithServer(token: token);
    });

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

  static Future<void> _subscribeToTopicWithRetry(String topic) async {
    const maxAttempts = 3;
    const baseDelay = Duration(seconds: 2);

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        // Bounded, so a device without working Play services fails this attempt
        // instead of leaving the call pending forever.
        await _messaging
            .subscribeToTopic(topic)
            .timeout(const Duration(seconds: 5));
        if (kDebugMode) {
          print('Subscribed to topic: $topic');
        }
        return;
      } catch (e) {
        if (attempt == maxAttempts) {
          if (kDebugMode) {
            print('Topic subscription failed after $maxAttempts attempts: $e');
          }
          return;
        }
        await Future.delayed(baseDelay * attempt);
      }
    }
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
      icon: 'ic_notification',
      color: Color(0xFF1A237E), // USEA brand blue
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

  /// Updates app icon launcher badge count and in-app badge listeners
  static Future<void> updateBadgeCount(int count) async {
    try {
      _badgeCount = count;
      unreadCountNotifier.value = count;
      final isSupported = await AppBadgePlus.isSupported();
      if (isSupported) {
        await AppBadgePlus.updateBadge(count);
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Error updating badge: $e");
    }
  }

  /// Clears in-app badge count and app icon launcher badge count
  static Future<void> removeBadge() async {
    try {
      _badgeCount = 0;
      unreadCountNotifier.value = 0;
      final isSupported = await AppBadgePlus.isSupported();
      if (isSupported) {
        await AppBadgePlus.updateBadge(0);
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Error removing badge: $e");
    }
  }

  /// Clears only the OS launcher icon badge count on the device home screen
  static Future<void> removeLauncherBadge() async {
    try {
      final isSupported = await AppBadgePlus.isSupported();
      if (isSupported) {
        await AppBadgePlus.updateBadge(0);
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Error removing launcher badge: $e");
    }
  }

  /// Fetches unread notifications count from the server and updates listeners
  static Future<int> fetchUnreadCount({InventoryApi? api}) async {
    final session = await StudentSessionStore.readValid();
    if (session.isEmpty) {
      await updateBadgeCount(0);
      return 0;
    }

    try {
      final inventoryApi = api ?? InventoryApi();
      int count = 0;
      try {
        final inbox = await inventoryApi.notifications();
        count = inbox.unread;
      } catch (e) {
        if (kDebugMode) debugPrint("Error fetching notifications: $e");
      }

      try {
        final reservations = await inventoryApi.myReservations();
        final readyCount = reservations
            .where((r) => r.status == ReservationStatus.readyForPickup)
            .length;
        if (readyCount > count) {
          count = readyCount;
        }
      } catch (e) {
        if (kDebugMode) debugPrint("Error checking reservations status: $e");
      }

      await updateBadgeCount(count);
      return count;
    } catch (e) {
      if (kDebugMode) debugPrint("Could not update badge count: $e");
      return unreadCountNotifier.value;
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

  /// Tells the server where to deliver this student's notifications.
  ///
  /// -------------------------------------------------------------------------
  ///  Why this is the piece that was missing
  /// -------------------------------------------------------------------------
  ///
  /// Everything else here already worked. Firebase was initialised, the channel
  /// was created, a foreground banner was shown and the badge was counted — and
  /// [getFcmToken] had no callers anywhere in the app. So the receiving half was
  /// complete, the server had no endpoint to be told an address, and nothing
  /// could ever arrive. This is the call that closes it.
  ///
  /// Called after signing in, and again from [initialize] whenever Firebase
  /// rotates the token.
  ///
  /// Never throws. A student who has just signed in must not be shown an error
  /// about push registration, and must certainly not be stopped from getting
  /// into the app by one: the worst case is that they read their messages in
  /// the app instead of being nudged by the phone, which is where they were
  /// before any of this existed.
  static Future<void> registerWithServer({String? token, InventoryApi? api}) async {
    try {
      // No session means nobody is signed in, so there is nobody to register
      // this handset to and the endpoint would answer 401.
      if ((await StudentSessionStore.readValid()).trim().isEmpty) return;

      final address = (token ?? await getFcmToken() ?? '').trim();

      if (address.isEmpty) return;

      await (api ?? InventoryApi()).registerDevice(
        token: address,
        platform: _platform,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Could not register for notifications: $e');
    }
  }

  /// Stops notifications reaching this handset, on sign-out.
  ///
  /// Must run **before** the student session is cleared, because the endpoint
  /// is guarded by that session. Phones get shared and sold, and what must not
  /// happen is the next "your books are ready" landing on somebody else's lock
  /// screen naming this student's order.
  static Future<void> forgetWithServer({String? token, InventoryApi? api}) async {
    try {
      if ((await StudentSessionStore.readValid()).trim().isEmpty) return;

      final address = (token ?? await getFcmToken() ?? '').trim();

      if (address.isEmpty) return;

      await (api ?? InventoryApi()).forgetDevice(address);
    } catch (e) {
      if (kDebugMode) debugPrint('Could not unregister notifications: $e');
    }
  }

  /// What the server records the handset as, for reading the logs by.
  static String get _platform {
    if (kIsWeb) return 'web';

    return Platform.isIOS ? 'ios' : 'android';
  }
}
