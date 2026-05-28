// lib/services/estadisticas_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/estadistica_equipo_model.dart';

class EstadisticasService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Estadísticas en vivo desde la vista (temporada PROG o ACTI).
  /// Devuelve la lista plana ordenada por categoría y diferencia de goles.
  /// El agrupado por categoría se hace en pantalla con [agruparPorCategoria].
  Future<List<EstadisticaEquipoModel>> obtenerEstadisticasLive(
    String temporadaId,
  ) async {
    final response = await _supabase
        .from('vista_estadisticas_equipos')
        .select()
        .eq('temporada_id', temporadaId)
        .order('categoria_nombre', ascending: true)
        .order('diferencia_goles', ascending: false)
        .order('goles_favor', ascending: false);

    return response
        .map((json) => EstadisticaEquipoModel.fromJson(json))
        .toList();
  }

  /// Snapshot histórico desde estadisticas_historicas (temporada FINA o SUSP).
  /// Misma estructura de retorno que [obtenerEstadisticasLive].
  Future<List<EstadisticaEquipoModel>> obtenerEstadisticasHistoricas(
    String temporadaId,
  ) async {
    final response = await _supabase
        .from('estadisticas_historicas')
        .select()
        .eq('temporada_id', temporadaId)
        .order('categoria_nombre', ascending: true)
        .order('diferencia_goles', ascending: false)
        .order('goles_favor', ascending: false);

    return response
        .map((json) => EstadisticaEquipoModel.fromJson(json))
        .toList();
  }

  /// Guarda el snapshot de una temporada en estadisticas_historicas.
  /// Llama al RPC de Postgres que lee la vista y cierra la temporada.
  /// Usar antes de cambiar el estado a FINA.
  Future<void> cerrarTemporada({
    required String temporadaId,
    required String usuarioId,
  }) async {
    await _supabase.rpc(
      'cerrar_temporada',
      params: {'p_temporada_id': temporadaId, 'p_usuario_id': usuarioId},
    );
  }

  /// Agrupa una lista plana de estadísticas por nombre de categoría.
  /// Útil para renderizar secciones en la pantalla ACTI.
  /// Las entradas sin categoría (amistosos de estado PROG) quedan bajo
  /// la clave 'Sin categoría'.
  static Map<String, List<EstadisticaEquipoModel>> agruparPorCategoria(
    List<EstadisticaEquipoModel> estadisticas,
  ) {
    final Map<String, List<EstadisticaEquipoModel>> agrupado = {};

    for (final e in estadisticas) {
      final categoria = e.categoriaNombre ?? 'Sin categoría';
      agrupado.putIfAbsent(categoria, () => []).add(e);
    }

    return agrupado;
  }
}
