import 'package:firebase_messaging/firebase_messaging.dart';

class NotificacionHandler {
  static Future<void> initialize() async {
    // Cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _mostrarNotificacionLocal(message);
    });
    
    // Cuando la app está en segundo plano y se toca la notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _manejarNavegacion(message.data);
    });
    
    // Cuando la app se abre desde estado terminado
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _manejarNavegacion(message.data);
      }
    });
  }
  
  static void _mostrarNotificacionLocal(RemoteMessage message) {
    // Usar NotificationService().showLocalNotification()
    print('Notificación recibida: ${message.notification?.title}');
  }
  
  static void _manejarNavegacion(Map<String, dynamic> data) {
    final route = data['route'];
    if (route == '/mis-equipos') {
      // Navegar a pantalla de equipos del jugador
      print('Navegar a mis equipos');
    }
  }
}