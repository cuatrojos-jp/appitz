import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/equipos_model.dart';

class EquipoCategoriaService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Sincroniza los equipos asignados a una categoría
  /// - Inserta los nuevos
  /// - Elimina los que ya no están seleccionados
  Future<void> sincronizarEquiposEnCategoria({
    required String categoriaId,
    required List<String> equiposSeleccionadosIds,
  }) async {
    // 1. Obtener los equipos actualmente asignados a esta categoría
    final asignacionesActuales = await _supabase
        .from('equipos_categorias')
        .select('equipo_id')
        .eq('categoria_id', categoriaId)
        .eq('activo', true);

    final idsActuales = asignacionesActuales
        .map((a) => a['equipo_id'] as String)
        .toSet();

    final idsNuevos = equiposSeleccionadosIds.toSet();

    // 2. Equipos para ELIMINAR (están en actuales pero NO en nuevos)
    final idsAEliminar = idsActuales.difference(idsNuevos);

    // 3. Equipos para INSERTAR (están en nuevos pero NO en actuales)
    final idsAInsertar = idsNuevos.difference(idsActuales);

    // 4. Eliminar los que ya no están seleccionados
    if (idsAEliminar.isNotEmpty) {
      await _supabase
          .from('equipos_categorias')
          .update({
            'fecha_fin': DateTime.now().toIso8601String(),
            'activo': false,
          })
          .eq('categoria_id', categoriaId)
          .inFilter('equipo_id', idsAEliminar.toList());
    }

    // 5. Insertar los nuevos equipos
    if (idsAInsertar.isNotEmpty) {
      final nuevasAsignaciones = idsAInsertar
          .map(
            (equipoId) => {
              'categoria_id': categoriaId,
              'equipo_id': equipoId,
              'fecha_inicio': DateTime.now().toIso8601String(),
            },
          )
          .toList();

      await _supabase.from('equipos_categorias').insert(nuevasAsignaciones);
    }
  }

  /// Obtiene los IDs de los equipos asignados activamente a una categoría
  Future<List<String>> obtenerEquiposIdsPorCategoria(String categoriaId) async {
    final response = await _supabase
        .from('equipos_categorias')
        .select('equipo_id')
        .eq('categoria_id', categoriaId)
        .eq('activo', true); // Solo asignaciones activas

    return response.map((r) => r['equipo_id'] as String).toList();
  }

  /// Obtiene los equipos completos (con todos sus datos) asignados a una categoría
  Future<List<EquipoModel>> obtenerEquiposCompletosPorCategoria(
    String categoriaId,
  ) async {
    final response = await _supabase
        .from('equipos_categorias')
        .select('equipos(*)') // JOIN con tabla equipos
        .eq('categoria_id', categoriaId)
        .eq('activo', true);

    return response.map((r) => EquipoModel.fromJson(r['equipos'])).toList();
  }
}
