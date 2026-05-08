import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/partido_model.dart';
import 'partido_validator.dart';

class PartidoService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final PartidoValidator _validator = PartidoValidator();

  // UUID del estado "programado" para nuevos partidos
  static const String _estadoProgramadoId =
      '32dd8daf-4d3f-4a2d-9cda-98f13af88493';

  /// Crear un nuevo partido (con validaciones)
  Future<PartidoModel> crearPartido({
    required String campoId,
    required String equipoLocalId,
    required String equipoVisitanteId,
    required DateTime fechaHora,
    String? categoriaId,
    String? observaciones,
  }) async {
    // Validar antes de crear
    await _validator.validarCreacionPartido(
      campoId: campoId,
      equipoLocalId: equipoLocalId,
      equipoVisitanteId: equipoVisitanteId,
      fechaHora: fechaHora,
      categoriaId: categoriaId,
    );

    final response = await _supabase
        .from('partidos')
        .insert({
          'campo_id': campoId,
          'equipo_local_id': equipoLocalId,
          'equipo_visitante_id': equipoVisitanteId,
          'fecha_hora': fechaHora.toIso8601String(),
          if (categoriaId != null) 'categoria_id': categoriaId,
          if (observaciones != null && observaciones.isNotEmpty)
            'observaciones': observaciones,
          'estado_id': _estadoProgramadoId, // Estado inicial: Programado
        })
        .select()
        .single();

    return PartidoModel.fromJson(response);
  }

  /// Obtener todos los partidos
  Future<List<PartidoModel>> obtenerTodosLosPartidos() async {
    final response = await _supabase
        .from('partidos')
        .select('''
          *,
          equipos!partidos_equipo_local_id_fkey(id, nombre),
          equipos!partidos_equipo_visitante_id_fkey(id, nombre),
          campos(id, nombre),
          categorias(id, nombre),
          estados_partido(id, codigo)
        ''')
        .order('fecha_hora', ascending: true);

    return response.map((json) => PartidoModel.fromJson(json)).toList();
  }

  /// Obtener partidos por fecha
  Future<List<PartidoModel>> obtenerPartidosPorFecha(DateTime fecha) async {
    final inicio = DateTime(fecha.year, fecha.month, fecha.day);
    final fin = inicio.add(const Duration(days: 1));

    final response = await _supabase
        .from('partidos')
        .select('''
          *,
          equipos!partidos_equipo_local_id_fkey(id, nombre),
          equipos!partidos_equipo_visitante_id_fkey(id, nombre),
          campos(id, nombre),
          categorias(id, nombre),
          estados_partido(id, codigo)
        ''')
        .gte('fecha_hora', inicio.toIso8601String())
        .lt('fecha_hora', fin.toIso8601String())
        .order('fecha_hora', ascending: true);

    return response.map((json) => PartidoModel.fromJson(json)).toList();
  }

  /// Obtener partidos por equipo
  Future<List<PartidoModel>> obtenerPartidosPorEquipo(String equipoId) async {
    final response = await _supabase
        .from('partidos')
        .select('''
          *,
          equipos!partidos_equipo_local_id_fkey(id, nombre),
          equipos!partidos_equipo_visitante_id_fkey(id, nombre),
          campos(id, nombre),
          categorias(id, nombre),
          estados_partido(id, codigo)
        ''')
        .or('equipo_local_id.eq.$equipoId,equipo_visitante_id.eq.$equipoId')
        .order('fecha_hora', ascending: false);

    return response.map((json) => PartidoModel.fromJson(json)).toList();
  }

  /// Obtener un partido por ID
  Future<PartidoModel?> obtenerPartidoPorId(String id) async {
    final response = await _supabase
        .from('partidos')
        .select('''
          *,
          equipos!partidos_equipo_local_id_fkey(id, nombre),
          equipos!partidos_equipo_visitante_id_fkey(id, nombre),
          campos(id, nombre),
          categorias(id, nombre),
          estados_partido(id, codigo)
        ''')
        .eq('id', id)
        .maybeSingle();

    return response != null ? PartidoModel.fromJson(response) : null;
  }

  /// Actualizar un partido existente (con validaciones)
  Future<PartidoModel> actualizarPartido({
    required String id,
    String? campoId,
    String? equipoLocalId,
    String? equipoVisitanteId,
    DateTime? fechaHora,
    String? categoriaId,
    String? observaciones,
    String? estadoId,
  }) async {
    // Validar que se pueda editar (temporada no histórica)
    await _validator.validarEdicionPartido(id);

    final updates = <String, dynamic>{};

    if (campoId != null) updates['campo_id'] = campoId;
    if (equipoLocalId != null) updates['equipo_local_id'] = equipoLocalId;
    if (equipoVisitanteId != null)
      updates['equipo_visitante_id'] = equipoVisitanteId;
    if (fechaHora != null) updates['fecha_hora'] = fechaHora.toIso8601String();
    if (categoriaId != null) updates['categoria_id'] = categoriaId;
    if (observaciones != null)
      updates['observaciones'] = observaciones.isEmpty ? null : observaciones;
    if (estadoId != null) updates['estado_id'] = estadoId;

    if (updates.isEmpty) {
      throw Exception('No hay datos para actualizar.');
    }

    final response = await _supabase
        .from('partidos')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return PartidoModel.fromJson(response);
  }

  /// Eliminar un partido (solo si se puede)
  Future<void> eliminarPartido(String id) async {
    // Validar que se pueda editar (temporada no histórica)
    await _validator.validarEdicionPartido(id);

    await _supabase.from('partidos').delete().eq('id', id);
  }

  /// Cambiar estado de un partido (programado, en_curso, finalizado, etc.)
  Future<PartidoModel> cambiarEstado(String id, String nuevoEstadoId) async {
    await _validator.validarEdicionPartido(id);

    final response = await _supabase
        .from('partidos')
        .update({'estado_id': nuevoEstadoId})
        .eq('id', id)
        .select()
        .single();

    return PartidoModel.fromJson(response);
  }
}
