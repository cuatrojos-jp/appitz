// lib/services/dispositivo_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class DispositivoService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Guardar token FCM del dispositivo
  Future<void> guardarToken(String usuarioId, String fcmToken) async {
  final existing = await _supabase
      .from('dispositivos')
      .select('id')
      .eq('fcm_token', fcmToken)
      .maybeSingle();

  if (existing != null) {
    await _supabase
        .from('dispositivos')
        .update({
          'usuario_id': usuarioId,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', existing['id']);
  } else {
    await _supabase.from('dispositivos').insert({
      'usuario_id': usuarioId,
      'fcm_token': fcmToken,
    });
  }
}

  Future<void> eliminarToken(String fcmToken) async {
    await _supabase.from('dispositivos').delete().eq('fcm_token', fcmToken);
  }

  /// Obtener tokens de un usuario
  Future<List<String>> obtenerTokens(String usuarioId) async {
    final response = await _supabase
        .from('dispositivos')
        .select('fcm_token')
        .eq('usuario_id', usuarioId);

    return response.map((r) => r['fcm_token'] as String).toList();
  }
}
