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

  Future<void> deshabilitarEquipo({
    required String equipoId,
    required String razon,
  }) async {
    try {
      await _client
          .from(table)
          .update({'habilitado': false, 'habilitado_descripcion': razon.trim()})
          .eq('id', equipoId);
    } catch (e) {
      print('Error deshabilitando equipo: $e');
      rethrow;
    }
  }

  /// Habilitar un equipo (limpia la descripción automáticamente)
  Future<void> habilitarEquipo(String equipoId) async {
    await _client
        .from(table)
        .update({
          'habilitado': true,
          'habilitado_descripcion': null, // ← Limpia la descripción
        })
        .eq('id', equipoId);
  }

  /// Alternar el estado de un equipo (si no usas diálogos separados)
  /// Este método decide automáticamente si habilitar o deshabilitar
  Future<void> toggleHabilitado({
    required String equipoId,
    required bool estadoActual,
    String? razon, // Requerido solo si estadoActual == true (para deshabilitar)
  }) async {
    if (estadoActual == true) {
      // Va a DESHABILITAR (requiere razón)
      if (razon == null || razon.trim().isEmpty) {
        throw Exception(
          'Debes proporcionar una razón para deshabilitar el equipo.',
        );
      }
      await deshabilitarEquipo(equipoId: equipoId, razon: razon);
    } else {
      // Va a HABILITAR (no requiere razón)
      await habilitarEquipo(equipoId);
    }
  }

  /// Obtener solo equipos habilitados (útil para filtros en otros módulos)
  Future<List<EquipoModel>> obtenerEquiposHabilitados() async {
    try {
      final response = await _client
          .from(table)
          .select()
          .eq('habilitado', true)
          .order('nombre');

      return (response as List)
          .map((json) => EquipoModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error en obtenerEquiposHabilitados: $e');
      return [];
    }
  }

  /// Obtener solo equipos deshabilitados
  Future<List<EquipoModel>> obtenerEquiposDeshabilitados() async {
    try {
      final response = await _client
          .from(table)
          .select()
          .eq('habilitado', false)
          .order('nombre');

      return (response as List)
          .map((json) => EquipoModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error en obtenerEquiposDeshabilitados: $e');
      return [];
    }
  }
}
