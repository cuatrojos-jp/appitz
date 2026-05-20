import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  void _onNotificationTap(NotificationResponse response) {
    print('📱 Notificación tocada: ${response.payload}');
    _handleNavigation(response.payload);
  }

  @pragma('vm:entry-point')
  static void onDidReceiveBackgroundNotificationResponse(
    NotificationResponse response,
  ) {
    print('📱 Notificación en segundo plano: ${response.payload}');
  }

  Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse:
          onDidReceiveBackgroundNotificationResponse,
    );

    await _requestPermissions();
    _setupFCMHandlers();
    _printToken();
  }

  Future<void> _requestPermissions() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<void> _printToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    print('📱 FCM Token: $token');
  }

  void _setupFCMHandlers() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 Notificación recibida');
      showLocalNotification(
        title: message.notification?.title ?? '',
        body: message.notification?.body ?? '',
        payload: message.data['route'],
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 Usuario tocó la notificación');
      _handleNavigation(message.data['route']);
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        print('🚀 App abierta desde notificación');
        _handleNavigation(message.data['route']);
      }
    });
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'appitz_channel',
          'Notificaciones Appitz',
          channelDescription: 'Notificaciones de la aplicación Appitz',
          importance: Importance.high,
          priority: Priority.high,
          channelShowBadge: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  void _handleNavigation(String? route) {
    print('📍 Navegar a: $route');
  }

  Future<String?> getFCMToken() async {
    return await FirebaseMessaging.instance.getToken();
  }

  Future<void> refreshToken() async {
    await FirebaseMessaging.instance.deleteToken();
    final newToken = await FirebaseMessaging.instance.getToken();
    print('🔄 Token refrescado: $newToken');
  }
}
