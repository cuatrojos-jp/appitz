import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../screens/partidos_list_screen.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dispositivo_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Contexto guardado para navegación
  BuildContext? _context;

  void setContext(BuildContext context) {
    _context = context;
  }

  void _onNotificationTap(NotificationResponse response) {
    _handleNavigation(response.payload);
  }

  @pragma('vm:entry-point')
  static void onDidReceiveBackgroundNotificationResponse(
    NotificationResponse response,
  ) {}

  Future<void> initialize() async {
    // Inicializar notificaciones locales (funciona en ambas plataformas)
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Solo Android: solicitar permisos y configurar FCM
    if (Platform.isAndroid) {
      await _requestPermissions();
      _setupFCMHandlers();
      _printToken();
    } else {
      print('📱 iOS: Notificaciones push deshabilitadas (sin APNS)');
    }
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
    // App en primer plano — mostrar notificación local
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showLocalNotification(
        title: message.notification?.title ?? '',
        body: message.notification?.body ?? '',
        payload: message.data['route'],
      );
    });

    // App en segundo plano — usuario tocó la notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNavigation(message.data['route']);
    });

    // App terminada — usuario tocó la notificación
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
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
    if (_context == null || route == null) return;
    final context = _context!;

    switch (route) {
      case '/partidos':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PartidosListScreen()),
        );
        break;
      // Agrega más rutas aquí a futuro
    }
  }

  // Future<String?> getFCMToken({int maxAttempts = 3}) async {
  //   if (Platform.isIOS) {
  //     print('📱 iOS: FCM token no solicitado (APNS no configurado)');
  //     return null;
  //   } else {
  //     // Android no tiene este problema
  //     return await FirebaseMessaging.instance.getToken();
  //   }
  // }

  Future<String?> getFCMToken({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (Platform.isIOS) {
      print('📱 iOS: FCM token no solicitado');
      return null;
    }
    try {
      return await FirebaseMessaging.instance.getToken().timeout(timeout);
    } catch (e) {
      print('⏰ Timeout o error al obtener FCM token: $e');
      return null;
    }
  }

  Future<void> refreshToken() async {
    await FirebaseMessaging.instance.deleteToken();
    final newToken = await FirebaseMessaging.instance.getToken();
    print('🔄 Token refrescado: $newToken');
  }

  Future<bool> getNotificacionesActivas() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notificaciones_activas') ?? true;
  }

  Future<void> desactivarNotificaciones(String usuarioId) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await DispositivoService().eliminarToken(token);
    }
    await FirebaseMessaging.instance.deleteToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificaciones_activas', false);
  }

  Future<void> activarNotificaciones(String usuarioId) async {
    // Regenerar token (deleteToken lo invalidó)
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await DispositivoService().guardarToken(usuarioId, token);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificaciones_activas', true);
  }
}
