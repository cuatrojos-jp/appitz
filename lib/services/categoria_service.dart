import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/categorias_model.dart';
import '../utils/string_utils.dart';

class CategoriaService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Estados posibles de una temporada
  static const String estadoProgramadoId =
      '32dd8daf-4d3f-4a2d-9cda-98f13af88493';
  static const String estadoActivoId = 'a4a0e12b-40b9-4c7a-979b-654e7807e012';
  static const String estadoSuspendidoId =
      '90f514a4-b43c-4fb1-b327-366b708dd9c2';
  static const String estadoFinalizadoId =
      'af6a7363-5105-4c22-9b03-4f77be807264';

  /// Obtener todas las categorías
  Future<List<CategoriaModel>> obtenerTodas() async {
    final response = await _supabase
        .from('categorias')
        .select('*')
        .order('nombre', ascending: true);

    return response.map((json) => CategoriaModel.fromJson(json)).toList();
  }

  /// Obtener categorías por temporada
  Future<List<CategoriaModel>> obtenerPorTemporada(String temporadaId) async {
    final response = await _supabase
        .from('categorias')
        .select('*')
        .eq('temporada_id', temporadaId)
        .order('nombre', ascending: true);

    return response.map((json) => CategoriaModel.fromJson(json)).toList();
  }

  /// Obtener una categoría por ID
  Future<CategoriaModel?> obtenerPorId(String id) async {
    final response = await _supabase
        .from('categorias')
        .select('*')
        .eq('id', id)
        .maybeSingle();

    return response != null ? CategoriaModel.fromJson(response) : null;
  }

  /// Crear una nueva categoría
  Future<CategoriaModel> crear(CategoriaModel categoria) async {
    final response = await _supabase
        .from('categorias')
        .insert(categoria.toJson())
        .select()
        .single();

    return CategoriaModel.fromJson(response);
  }

  /// Actualizar una categoría existente
  Future<CategoriaModel> actualizar(CategoriaModel categoria) async {
    final response = await _supabase
        .from('categorias')
        .update(categoria.toJson())
        .eq('id', categoria.id)
        .select()
        .single();

    return CategoriaModel.fromJson(response);
  }

  /// Eliminar una categoría
  Future<void> eliminar(String id) async {
    await validarEliminacionCategoria(id);

    final response = await _supabase.from('categorias').delete().eq('id', id);

    if (response.error != null) {
      throw Exception(
        'Error al eliminar la categoría: ${response.error!.message}',
      );
    }
  }

  /// Verificar si existe una categoría con el mismo nombre en la misma temporada
  Future<bool> existeEnTemporada({
    required String nombre,
    required String temporadaId,
    String? excludeId,
  }) async {
    var query = _supabase
        .from('categorias')
        .select('id')
        .eq('nombre', nombre)
        .eq('temporada_id', temporadaId);

    if (excludeId != null) {
      query = query.neq('id', excludeId);
    }

    final response = await query.limit(1);
    return response.isNotEmpty;
  }

  /// Obtener todas las categorías con datos de la temporada (JOIN)
  Future<List<CategoriaModel>> obtenerTodasConTemporada() async {
    final response = await _supabase
        .from('categorias')
        .select('''
        id,
        nombre,
        temporada_id,
        temporadas!inner(nombre)
      ''')
        .order('nombre', ascending: true);

    // Convertir Map a CategoriaModel dentro del servicio
    return response.map((json) => CategoriaModel.fromJson(json)).toList();
  }

  /// Verificar si existe otra categoría con el mismo nombre en la misma temporada (ignorando mayúsculas, acentos y espacios)
  Future<bool> existeNombreEnTemporada({
    required String nombre,
    required String temporadaId,
    String? excludeId,
  }) async {
    var query = _supabase
        .from('categorias')
        .select('id, nombre')
        .eq('temporada_id', temporadaId);

    if (excludeId != null) {
      query = query.neq('id', excludeId);
    }

    final response = await query;

    final nombreNormalizado = StringUtils.normalize(nombre);

    return response.any((categoria) {
      final nombreExistente = categoria['nombre'] as String;
      final nombreExistenteNormalizado = StringUtils.normalize(nombreExistente);
      return nombreExistenteNormalizado == nombreNormalizado;
    });
  }

  /// Cuenta cuántos equipos están asignados a una categoría
  Future<int> _contarEquiposEnCategoria(String categoriaId) async {
    final response = await _supabase
        .from('equipos_categorias')
        .select('id')
        .eq('categoria_id', categoriaId)
        .eq('activo', true);

    return response.length;
  }

  Future<void> validarEliminacionCategoria(String categoriaId) async {
    // 1. Obtener la categoría con su temporada
    final categoria = await _supabase
        .from('categorias')
        .select('''
        *,
        temporada:temporadas(*)
      ''')
        .eq('id', categoriaId)
        .maybeSingle();

    if (categoria == null) {
      throw Exception('La categoría no existe.');
    }

    // 2. Obtener el estado de la temporada
    final temporada = categoria['temporada'];
    final estadoId = temporada['estado_id'] as String;

    // 3. Validar según el estado de la temporada
    switch (estadoId) {
      case estadoActivoId:
        // Verificar si tiene equipos asignados
        final equiposAsignados = await _contarEquiposEnCategoria(categoriaId);
        if (equiposAsignados > 0) {
          throw Exception(
            'No se puede eliminar la categoría porque está en una temporada ACTIVA '
            'y tiene $equiposAsignados equipo(s) asignado(s).',
          );
        }
        throw Exception(
          'No se puede eliminar la categoría porque pertenece a una temporada ACTIVA. '
          'Primero debes finalizar o suspender la temporada.',
        );

      case estadoSuspendidoId:
      case estadoFinalizadoId:
        throw Exception(
          'No se puede eliminar la categoría porque pertenece a una temporada '
          'SUSPENDIDA o FINALIZADA. Las categorías de temporadas históricas no se pueden eliminar.',
        );

      case estadoProgramadoId:
        // OK - Se puede eliminar porque la temporada está programada
        // Verificar si tiene equipos asignados (por si acaso)
        final equiposAsignados = await _contarEquiposEnCategoria(categoriaId);
        if (equiposAsignados > 0) {
          throw Exception(
            'No se puede eliminar la categoría porque tiene $equiposAsignados equipo(s) asignado(s). '
            'Primero debes desasignar los equipos de esta categoría.',
          );
        }
        return; // ✅ Validación exitosa

      default:
        throw Exception('Estado de temporada desconocido.');
    }
  }
}
