import 'package:supabase_flutter/supabase_flutter.dart';

class BandejaService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtener notificaciones del usuario
  Future<List<Map<String, dynamic>>> obtenerNotificaciones(
    String usuarioId,
  ) async {
    final response = await _supabase
        .from('notificaciones')
        .select('*')
        .eq('usuario_id', usuarioId)
        .order('creado_en', ascending: false);

    return response;
  }

  /// Contar no leídas
  Future<int> contarNoLeidas(String usuarioId) async {
    try {
      final response = await _supabase
          .from('notificaciones')
          .select('id')
          .eq('usuario_id', usuarioId)
          .eq('leida', false);

      return response.length;
    } catch (e) {
      print('Error al contar no leídas: $e');
      return 0;
    }
  }

  /// Marcar como leída
  Future<void> marcarComoLeida(String notificacionId) async {
    await _supabase
        .from('notificaciones')
        .update({'leida': true, 'leida_en': DateTime.now().toIso8601String()})
        .eq('id', notificacionId);
  }

  /// Marcar todas como leídas
  Future<void> marcarTodasComoLeidas(String usuarioId) async {
    await _supabase
        .from('notificaciones')
        .update({'leida': true, 'leida_en': DateTime.now().toIso8601String()})
        .eq('usuario_id', usuarioId)
        .eq('leida', false);
  }

  /// Eliminar notificación
  Future<void> eliminarNotificacion(String notificacionId) async {
    await _supabase.from('notificaciones').delete().eq('id', notificacionId);
  }

  /// Eliminar todas las notificaciones del usuario
  Future<void> eliminarTodas(String usuarioId) async {
    await _supabase.from('notificaciones').delete().eq('usuario_id', usuarioId);
  }
}
