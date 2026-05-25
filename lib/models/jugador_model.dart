// Representa la estructura de datos de un jugador
class JugadorModel {
  final String? id; // Opcional porque al crear no tiene ID
  final String nombreCompleto;
  final DateTime? fechaNacimiento;
  final String? fotoUrl;
  final bool activo;
  final bool estadisticasPublicas;
  final String? usuarioId;

  JugadorModel({
    this.id,
    required this.nombreCompleto,
    this.fechaNacimiento,
    this.fotoUrl,
    this.activo = true,
    this.estadisticasPublicas = false,
    this.usuarioId,
  });

  // Convertir a JSON para enviar a Supabase
  Map<String, dynamic> toJson() {
    return {
      'nombre_completo': nombreCompleto,
      'fecha_nacimiento': fechaNacimiento?.toIso8601String(),
      'foto_url': fotoUrl,
      'activo': activo,
      'estadisticas_publicas': estadisticasPublicas,
      'usuario_id': usuarioId,
    };
  }

  // Crear modelo desde JSON (para cuando consultemos)
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
      usuarioId: json['usuario_id'] as String?,
    );
  }

  JugadorModel copyWith({
    String? id,
    String? nombreCompleto,
    DateTime? fechaNacimiento,
    String? fotoUrl,
    bool? activo,
    bool? estadisticasPublicas,
    String? usuarioId,
  }) {
    return JugadorModel(
      id: id ?? this.id,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      activo: activo ?? this.activo,
      estadisticasPublicas: estadisticasPublicas ?? this.estadisticasPublicas,
      usuarioId: usuarioId ?? this.usuarioId,
    );
  }
}
