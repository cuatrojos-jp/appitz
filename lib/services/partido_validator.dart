import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/temporadas_model.dart';
import 'temporada_service.dart';
import 'equipo_service.dart';
import 'campo_service.dart';

class PartidoValidator {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TemporadaService _temporadaService = TemporadaService();
  final EquipoService _equipoService = EquipoService();
  final CampoService _campoService = CampoService();

  // UUIDs de estados
  static const String _estadoActivoId = 'a4a0e12b-40b9-4c7a-979b-654e7807e012';
  static const String _estadoProgramadoId = '32dd8daf-4d3f-4a2d-9cda-98f13af88493';

  // ============================================================
  // VALIDACIÓN DE TEMPORADA
  // ============================================================

  /// Obtener el contexto actual (temporada activa o programada)
  Future<Map<String, dynamic>> obtenerContextoTemporada() async {
    final temporadaActual = await _temporadaService.obtenerTemporadaActual();
    
    if (temporadaActual == null) {
      throw Exception('No hay temporada activa ni programada.');
    }
    
    final esActiva = temporadaActual.estadoId == _estadoActivoId;
    final esProgramada = temporadaActual.estadoId == _estadoProgramadoId;
    
    return {
      'temporada': temporadaActual,
      'esActiva': esActiva,
      'esProgramada': esProgramada,
    };
  }

  // ============================================================
  // VALIDACIÓN DE CAMPOS (CANCHAS)
  // ============================================================

  /// Verificar que el campo esté disponible
  Future<void> validarCampoDisponible(String campoId) async {
    final campo = await _campoService.obtenerCampoPorId(campoId);
    
    if (campo == null) {
      throw Exception('Campo no encontrado.');
    }
    
    if (!campo.disponible) {
      throw Exception('El campo no está disponible actualmente.');
    }
  }

  /// Verificar compatibilidad entre campo y equipos
  Future<void> validarCompatibilidadCampoEquipos({
    required String campoId,
    required String equipoLocalId,
    required String equipoVisitanteId,
  }) async {
    final campo = await _campoService.obtenerCampoPorId(campoId);
    final equipoLocal = await _equipoService.obtenerEquipoPorId(equipoLocalId);
    final equipoVisitante = await _equipoService.obtenerEquipoPorId(equipoVisitanteId);
    
    if (campo == null) throw Exception('Campo no encontrado.');
    if (equipoLocal == null) throw Exception('Equipo local no encontrado.');
    if (equipoVisitante == null) throw Exception('Equipo visitante no encontrado.');
    
    final esCompatibleLocal = _esCompatible(campo.cantidad, equipoLocal.cantidad as String);
    final esCompatibleVisitante = _esCompatible(campo.cantidad, equipoVisitante.cantidad as String);
    
    if (!esCompatibleLocal) {
      throw Exception('El equipo local (${equipoLocal.cantidad}) no es compatible con el campo (${campo.cantidad}).');
    }
    
    if (!esCompatibleVisitante) {
      throw Exception('El equipo visitante (${equipoVisitante.cantidad}) no es compatible con el campo (${campo.cantidad}).');
    }
  }

  bool _esCompatible(String campoModalidad, String equipoModalidad) {
    // Campo 11v11 es compatible con cualquier modalidad
    if (campoModalidad == '11v11') return true;
    // Para otros campos, deben coincidir exactamente
    return campoModalidad == equipoModalidad;
  }

  // ============================================================
  // VALIDACIÓN DE CATEGORÍAS (solo para temporada activa)
  // ============================================================

  /// Verificar que los equipos tengan categoría asignada y estén en la misma
  Future<void> validarCategoriasEquipos({
    required String equipoLocalId,
    required String equipoVisitanteId,
    required String temporadaId,
  }) async {
    // Obtener categorías de los equipos en esta temporada
    final localCategorias = await _obtenerCategoriasEquipoEnTemporada(equipoLocalId, temporadaId);
    final visitanteCategorias = await _obtenerCategoriasEquipoEnTemporada(equipoVisitanteId, temporadaId);
    
    if (localCategorias.isEmpty) {
      throw Exception('El equipo local no tiene categoría asignada en esta temporada.');
    }
    
    if (visitanteCategorias.isEmpty) {
      throw Exception('El equipo visitante no tiene categoría asignada en esta temporada.');
    }
    
    // Verificar que compartan al menos una categoría
    final categoriasComunes = localCategorias.where((c) => visitanteCategorias.contains(c)).toList();
    
    if (categoriasComunes.isEmpty) {
      throw Exception('Los equipos no pertenecen a la misma categoría.');
    }
  }

  Future<List<String>> _obtenerCategoriasEquipoEnTemporada(String equipoId, String temporadaId) async {
    final response = await _supabase
        .from('equipos_categorias')
        .select('categoria_id')
        .eq('equipo_id', equipoId)
        .eq('activo', true);
    
    // Filtrar por temporada (necesitas hacer join con categorias)
    final List<String> categorias = [];
    for (var ec in response) {
      final categoria = await _supabase
          .from('categorias')
          .select('id')
          .eq('id', ec['categoria_id'])
          .eq('temporada_id', temporadaId)
          .maybeSingle();
      
      if (categoria != null) {
        categorias.add(ec['categoria_id'] as String);
      }
    }
    
    return categorias;
  }

  // ============================================================
  // VALIDACIÓN DE CONFLICTOS DE HORARIO
  // ============================================================

  /// Verificar conflictos de horario (campo y equipos)
  Future<void> validarConflictosHorario({
    required String campoId,
    required String equipoLocalId,
    required String equipoVisitanteId,
    required DateTime fechaHora,
    String? excludePartidoId,
  }) async {
    final inicio = fechaHora;
    final fin = fechaHora.add(const Duration(hours: 1));
    
    // Verificar campo ocupado
    final campoOcupado = await _verificarCampoOcupado(campoId, inicio, fin, excludePartidoId);
    if (campoOcupado) {
      throw Exception('El campo ya está ocupado en ese horario.');
    }
    
    // Verificar equipo local ocupado
    final localOcupado = await _verificarEquipoOcupado(equipoLocalId, inicio, fin, excludePartidoId);
    if (localOcupado) {
      throw Exception('El equipo local ya tiene un partido en ese horario.');
    }
    
    // Verificar equipo visitante ocupado
    final visitanteOcupado = await _verificarEquipoOcupado(equipoVisitanteId, inicio, fin, excludePartidoId);
    if (visitanteOcupado) {
      throw Exception('El equipo visitante ya tiene un partido en ese horario.');
    }
  }

  Future<bool> _verificarCampoOcupado(String campoId, DateTime inicio, DateTime fin, String? excludeId) async {
    var query = _supabase
        .from('partidos')
        .select('id')
        .eq('campo_id', campoId)
        .lt('fecha_hora', fin.toIso8601String())
        .gt('fecha_hora', inicio.subtract(const Duration(hours: 1)).toIso8601String());
    
    if (excludeId != null) {
      query = query.neq('id', excludeId);
    }
    
    final response = await query.limit(1);
    return response.isNotEmpty;
  }

  Future<bool> _verificarEquipoOcupado(String equipoId, DateTime inicio, DateTime fin, String? excludeId) async {
    var query = _supabase
        .from('partidos')
        .select('id')
        .or('equipo_local_id.eq.$equipoId,equipo_visitante_id.eq.$equipoId')
        .lt('fecha_hora', fin.toIso8601String())
        .gt('fecha_hora', inicio.subtract(const Duration(hours: 1)).toIso8601String());
    
    if (excludeId != null) {
      query = query.neq('id', excludeId);
    }
    
    final response = await query.limit(1);
    return response.isNotEmpty;
  }

  // ============================================================
  // VALIDACIÓN DE EDICIÓN (partidos históricos)
  // ============================================================

  /// Verificar si un partido puede ser editado (no pertenece a temporada finalizada/suspendida)
  Future<void> validarEdicionPartido(String partidoId) async {
    // Obtener la categoría del partido
    final partido = await _supabase
        .from('partidos')
        .select('categoria_id')
        .eq('id', partidoId)
        .maybeSingle();
    
    if (partido == null) {
      throw Exception('Partido no encontrado.');
    }
    
    final categoriaId = partido['categoria_id'] as String?;
    
    if (categoriaId == null) {
      // Partido amistoso (sin categoría) - siempre editable
      return;
    }
    
    // Obtener temporada de la categoría
    final categoria = await _supabase
        .from('categorias')
        .select('temporada_id')
        .eq('id', categoriaId)
        .maybeSingle();
    
    if (categoria == null) {
      throw Exception('Categoría no encontrada.');
    }
    
    final temporadaId = categoria['temporada_id'] as String;
    final esHistorica = await _temporadaService.esTemporadaHistorica(temporadaId);
    
    if (esHistorica) {
      throw Exception('No se puede editar un partido de una temporada finalizada o suspendida.');
    }
  }

  // ============================================================
  // VALIDACIÓN COMPLETA (antes de crear partido)
  // ============================================================

  /// Validar todo antes de crear un partido
  Future<void> validarCreacionPartido({
    required String campoId,
    required String equipoLocalId,
    required String equipoVisitanteId,
    required DateTime fechaHora,
    String? categoriaId,
  }) async {
    // 1. Obtener contexto de temporada
    final contexto = await obtenerContextoTemporada();
    final temporada = contexto['temporada'] as TemporadaModel;
    final esActiva = contexto['esActiva'] as bool;
    final esProgramada = contexto['esProgramada'] as bool;
    
    // 2. Validar campo disponible
    await validarCampoDisponible(campoId);
    
    // 3. Validar compatibilidad campo-equipos
    await validarCompatibilidadCampoEquipos(
      campoId: campoId,
      equipoLocalId: equipoLocalId,
      equipoVisitanteId: equipoVisitanteId,
    );
    
    // 4. Validar conflictos de horario
    await validarConflictosHorario(
      campoId: campoId,
      equipoLocalId: equipoLocalId,
      equipoVisitanteId: equipoVisitanteId,
      fechaHora: fechaHora,
    );
    
    // 5. Validaciones según estado de temporada
    if (esActiva) {
      // Temporada activa: requieren categorías
      if (categoriaId == null) {
        throw Exception('En temporada activa, debe seleccionar una categoría.');
      }
      
      await validarCategoriasEquipos(
        equipoLocalId: equipoLocalId,
        equipoVisitanteId: equipoVisitanteId,
        temporadaId: temporada.id,
      );
    } else if (esProgramada) {
      // Temporada programada: partidos amistosos (categoría opcional)
      // No se validan categorías
    }
  }
}