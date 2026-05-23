// lib/services/jugador_equipo_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/equipos_model.dart';

class JugadorEquipoService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtiene los equipos actualmente asignados a un jugador (activos)
  Future<List<EquipoModel>> obtenerEquiposPorJugador(String jugadorId) async {
    final response = await _supabase
        .from('jugadores_equipos')
        .select('equipo_id, equipos(*)')
        .eq('jugador_id', jugadorId)
        .eq('activo', true);

    return response.map((row) => EquipoModel.fromJson(row['equipos'])).toList();
  }

  /// Reemplaza todas las asignaciones de equipos para un jugador.
  /// Elimina las asignaciones activas actuales y crea las nuevas.
  Future<void> asignarEquiposAJugador(
    String jugadorId,
    List<String> nuevosEquipoIds,
  ) async {
    // 1. Eliminar asignaciones activas existentes (borrado físico)
    await _supabase
        .from('jugadores_equipos')
        .delete()
        .eq('jugador_id', jugadorId)
        .eq('activo', true);

    // 2. Insertar nuevas asignaciones
    if (nuevosEquipoIds.isNotEmpty) {
      final ahora = DateTime.now().toIso8601String();
      final asignaciones = nuevosEquipoIds
          .map(
            (equipoId) => {
              'jugador_id': jugadorId,
              'equipo_id': equipoId,
              'fecha_inicio': ahora,
              'activo': true,
            },
          )
          .toList();

      await _supabase.from('jugadores_equipos').insert(asignaciones);
    }
  }
}
