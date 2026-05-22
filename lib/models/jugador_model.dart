// lib/models/jugador_model.dart
class JugadorModel {
  final String? id;
  final String nombreCompleto;
  final DateTime? fechaNacimiento;
  final String? fotoUrl;
  final bool activo;
  final bool estadisticasPublicas;
  final String? equipoId; // ← NUEVO: ID del equipo

  JugadorModel({
    this.id,
    required this.nombreCompleto,
    this.fechaNacimiento,
    this.fotoUrl,
    this.activo = true,
    this.estadisticasPublicas = false,
    this.equipoId, // ← NUEVO
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre_completo': nombreCompleto,
      'fecha_nacimiento': fechaNacimiento?.toIso8601String(),
      'foto_url': fotoUrl,
      'activo': activo,
      'estadisticas_publicas': estadisticasPublicas,
      'equipo_id': equipoId, // ← NUEVO
    };
  }

  factory JugadorModel.fromJson(Map<String, dynamic> json) {
    return JugadorModel(
      id: json['id'],
      nombreCompleto: json['nombre_completo'],
      fechaNacimiento: json['fecha_nacimiento'] != null
          ? DateTime.parse(json['fecha_nacimiento'])
          : null,
      fotoUrl: json['foto_url'],
      activo: json['activo'] ?? true,
      estadisticasPublicas: json['estadisticas_publicas'] ?? false,
      equipoId: json['equipo_id'], // ← NUEVO
    );
  }

  // Método copyWith para actualizar fácilmente
  JugadorModel copyWith({
    String? id,
    String? nombreCompleto,
    DateTime? fechaNacimiento,
    String? fotoUrl,
    bool? activo,
    bool? estadisticasPublicas,
    String? equipoId,
  }) {
    return JugadorModel(
      id: id ?? this.id,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      activo: activo ?? this.activo,
      estadisticasPublicas: estadisticasPublicas ?? this.estadisticasPublicas,
      equipoId: equipoId ?? this.equipoId,
    );
  }
}