// Representa la estructura de datos de un jugador
class JugadorModel {
  final String? id; // Opcional porque al crear no tiene ID
  final String nombreCompleto;
  final String? emailContacto;
  final DateTime? fechaNacimiento;
  final String? fotoUrl;
  final bool activo;
  final bool estadisticasPublicas;
  final String? usuarioId;
  final String? descripcion;

  JugadorModel({
    this.id,
    required this.nombreCompleto,
    this.emailContacto,
    this.fechaNacimiento,
    this.fotoUrl,
    this.activo = true,
    this.estadisticasPublicas = false,
    this.usuarioId,
    this.descripcion,
  });

  // Convertir a JSON para enviar a Supabase
  Map<String, dynamic> toJson() {
    return {
      'nombre_completo': nombreCompleto,
      'email_contacto': emailContacto,
      'fecha_nacimiento': fechaNacimiento?.toIso8601String(),
      'foto_url': fotoUrl,
      'activo': activo,
      'estadisticas_publicas': estadisticasPublicas,
      'usuario_id': usuarioId,
      'descripcion': descripcion,
    };
  }

  // Crear modelo desde JSON (para cuando consultemos)
  factory JugadorModel.fromJson(Map<String, dynamic> json) {
    return JugadorModel(
      id: json['id'],
      nombreCompleto: json['nombre_completo'],
      emailContacto: json['email_contacto'] as String?,
      fechaNacimiento: json['fecha_nacimiento'] != null
          ? DateTime.parse(json['fecha_nacimiento'])
          : null,
      fotoUrl: json['foto_url'],
      activo: json['activo'] ?? true,
      estadisticasPublicas: json['estadisticas_publicas'] ?? false,
      usuarioId: json['usuario_id'] as String?,
      descripcion: json['descripcion'] as String?,
    );
  }

  JugadorModel copyWith({
    String? id,
    String? nombreCompleto,
    String? emailContacto,
    DateTime? fechaNacimiento,
    String? fotoUrl,
    bool? activo,
    bool? estadisticasPublicas,
    String? usuarioId,
    String? descripcion,
  }) {
    return JugadorModel(
      id: id ?? this.id,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      emailContacto: emailContacto ?? this.emailContacto,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      activo: activo ?? this.activo,
      estadisticasPublicas: estadisticasPublicas ?? this.estadisticasPublicas,
      usuarioId: usuarioId ?? this.usuarioId,
      descripcion: descripcion ?? this.descripcion,
    );
  }
}
