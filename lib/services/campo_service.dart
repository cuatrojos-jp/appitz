import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/campos_model.dart';

class CampoService {
  final SupabaseClient _client = Supabase.instance.client;

  final String table = 'campos';

  // 🔹 CREATE
  Future<void> crearCampo(CampoFutbolModel campo) async {
    try {
      final response = await _client
          .from(table)
          .insert(campo.toJson());

      if (response.error != null) {
        throw Exception(response.error!.message);
      }
    } catch (e) {
      print('🔥 Error crearCampo: $e');
      throw Exception('No se pudo crear el campo');
    }
  }

  // 🔹 READ (todos)
  Future<List<CampoFutbolModel>> obtenerCampos() async {
    try {
      final response = await _client.from(table).select();

      return (response as List)
          .map((json) => CampoFutbolModel.fromJson(json))
          .toList();
    } catch (e) {
      print('🔥 Error obtenerCampos: $e');
      throw Exception('No se pudieron obtener los campos');
    }
  }

  // 🔹 READ (por id)
  Future<CampoFutbolModel?> obtenerCampoPorId(String id) async {
    try {
      final response = await _client
          .from(table)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      return CampoFutbolModel.fromJson(response);
    } catch (e) {
      print('🔥 Error obtenerCampoPorId: $e');
      throw Exception('No se pudo obtener el campo');
    }
  }

  // 🔹 UPDATE
  Future<void> actualizarCampo(String id, CampoFutbolModel campo) async {
    try {
      await _client
          .from(table)
          .update(campo.toJson())
          .eq('id', id);
    } catch (e) {
      print('🔥 Error actualizarCampo: $e');
      throw Exception('No se pudo actualizar el campo');
    }
  }

  // 🔹 DELETE
  Future<void> eliminarCampo(String id) async {
    try {
      await _client
          .from(table)
          .delete()
          .eq('id', id);
    } catch (e) {
      print('🔥 Error eliminarCampo: $e');
      throw Exception('No se pudo eliminar el campo');
    }
  }

  // 🔹 CAMBIAR DISPONIBILIDAD
  Future<void> cambiarDisponibilidad(String id, bool estado) async {
    try {
      await _client
          .from(table)
          .update({'disponible': estado})
          .eq('id', id);
    } catch (e) {
      print('🔥 Error cambiarDisponibilidad: $e');
      throw Exception('No se pudo cambiar disponibilidad');
    }
  }
}