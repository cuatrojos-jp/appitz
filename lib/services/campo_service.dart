import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/campos_model.dart';

class CampoService {
  final SupabaseClient _client = Supabase.instance.client;
  final String table = 'campos';

  
  Future<void> crearCampo(CampoFutbolModel campo) async {
    final response = await _client
        .from(table)
        .insert(campo.toJsonSinId());

    print('✅ RESPUESTA INSERT SUPABASE: $response');
  }

  // 🔹 READ (todos)
  Future<List<CampoFutbolModel>> obtenerCampos() async {
    final response = await _client.from(table).select();

    print('✅ RESPUESTA SELECT: $response');

    return (response as List)
        .map((json) => CampoFutbolModel.fromJson(json))
        .toList();
  }

  // 🔹 READ por ID
  Future<CampoFutbolModel?> obtenerCampoPorId(String id) async {
    final response = await _client
        .from(table)
        .select()
        .eq('id', id)
        .maybeSingle();

    print('✅ RESPUESTA SELECT ID: $response');

    if (response == null) return null;

    return CampoFutbolModel.fromJson(response);
  }

  // 🔹 UPDATE
  Future<void> actualizarCampo(String id, CampoFutbolModel campo) async {
    final response = await _client
        .from(table)
        .update(campo.toJsonSinId())
        .eq('id', id);

    print('✅ RESPUESTA UPDATE: $response');
  }

  // 🔹 DELETE
  Future<void> eliminarCampo(String id) async {
    final response =
        await _client.from(table).delete().eq('id', id);

    print('✅ RESPUESTA DELETE: $response');
  }

  // 🔥 CAMBIAR DISPONIBILIDAD (BOOL)
  Future<void> cambiarDisponibilidad(String id, bool estado) async {
    final response = await _client
        .from(table)
        .update({'disponible': estado})
        .eq('id', id);

    print('✅ RESPUESTA CAMBIAR DISPONIBILIDAD: $response');
  }
}