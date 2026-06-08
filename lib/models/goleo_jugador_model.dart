// lib/models/goleo_jugador_model.dart
class GoleoJugadorModel {
  final String jugadorId;
  final String nombreCompleto;
  final String? fotoUrl;
  final String? equipoId;
  final int goles;
  final int asistencias;
  final int penales;
  final int amarillas;
  final int rojas;

  GoleoJugadorModel({
    required this.jugadorId,
    required this.nombreCompleto,
    this.fotoUrl,
    this.equipoId,
    required this.goles,
    required this.asistencias,
    required this.penales,
    required this.amarillas,
    required this.rojas,
  });

  factory GoleoJugadorModel.fromJson(Map<String, dynamic> json) {
    return GoleoJugadorModel(
      jugadorId: json['jugador_id'] ?? '',
      nombreCompleto: json['nombre_completo'] ?? '',
      fotoUrl: json['foto_url'],
      equipoId: json['equipo_id'],
      goles: json['goles'] ?? 0,
      asistencias: json['asistencias'] ?? 0,
      penales: json['penales'] ?? 0,
      amarillas: json['amarillas'] ?? 0,
      rojas: json['rojas'] ?? 0,
    );
  }
}
