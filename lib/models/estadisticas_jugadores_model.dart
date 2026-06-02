// lib/models/estadisticas_jugadores_model.dart

class EstadisticasJugadorModel {
  final String jugadorId;
  final String nombreCompleto;
  final String? fotoUrl;
  final String? equipoId;
  final String temporadaId;
  final String temporadaNombre;
  final int goles;
  final int asistencias;
  final int penales;
  final DateTime? cerradoEn;
  final String? cerradoPor;

  const EstadisticasJugadorModel({
    required this.jugadorId,
    required this.nombreCompleto,
    this.fotoUrl,
    this.equipoId,
    required this.temporadaId,
    required this.temporadaNombre,
    required this.goles,
    required this.asistencias,
    required this.penales,
    this.cerradoEn,
    this.cerradoPor,
  });

  factory EstadisticasJugadorModel.fromJson(Map<String, dynamic> json) {
    return EstadisticasJugadorModel(
      jugadorId: json['jugador_id'] as String,
      nombreCompleto: json['nombre_completo'] as String,
      fotoUrl: json['foto_url'] as String?,
      equipoId: json['equipo_id'] as String?,
      temporadaId: json['temporada_id'] as String,
      temporadaNombre: json['temporada_nombre'] as String,
      goles: (json['goles'] as num).toInt(),
      asistencias: (json['asistencias'] as num).toInt(),
      penales: (json['penales'] as num).toInt(),
      cerradoEn: json['cerrado_en'] != null
          ? DateTime.parse(json['cerrado_en'] as String)
          : null,
      cerradoPor: json['cerrado_por'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'jugador_id': jugadorId,
    'nombre_completo': nombreCompleto,
    'foto_url': fotoUrl,
    'equipo_id': equipoId,
    'temporada_id': temporadaId,
    'temporada_nombre': temporadaNombre,
    'goles': goles,
    'asistencias': asistencias,
    'penales': penales,
  };

  int get totalParticipaciones => goles + asistencias + penales;

  @override
  String toString() =>
      'EstadisticasJugadorModel(jugadorId: $jugadorId, temporada: $temporadaNombre, '
      'goles: $goles, asistencias: $asistencias, penales: $penales)';
}
