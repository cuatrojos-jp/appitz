// lib/models/estadistica_equipo_model.dart

class EstadisticaEquipoModel {
  final String? temporadaId;
  final String? temporadaNombre; // solo en historicas
  final String? categoriaId;
  final String? categoriaNombre;
  final String equipoId;
  final String equipoNombre;
  final String? escudoUrl;

  // Estadísticas
  final int partidosJugados;
  final int ganados;
  final int perdidos;
  final int empates;
  final int? empatesGanados;
  final int golesFavor;
  final int golesContra;
  final int diferenciaGoles;
  final int? puntos; // nullable en ambas fuentes

  // Solo en historicas
  final DateTime? cerradoEn;

  const EstadisticaEquipoModel({
    this.temporadaId,
    this.temporadaNombre,
    this.categoriaId,
    this.categoriaNombre,
    required this.equipoId,
    required this.equipoNombre,
    this.escudoUrl,
    required this.partidosJugados,
    required this.ganados,
    required this.perdidos,
    required this.empates,
    this.empatesGanados,
    required this.golesFavor,
    required this.golesContra,
    required this.diferenciaGoles,
    this.puntos,
    this.cerradoEn,
  });

  factory EstadisticaEquipoModel.fromJson(Map<String, dynamic> json) {
    return EstadisticaEquipoModel(
      temporadaId: json['temporada_id'] as String?,
      temporadaNombre: json['temporada_nombre'] as String?,
      categoriaId: json['categoria_id'] as String?,
      categoriaNombre: json['categoria_nombre'] as String?,
      equipoId: json['equipo_id'] as String,
      equipoNombre: json['equipo_nombre'] as String,
      escudoUrl: json['escudo_url'] as String?,
      partidosJugados: (json['partidos_jugados'] as num).toInt(),
      ganados: (json['ganados'] as num).toInt(),
      perdidos: (json['perdidos'] as num).toInt(),
      empates: (json['empates'] as num).toInt(),
      empatesGanados: (json['empates_ganados'] as num?)?.toInt(),
      golesFavor: (json['goles_favor'] as num).toInt(),
      golesContra: (json['goles_contra'] as num).toInt(),
      diferenciaGoles: (json['diferencia_goles'] as num).toInt(),
      puntos: (json['puntos'] as num?)?.toInt(),
      cerradoEn: json['cerrado_en'] != null
          ? DateTime.parse(json['cerrado_en'] as String)
          : null,
    );
  }
}
