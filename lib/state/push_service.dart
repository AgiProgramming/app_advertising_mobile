import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../services/api_services.dart';

/// Integrasi Firebase Cloud Messaging.
///
/// Alur: setelah login, token perangkat didaftarkan ke backend
/// (`POST /api/device-token`). Backend mengirim push saat slip terbit/dibayar.
/// Notifikasi yang masuk saat aplikasi terbuka ditampilkan lewat
/// flutter_local_notifications pada channel "payroll".
class PushService {
  PushService._();

  static final PushService instance = PushService._();

  static const _channelId = 'payroll';
  static const _channelName = 'Slip Gaji';
  static const _channelDescription = 'Pemberitahuan slip gaji terbit dan sudah dibayar';

  final _local = FlutterLocalNotificationsPlugin();

  bool _firebaseReady = false;
  bool _listenersAttached = false;
  String? _token;
  ApiServices? _services;

  Future<void> attach(ApiServices services) async {
    _services = services;

    if (kIsWeb) return;

    await _initFirebase();
    if (!_firebaseReady) return;

    await _registerToken();
    _attachListeners();
  }

  /// Dipanggil saat logout: hapus token dari backend agar tidak menerima push.
  Future<void> detach(ApiServices services) async {
    final token = _token;
    if (token == null) return;

    try {
      await services.removeDeviceToken(token);
    } catch (_) {
      // Abaikan: token bisa saja sudah tidak valid.
    }

    _token = null;
    _services = null;
  }

  Future<void> _initFirebase() async {
    if (_firebaseReady) return;

    try {
      await Firebase.initializeApp();

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit, iOS: DarwinInitializationSettings());
      await _local.initialize(settings: initSettings);

      await _local
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.high,
          ));

      await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _firebaseReady = true;
    } catch (error) {
      // Tanpa Firebase (mis. belum ada google-services.json) aplikasi tetap jalan.
      debugPrint('Firebase belum siap: $error');
    }
  }

  Future<void> _registerToken() async {
    try {
      // FCM v17 menandai getToken() deprecated; token ini yang dipakai backend.
      // ignore: deprecated_member_use
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      _token = token;
      await _services?.registerDeviceToken(token);
    } catch (error) {
      debugPrint('Gagal mendaftarkan token FCM: $error');
    }
  }

  void _attachListeners() {
    if (_listenersAttached) return;
    _listenersAttached = true;

    // ignore: deprecated_member_use
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      _token = token;
      try {
        await _services?.registerDeviceToken(token);
      } catch (_) {}
    });

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;

      _local.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    });
  }
}
