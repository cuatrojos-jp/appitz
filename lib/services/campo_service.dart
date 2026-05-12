import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/campos_model.dart';

class CampoService {
  final SupabaseClient _client = Supabase.instance.client;
  final String table = 'campos';

  // 🔹 CREATE
  Future<void> crearCampo(CampoFutbolModel campo) async {
    await _client.from(table).insert(campo.toJsonSinId());
  }

  // 🔹 READ (TODOS)
  Future<List<CampoFutbolModel>> obtenerCampos() async {
    final response = await _client.from(table).select();

    return (response as List)
        .map((json) => CampoFutbolModel.fromJson(json))
        .toList();
  }

  // 🔥 READ POR ID
  Future<CampoFutbolModel?> obtenerCampoPorId(String id) async {
    final response = await _client
        .from(table)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;

    return CampoFutbolModel.fromJson(response);
  }

// 🔹 UPDATE (VERSIÓN MÁS SEGURA)
Future<void> actualizarCampo(CampoFutbolModel campo) async {
  // ✅ Validar que el id exista
  final id = campo.id;
  if (id == null) {
    throw Exception('No se puede actualizar: el campo no tiene ID');
  }
  
  try {
    await _client
        .from(table)
        .update({
          'nombre': campo.nombre,
          'direccion': campo.direccion,
          'cantidad': campo.cantidad,
          'disponible': campo.disponible,
          'foto_url': campo.fotoUrl,
        })
        .eq('id', id);
  } catch (e) {
    throw Exception('Error al actualizar campo: $e');
  }
}
  // 🔹 DELETE
  Future<void> eliminarCampo(String id) async {
    await _client.from(table).delete().eq('id', id);
  }

  // 🔹 CAMBIAR DISPONIBILIDAD
  Future<void> cambiarDisponibilidad(String id, bool estado) async {
    await _client
        .from(table)
        .update({'disponible': estado})
        .eq('id', id);
  }
}