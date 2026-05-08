import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/equipos_model.dart';

class EquipoService {
  final SupabaseClient _client = Supabase.instance.client;
  final String table = 'equipos';

  // 🔹 CREATE
  Future<EquipoModel> crearEquipo(EquipoModel equipo) async {
    final response = await _client
        .from('equipos')
        .insert(equipo.toJson())
        .select()
        .single();
    return EquipoModel.fromJson(response);
  }

  // 🔹 READ todos
  Future<List<EquipoModel>> obtenerEquipos() async {
    try {
      final response = await _client.from('equipos').select();
      print('Equipos obtenidos: ${response.length}'); // ← Ver cuántos vienen
      print('Datos: $response'); // ← Ver los datos crudos

      return (response as List)
          .map((json) => EquipoModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error en obtenerEquipos: $e');
      return [];
    }
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
  Future<EquipoModel> actualizarEquipo(EquipoModel equipo) async {
    final response = await _client
        .from('equipos')
        .update(equipo.toUpdateJson())
        .eq('id', equipo.id)
        .select()
        .single();
    return EquipoModel.fromJson(response);
  }

  // 🔹 DELETE
  Future<void> eliminarEquipo(String id) async {
    await _client.from(table).delete().eq('id', id);
  }
}
