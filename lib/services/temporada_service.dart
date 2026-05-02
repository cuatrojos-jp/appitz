// lib/services/temporada_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/temporadas_model.dart';

class TemporadaService {
  final SupabaseClient _supabase = Supabase.instance.client;

  //static const String _estadoProgramadoId = '32dd8daf-4d3f-4a2d-9cda-98f13af88493';
  static const String _estadoActivoId = 'a4a0e12b-40b9-4c7a-979b-654e7807e012';
  static const String _estadoFinalizadoId = 'af6a7363-5105-4c22-9b03-4f77be807264';
  static const String _estadoSuspendidoId = '90f514a4-b43c-4fb1-b327-366b708dd9c2';

  /// Crear una nueva temporada (el trigger asigna estado_id, creado_por, creado_en)
  Future<TemporadaModel> crearTemporada({
    required String nombre,
    String? descripcion,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    final response = await _supabase.from('temporadas').insert({
      'nombre': nombre,
      'descripcion': descripcion,
      if (fechaInicio != null) 'fecha_inicio': fechaInicio.toIso8601String(),
      if (fechaInicio != null) 'fecha_inicio': fechaInicio.toIso8601String(),
    }).select().single();

    return TemporadaModel.fromJson(response);
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
        if (temporada.fechaInicio != null) 'fecha_inicio': temporada.fechaInicio!.toIso8601String(),
        if (temporada.fechaFin != null) 'fecha_fin': temporada.fechaFin!.toIso8601String(),
      })
      .eq('id', temporada.id);
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
}