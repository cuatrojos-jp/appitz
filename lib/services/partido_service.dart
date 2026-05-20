import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/partido_model.dart';
import '../models/campos_model.dart';
import '../models/equipos_model.dart';
import 'partido_validator.dart';
import 'equipo_service.dart';

class PartidoService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final PartidoValidator _validator = PartidoValidator();

  // UUID del estado "programado" para nuevos partidos
  static const String _estadoProgramadoId =
      '75e0fced-c2d6-4896-9356-2b27a0bf3c78';

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
    _validator.validarLongitudObservaciones(observaciones);
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
          'fecha_hora': fechaHora.toUtc().toIso8601String(),
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
        equipos_local:equipos!partidos_equipo_local_id_fkey(id, nombre),
        equipos_visitante:equipos!partidos_equipo_visitante_id_fkey(id, nombre),
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
        .gte('fecha_hora', inicio.toUtc().toIso8601String())
        .lt('fecha_hora', fin.toUtc().toIso8601String())
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
    if (equipoVisitanteId != null) {
      updates['equipo_visitante_id'] = equipoVisitanteId;
    }
    if (fechaHora != null)
      updates['fecha_hora'] = fechaHora.toUtc().toIso8601String();
    if (categoriaId != null) updates['categoria_id'] = categoriaId;
    if (observaciones != null) {
      updates['observaciones'] = observaciones.isEmpty ? null : observaciones;
    }
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

  Future<List<CampoFutbolModel>> obtenerTodos() async {
    final response = await _supabase
        .from('campos')
        .select('*')
        .eq('disponible', true)
        .order('nombre', ascending: true);

    return response.map((json) => CampoFutbolModel.fromJson(json)).toList();
  }

  Future<List<CampoFutbolModel>> obtenerCompatibleCon(String cantidad) async {
    var query = _supabase.from('campos').select('*').eq('disponible', true);

    //if (cantidad != '11v11') {
    query = query.eq('cantidad', cantidad);
    //}

    final response = await query.order('nombre', ascending: true);
    return response.map((json) => CampoFutbolModel.fromJson(json)).toList();
  }

  Future<List<EquipoModel>> obtenerEquiposCompatibles(String cantidad) async {
    var query = _supabase.from('equipos').select('*');

    //if (cantidad != '11v11') {
    query = query.eq('cantidad', cantidad);
    //}

    final response = await query.order('nombre', ascending: true);
    return response.map((json) => EquipoModel.fromJson(json)).toList();
  }

  /// Obtener equipos con sus categorías en una temporada específica
  Future<List<Map<String, dynamic>>> obtenerEquiposConCategoriaEnTemporada(
    String temporadaId,
  ) async {
    // 1. Obtener todas las categorías de la temporada
    final categorias = await _supabase
        .from('categorias')
        .select('id')
        .eq('temporada_id', temporadaId);

    final categoriaIds = categorias.map((c) => c['id'] as String).toList();

    if (categoriaIds.isEmpty) return [];

    // 2. Obtener relaciones equipo-categoría
    final relaciones = await _supabase
        .from('equipos_categorias')
        .select('equipo_id, categoria_id')
        .inFilter('categoria_id', categoriaIds)
        .eq('activo', true);

    // 3. Crear mapa equipo_id -> lista de categorías
    final Map<String, List<String>> categoriasPorEquipo = {};
    for (var rel in relaciones) {
      final equipoId = rel['equipo_id'] as String;
      final categoriaId = rel['categoria_id'] as String;
      categoriasPorEquipo.putIfAbsent(equipoId, () => []).add(categoriaId);
    }

    // 4. Obtener todos los equipos
    final equipoService = EquipoService();
    final todosEquipos = await equipoService.obtenerEquipos();

    // 5. Combinar
    return todosEquipos.map((equipo) {
      return {
        'equipo': equipo,
        'categoria_ids': categoriasPorEquipo[equipo.id] ?? [],
      };
    }).toList();
  }

  Future<void> enviarRol() async {
    final hoy = DateTime.now();
    final diaSemana = hoy.weekday; // 1=lunes, 7=domingo

    DateTime inicio;
    DateTime fin;
    String tipoRol;

    if (diaSemana >= 1 && diaSemana <= 4) {
      final diasHastaViernes = 5 - diaSemana;
      inicio = DateTime(hoy.year, hoy.month, hoy.day + diasHastaViernes);
      fin = inicio.add(const Duration(days: 2)); // viernes, sábado, domingo
      tipoRol = 'fin_de_semana';
    } else {
      final diasHastaLunes = 8 - diaSemana;
      inicio = DateTime(hoy.year, hoy.month, hoy.day + diasHastaLunes);
      fin = inicio.add(const Duration(days: 6)); // lunes a domingo
      tipoRol = 'semanal';
    }

    final response = await _supabase.functions.invoke(
      'send-rol',
      body: {
        'inicio': inicio.toUtc().toIso8601String(),
        'fin': fin.toUtc().toIso8601String(),
        'tipo_rol': tipoRol,
      },
    );

    if (response.status != 200) {
      throw Exception('Error al enviar rol: ${response.data}');
    }
  }
}
