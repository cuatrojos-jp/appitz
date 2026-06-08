// lib/services/goleo_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/goleo_jugador_model.dart';

class GoleoService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Datos en vivo (desde la vista)
  Future<List<GoleoJugadorModel>> obtenerGoleoLive(String temporadaId) async {
    final response = await _supabase
        .from('vista_goleo_jugadores')
        .select()
        .eq('temporada_id', temporadaId)
        .order('goles', ascending: false);

    return (response as List)
        .map((e) => GoleoJugadorModel.fromJson(e))
        .toList();
  }

  // Datos históricos (desde la tabla de snapshots)
  Future<List<GoleoJugadorModel>> obtenerGoleoHistorico(
    String temporadaId,
  ) async {
    final response = await _supabase
        .from('estadisticas_historicas_goleo')
        .select()
        .eq('temporada_id', temporadaId)
        .order('goles', ascending: false);

    return (response as List)
        .map((e) => GoleoJugadorModel.fromJson(e))
        .toList();
  }
}
