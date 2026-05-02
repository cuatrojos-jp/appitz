import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/equipos_model.dart';

class EquipoService {
  final SupabaseClient _client = Supabase.instance.client;
  final String table = 'equipos';

  // 🔹 CREATE
  Future<void> crearEquipo(EquipoModel equipo) async {
    try {
      final data = await _client
          .from(table)
          .insert(equipo.toJsonSinId())
          .select()
          .single();

      print('✅ INSERT EQUIPO: $data');
    } catch (e) {
      print('🔥 Error al crear equipo, verifique todos los datos: $e');
      rethrow;
    }
  }

  // 🔹 READ todos
  Future<List<EquipoModel>> obtenerEquipos() async {
    final response = await _client.from(table).select();

    return (response as List)
        .map((json) => EquipoModel.fromJson(json))
        .toList();
  }

  // 🔹 READ por ID
  Future<EquipoModel?> obtenerEquipoPorId(String id) async {
    final response = await _client
        .from(table)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;

    return EquipoModel.fromJson(response);
  }

  // 🔹 UPDATE
  Future<void> actualizarEquipo(String id, EquipoModel equipo) async {
    await _client.from(table).update(equipo.toJsonSinId()).eq('id', id);
  }

  // 🔹 DELETE
  Future<void> eliminarEquipo(String id) async {
    await _client.from(table).delete().eq('id', id);
  }
}
