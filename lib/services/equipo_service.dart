import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/equipos_model.dart';

class EquipoService {
  final SupabaseClient _client = Supabase.instance.client;
  final String table = 'equipos';

  // 🔹 CREATE
  Future<void> crearEquipo(EquipoModel equipo) async {
    final response = await _client
        .from(table)
        .insert(equipo.toJsonSinId());

    print('✅ INSERT EQUIPO: $response');
  }

  // 🔹 READ (todos)
  Future<List<EquipoModel>> obtenerEquipos() async {
    final response = await _client.from(table).select();

    print('✅ SELECT EQUIPOS: $response');

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

    print('✅ SELECT EQUIPO ID: $response');

    if (response == null) return null;

    return EquipoModel.fromJson(response);
  }

  // 🔹 UPDATE
  Future<void> actualizarEquipo(String id, EquipoModel equipo) async {
    final response = await _client
        .from(table)
        .update(equipo.toJsonSinId())
        .eq('id', id);

    print('✅ UPDATE EQUIPO: $response');
  }

  // 🔹 DELETE
  Future<void> eliminarEquipo(String id) async {
    final response =
        await _client.from(table).delete().eq('id', id);

    print('✅ DELETE EQUIPO: $response');
  }

  // 🔥 CAMBIAR ACTIVO (BOOL)
  Future<void> cambiarActivo(String id, bool estado) async {
    final response = await _client
        .from(table)
        .update({'activo': estado})
        .eq('id', id);

    print('✅ CAMBIAR ACTIVO: $response');
  }
}
