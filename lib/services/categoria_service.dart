import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/categorias_model.dart';
import '../utils/string_utils.dart';

class CategoriaService {
  final SupabaseClient _supabase = Supabase.instance.client;

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
    await _supabase.from('categorias').delete().eq('id', id);
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
}
