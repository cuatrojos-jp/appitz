// Representa la estructura de datos de un jugador
class JugadorModel {
  final String? id; // Opcional porque al crear no tiene ID
  final String nombreCompleto;
  final DateTime? fechaNacimiento;
  final String? fotoUrl;
  final bool activo;
  final bool estadisticasPublicas;

  JugadorModel({
    this.id,
    required this.nombreCompleto,
    this.fechaNacimiento,
    this.fotoUrl,
    this.activo = true,
    this.estadisticasPublicas = false,
  });

  // Convertir a JSON para enviar a Supabase
  Map<String, dynamic> toJson() {
    return {
      'nombre_completo': nombreCompleto,
      'fecha_nacimiento': fechaNacimiento?.toIso8601String(),
      'foto_url': fotoUrl,
      'activo': activo,
      'estadisticas_publicas': estadisticasPublicas,
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
    );
  }
}
