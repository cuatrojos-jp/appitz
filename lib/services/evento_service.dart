// lib/services/evento_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/evento_model.dart';

class EventoService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtener todos los eventos de un partido, ordenados por minuto
  Future<List<EventoModel>> obtenerEventosPorPartido(String partidoId) async {
    final response = await _supabase
        .from('eventos_partido')
        .select('''
          *,
          jugador:jugadores!eventos_partido_jugador_id_fkey(id, nombre),
          jugador_secundario:jugadores!eventos_partido_jugador_secundario_id_fkey(id, nombre),
          tipos_evento(id, codigo, afecta_marcador, requiere_jugador_secundario)
        ''')
        .eq('partido_id', partidoId)
        .order('minuto', ascending: true);

    return response.map((json) => EventoModel.fromJson(json)).toList();
  }

  /// Obtener jugadores de los dos equipos del partido
  Future<List<Map<String, dynamic>>> obtenerJugadoresDelPartido({
    required String equipoLocalId,
    required String equipoVisitanteId,
  }) async {
    final response = await _supabase
        .from('jugadores_equipos')
        .select('''
          equipo_id,
          jugadores!inner(id, nombre)
        ''')
        .inFilter('equipo_id', [equipoLocalId, equipoVisitanteId])
        .eq('activo', true);

    return response
        .map<Map<String, dynamic>>(
          (r) => {
            'id': r['jugadores']['id'] as String,
            'nombre': r['jugadores']['nombre'] as String,
            'equipo_id': r['equipo_id'] as String,
          },
        )
        .toList();
  }

  /// Obtener tipos de evento
  Future<List<Map<String, dynamic>>> obtenerTiposEvento() async {
    final response = await _supabase
        .from('tipos_evento')
        .select('*')
        .order('codigo', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Insertar múltiples eventos en bulk
  Future<void> registrarEventos(List<Map<String, dynamic>> eventos) async {
    if (eventos.isEmpty) return;
    await _supabase.from('eventos_partido').insert(eventos);
  }

  /// Eliminar todos los eventos de un partido (para re-registrar)
  Future<void> eliminarEventosDelPartido(String partidoId) async {
    await _supabase
        .from('eventos_partido')
        .delete()
        .eq('partido_id', partidoId);
  }
}
