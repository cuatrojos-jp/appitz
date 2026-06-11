// lib/services/estadisticas_jugador_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/estadisticas_jugadores_model.dart';
import 'auth_service.dart';

class EstadisticasJugadorService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService;

  EstadisticasJugadorService({AuthService? authService})
    : _authService = authService ?? AuthService();

  /// Retorna las estadísticas del jugador vinculado al usuario en sesión,
  /// agrupadas por temporada (activa o programada).
  /// Retorna una lista vacía si el usuario no tiene jugador asociado.
  Future<List<EstadisticasJugadorModel>> getEstadisticasPropias() async {
    final usuarioId = await _authService.getUsuarioId();
    if (usuarioId == null) return [];

    // Primero obtenemos el jugador_id vinculado a este usuario
    final jugadorResponse = await _supabase
        .from('jugadores')
        .select('id')
        .eq('usuario_id', usuarioId)
        .maybeSingle();

    if (jugadorResponse == null) return [];

    final jugadorId = jugadorResponse['id'] as String;

    final response = await _supabase
        .from('estadisticas_jugadores')
        .select()
        .eq('jugador_id', jugadorId);

    return (response as List<dynamic>)
        .map(
          (row) =>
              EstadisticasJugadorModel.fromJson(row as Map<String, dynamic>),
        )
        .toList();
  }

  Future<EstadisticasJugadorModel?> getEstadisticasHistoricasPorTemporada(
    String temporadaId,
  ) async {
    final usuarioId = await _authService.getUsuarioId();
    if (usuarioId == null) return null;

    final jugadorResponse = await _supabase
        .from('jugadores')
        .select('id')
        .eq('usuario_id', usuarioId)
        .maybeSingle();

    if (jugadorResponse == null) return null;

    final jugadorId = jugadorResponse['id'] as String;

    final response = await _supabase
        .from('estadisticas_historicas_jugadores')
        .select()
        .eq('jugador_id', jugadorId)
        .eq('temporada_id', temporadaId)
        .maybeSingle();

    if (response == null) return null;

    return EstadisticasJugadorModel.fromJson(response);
  }

  Future<List<EstadisticasJugadorModel>> getEstadisticasPorJugador(
    String jugadorId,
  ) async {
    final response = await _supabase
        .from('estadisticas_jugadores')
        .select()
        .eq('jugador_id', jugadorId);

    return (response as List<dynamic>)
        .map(
          (row) =>
              EstadisticasJugadorModel.fromJson(row as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<EstadisticasJugadorModel>> getHistoricoPorJugador(
    String jugadorId, {
    int limite = 5,
  }) async {
    final temporadasResponse = await _supabase
        .from('temporadas')
        .select('id')
        .order('fecha_inicio', ascending: false)
        .limit(limite);

    final temporadaIds = (temporadasResponse as List)
        .map((t) => t['id'] as String)
        .toList();

    if (temporadaIds.isEmpty) return [];

    final response = await _supabase
        .from('estadisticas_historicas_jugadores')
        .select()
        .eq('jugador_id', jugadorId)
        .inFilter('temporada_id', temporadaIds)
        .order('cerrado_en', ascending: false);

    return (response as List)
        .map(
          (r) => EstadisticasJugadorModel.fromJson(r as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<EstadisticasJugadorModel>> getHistoricoPropio({
    int limite = 5,
  }) async {
    final usuarioId = await _authService.getUsuarioId();
    if (usuarioId == null) return [];

    final jugadorResponse = await _supabase
        .from('jugadores')
        .select('id')
        .eq('usuario_id', usuarioId)
        .maybeSingle();

    if (jugadorResponse == null) return [];

    final jugadorId = jugadorResponse['id'] as String;

    // Traemos los IDs de las últimas 5 temporadas (cualquier estado)
    final temporadasResponse = await _supabase
        .from('temporadas')
        .select('id')
        .order('fecha_inicio', ascending: false)
        .limit(limite);

    final temporadaIds = (temporadasResponse as List)
        .map((t) => t['id'] as String)
        .toList();

    if (temporadaIds.isEmpty) return [];

    final response = await _supabase
        .from('estadisticas_historicas_jugadores')
        .select()
        .eq('jugador_id', jugadorId)
        .inFilter('temporada_id', temporadaIds)
        .order('cerrado_en', ascending: false);

    return (response as List)
        .map(
          (r) => EstadisticasJugadorModel.fromJson(r as Map<String, dynamic>),
        )
        .toList();
  }
}
