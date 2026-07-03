import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'data/providers/api_provider.dart';
import 'data/providers/storage_provider.dart';
import 'app/config/api_config.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class FirebaseService extends GetxService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif =
  FlutterLocalNotificationsPlugin();

  /// Saved FCM token — stored locally until user logs in
  String? _pendingToken;

  static Future<void> init() async {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  }

  @override
  void onInit() {
    super.onInit();
    _setup();
  }

  Future<void> _setup() async {
    await _setupLocalNotifications();
    await _requestPermission();
    _listenToMessages();
  }

  // ─────────────────────────────────────────────
  // Permission — runs on app start (before login)
  // ─────────────────────────────────────────────

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (kDebugMode) {
      print('🔔 Notification permission: ${settings.authorizationStatus}');
    }

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // Save token locally — don't send to server yet (user not logged in)
      final token = await _messaging.getToken();
      if (token != null) {
        _pendingToken = token;
        // Also save to secure storage for persistence
        try {
          final storage = Get.find<StorageProvider>();
          await storage.saveFcmToken(token);
        } catch (_) {}
        if (kDebugMode) print('🔔 FCM Token saved locally: ${token.substring(0, 20)}...');
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _pendingToken = newToken;
        try { Get.find<StorageProvider>().saveFcmToken(newToken); } catch (_) {}
        // Try to send if already logged in
        _trySendTokenToServer(newToken);
      });
    }
  }

  // ─────────────────────────────────────────────
  // Call this AFTER successful login
  // ─────────────────────────────────────────────

  /// Send the saved FCM token to the backend.
  /// Call this from AuthController after login succeeds.
  Future<void> sendSavedToken() async {
    // Try pending token first
    String? token = _pendingToken;

    // Fall back to stored token
    if (token == null) {
      try {
        final storage = Get.find<StorageProvider>();
        token = await storage.getFcmToken();
      } catch (_) {}
    }

    // Fall back to getting a new one
    token ??= await _messaging.getToken();

    if (token != null) {
      await _trySendTokenToServer(token);
    }
  }

  Future<void> _trySendTokenToServer(String token) async {
    try {
      final api = Get.find<ApiProvider>();
      await api.put(
        '${ApiConfig.apiPrefix}/users/fcm-token',
        body: {'fcm_token': token},
      );
      if (kDebugMode) print('🔔 Token sent to server ✓');
    } catch (e) {
      if (kDebugMode) print('🔔 Token send failed (not logged in?): $e');
    }
  }

  // ─────────────────────────────────────────────
  // Local Notifications
  // ─────────────────────────────────────────────

  Future<void> _setupLocalNotifications() async {
    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotif.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    const channel = AndroidNotificationChannel(
      'clinify_channel',
      'إشعارات Clinify',
      description: 'إشعارات المواعيد والرسائل',
      importance: Importance.high,
    );

    await _localNotif
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ─────────────────────────────────────────────
  // Listen to Messages
  // ─────────────────────────────────────────────

  void _listenToMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) print('🔔 Foreground message: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationNavigation(message.data);
    });

    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationNavigation(message.data);
      }
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotif.show(
      notification.hashCode,
      notification.title ?? 'Clinify',
      notification.body ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'clinify_channel',
          'إشعارات Clinify',
          icon: '@mipmap/ic_launcher',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        _handleNotificationNavigation(data);
      } catch (_) {}
    }
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    switch (type) {
      case 'APPOINTMENT_BOOKED':
      case 'APPOINTMENT_CONFIRMED':
      case 'APPOINTMENT_CANCELLED':
        break;
      case 'PRESCRIPTION_ADDED':
        final relatedId = data['related_id'] ?? '';
        if (relatedId.isNotEmpty) {
          Get.toNamed('/patient/prescriptions', arguments: relatedId);
        }
        break;
    }
  }
}