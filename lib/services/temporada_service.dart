import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/temporadas_model.dart';

class TemporadaService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _estadoActivoId = 'a4a0e12b-40b9-4c7a-979b-654e7807e012';
  static const String _estadoFinalizadoId =
      'af6a7363-5105-4c22-9b03-4f77be807264';
  static const String _estadoSuspendidoId =
      '90f514a4-b43c-4fb1-b327-366b708dd9c2';
  static const String _estadoProgramadoId =
      '32dd8daf-4d3f-4a2d-9cda-98f13af88493';

  /// Crear una nueva temporada (el trigger asigna estado_id, creado_por, creado_en)
  Future<TemporadaModel> crearTemporada({
    required String nombre,
    String? descripcion,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    final response = await _supabase
        .from('temporadas')
        .insert({
          'nombre': nombre,
          'descripcion': descripcion,
          if (fechaInicio != null)
            'fecha_inicio': fechaInicio.toIso8601String(),
          if (fechaFin != null) 'fecha_fin': fechaFin.toIso8601String(),
        })
        .select()
        .single();

    return TemporadaModel.fromJson(response);
  }

  /// Verificar si una temporada es editable (estado PROGRAMADO)
  Future<bool> esTemporadaEditable(String temporadaId) async {
    final response = await _supabase
        .from('temporadas')
        .select('estado_id')
        .eq('id', temporadaId)
        .single();

    final estadoId = response['estado_id'] as String;
    return estadoId == _estadoProgramadoId; // Solo programado es editable
  }

  /// Activar una temporada (cambia estado a ACTIVO)
  Future<void> activarTemporada(String id) async {
    await _supabase
        .from('temporadas')
        .update({'estado_id': _estadoActivoId})
        .eq('id', id);
  }

  /// Finalizar una temporada (cambia estado a FINALIZADO)
  Future<void> finalizarTemporada(String id) async {
    await _supabase
        .from('temporadas')
        .update({'estado_id': _estadoFinalizadoId})
        .eq('id', id);
  }

  /// Suspender una temporada (cambia estado a SUSPENDIDO)
  Future<void> suspenderTemporada(String id) async {
    await _supabase
        .from('temporadas')
        .update({'estado_id': _estadoSuspendidoId})
        .eq('id', id);
  }

  Future<void> actualizarTemporada(TemporadaModel temporada) async {
    await _supabase
        .from('temporadas')
        .update({
          'nombre': temporada.nombre,
          'descripcion': temporada.descripcion,
          if (temporada.fechaInicio != null)
            'fecha_inicio': temporada.fechaInicio!.toIso8601String(),
          if (temporada.fechaFin != null)
            'fecha_fin': temporada.fechaFin!.toIso8601String(),
        })
        .eq('id', temporada.id);
  }

  /// Eliminar una temporada
  Future<void> eliminar(String id) async {
    await _supabase.from('temporadas').delete().eq('id', id);
  }

  /// Listar todas las temporadas
  Future<List<TemporadaModel>> listarTemporadas() async {
    final response = await _supabase
        .from('temporadas')
        .select('''
          id,
          nombre,
          descripcion,
          fecha_inicio,
          fecha_fin,
          estado_id,
          estados_temporada!inner(codigo)
        ''')
        .order('fecha_inicio', ascending: false);

    return response.map((json) => TemporadaModel.fromJson(json)).toList();
  }

  Future<List<String>?> listarTemporadaIds() async {
    final response = await _supabase
        .from('temporadas')
        .select('id')
        .order('fecha_inicio', ascending: false);

    return response.map((json) => json['id'] as String).toList();
  }

  /// Obtener temporadas activas y programadas (para dropdown)
  Future<List<TemporadaModel>> obtenerTemporadasActivasYProgramadas() async {
    final response = await _supabase
        .from('temporadas')
        .select('''
         id,
         nombre,
         descripcion,
         fecha_inicio,
         fecha_fin,
         estado_id,
         estados_temporada!inner(codigo)
       ''')
        .inFilter('estado_id', [_estadoActivoId, _estadoProgramadoId])
        .order('nombre', ascending: true);
    return response.map((json) => TemporadaModel.fromJson(json)).toList();
  }

  // lib/services/temporada_service.dart

  /// Obtener temporadas PROGRAMADAS (para asignar a nuevas categorías)
  Future<List<TemporadaModel>> obtenerTemporadasProgramadas() async {
    final response = await _supabase
        .from('temporadas')
        .select('''
        id,
        nombre,
        descripcion,
        fecha_inicio,
        fecha_fin,
        estado_id,
        estados_temporada!inner(codigo)
      ''')
        .eq('estado_id', _estadoProgramadoId)
        .order('nombre', ascending: true);

    return response.map((json) => TemporadaModel.fromJson(json)).toList();
  }

  /// Obtener la primera temporada programada (error si no hay)
  Future<TemporadaModel> obtenerPrimeraTemporadaProgramada() async {
    final response = await _supabase
        .from('temporadas')
        .select('''
        id,
        nombre,
        descripcion,
        fecha_inicio,
        fecha_fin,
        estado_id,
        estados_temporada!inner(codigo)
      ''')
        .eq('estado_id', _estadoProgramadoId)
        .limit(1)
        .maybeSingle();

    if (response == null) {
      throw Exception('No hay temporadas programadas disponibles.');
    }

    return TemporadaModel.fromJson(response);
  }

  /// Obtener temporada por ID
  Future<TemporadaModel?> obtenerTemporadaPorId(String id) async {
    final response = await _supabase
        .from('temporadas')
        .select('''
          id,
          nombre,
          descripcion,
          fecha_inicio,
          fecha_fin,
          estado_id,
          estados_temporada!inner(codigo)
        ''')
        .eq('id', id)
        .maybeSingle();

    return response != null ? TemporadaModel.fromJson(response) : null;
  }

  /// Verificar si existe una temporada activa o programada
  Future<bool> existeTemporadaActivaOProgramada({String? excludeId}) async {
    var query = _supabase.from('temporadas').select('id').inFilter(
      'estado_id',
      [_estadoActivoId, _estadoProgramadoId],
    );

    if (excludeId != null) {
      query = query.neq('id', excludeId);
    }

    final response = await query;
    return response.isNotEmpty;
  }

  /// Verificar si existe una temporada activa
  // Future<bool> existeTemporadaActiva({String? excludeId}) async {
  //   var query = _supabase
  //       .from('temporadas')
  //       .select('id')
  //       .eq('estado_id', _estadoActivoId);

  //   if (excludeId != null) {
  //     query = query.neq('id', excludeId);
  //   }

  //   final response = await query.limit(1);
  //   return response.isNotEmpty;
  // }

  /// Obtener la temporada activa (asume que solo hay una)
  Future<TemporadaModel?> obtenerTemporadaActiva() async {
    final response = await _supabase
        .from('temporadas')
        .select('''
        id,
        nombre,
        descripcion,
        fecha_inicio,
        fecha_fin,
        estado_id,
        estados_temporada!inner(codigo)
      ''')
        .eq('estado_id', _estadoActivoId)
        .maybeSingle();

    return response != null ? TemporadaModel.fromJson(response) : null;
  }

  /// Obtener la temporada actual (primero activa, si no hay, la programada)
  Future<TemporadaModel?> obtenerTemporadaActual() async {
    // Primero buscar activa
    final activa = await obtenerTemporadaActiva();
    if (activa != null) return activa;

    // Si no hay activa, buscar programada
    final response = await _supabase
        .from('temporadas')
        .select('''
        id,
        nombre,
        descripcion,
        fecha_inicio,
        fecha_fin,
        estado_id,
        estados_temporada!inner(codigo)
      ''')
        .eq('estado_id', _estadoProgramadoId)
        .limit(1)
        .maybeSingle();

    return response != null ? TemporadaModel.fromJson(response) : null;
  }

  /// Verificar si una temporada es histórica (finalizada o suspendida)
  Future<bool> esTemporadaHistorica(String temporadaId) async {
    final response = await _supabase
        .from('temporadas')
        .select('estado_id')
        .eq('id', temporadaId)
        .single();

    final estadoId = response['estado_id'] as String;
    return estadoId == _estadoFinalizadoId || estadoId == _estadoSuspendidoId;
  }

  /// Obtener el estado de una temporada (devuelve el string: 'activo', 'programado', etc.)
  Future<String?> obtenerEstadoTemporada(String temporadaId) async {
    final response = await _supabase
        .from('temporadas')
        .select('estados_temporada!inner(codigo)')
        .eq('id', temporadaId)
        .maybeSingle();

    return response?['estados_temporada']?['codigo'] as String?;
  }

  Future<Map<String, dynamic>> obtenerContextoTemporada() async {
    final activa = await obtenerTemporadaActiva();
    if (activa != null) {
      return {'temporada': activa, 'esActiva': true, 'esProgramada': false};
    }

    final response = await _supabase
        .from('temporadas')
        .select('''
        id,
        nombre,
        descripcion,
        fecha_inicio,
        fecha_fin,
        estado_id,
        estados_temporada!inner(codigo)
      ''')
        .eq('estado_id', _estadoProgramadoId)
        .limit(1)
        .maybeSingle();

    if (response == null) {
      throw Exception('No hay temporada activa ni programada.');
    }

    final programada = TemporadaModel.fromJson(response);
    return {'temporada': programada, 'esActiva': false, 'esProgramada': true};
  }
}
