import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/campos_model.dart';

class CampoService {
  final SupabaseClient _client = Supabase.instance.client;
  final String table = 'campos';


  Future<void> crearCampo(CampoFutbolModel campo) async {
    try {
      await _client.from(table).insert(campo.toJsonSinId());
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
          .update(campo.toJsonSinId())
          .eq('id', id);
    } catch (e) {
      print(' Error actualizarCampo: $e');
      throw Exception('No se pudo actualizar el campo');
    }
  }

  // 🔹 DELETE
  Future<void> eliminarCampo(String id) async {
    try {
      await _client.from(table).delete().eq('id', id);
    } catch (e) {
      print(' Error eliminarCampo: $e');
      throw Exception('No se pudo eliminar el campo');
    }
  }

  // 
  Future<void> cambiarDisponibilidad(String id, String estado) async {
    try {
      await _client
          .from(table)
          .update({'disponible': estado}) // "SI" o "NO"
          .eq('id', id);
    } catch (e) {
      print(' Error cambiarDisponibilidad: $e');
      throw Exception('No se pudo cambiar disponibilidad');
    }
  }
}