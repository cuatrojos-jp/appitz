// ── models/usuario.dart ──────────────────────────────────────

enum RolUsuario { admin, coordinador, jugador, }

extension RolUsuarioExt on RolUsuario {
  String get label {
    switch (this) {
      case RolUsuario.admin:       return 'Admin';
      case RolUsuario.coordinador:  return 'Coordinador';
      case RolUsuario.jugador:     return 'Jugador';
    }
  }
   static RolUsuario fromString(String v) {
    return RolUsuario.values.firstWhere(
      (r) => r.name == v,
      orElse: () => RolUsuario.jugador,

    );
  }
}

class Usuario {
  final String id;
  final String email;
  String? nombre;
  RolUsuario rol;
  bool activo;
  String? jugadorId;
   final DateTime creadoEn;
  DateTime actualizadoEn;

  Usuario({
    required this.id,
    required this.email,
    this.nombre,
    required this.rol,
    this.activo = true,
    this.jugadorId,
    required this.creadoEn,
    required this.actualizadoEn,
  });

  String get iniciales {
    if (nombre == null || nombre!.isEmpty) return email.substring(0, 2).toUpperCase();
    final parts = nombre!.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0].substring(0, 2).toUpperCase();
  }

  Usuario copyWith({
    String? nombre,
    RolUsuario? rol,
    bool? activo,
    String? jugadorId,
  }) => Usuario(
    id: id,
    email: email,
    nombre: nombre ?? this.nombre,
    rol: rol ?? this.rol,
    activo: activo ?? this.activo,
    jugadorId: jugadorId ?? this.jugadorId,
    creadoEn: creadoEn,
    actualizadoEn: DateTime.now(),
  );

  factory Usuario.fromMap(Map<String, dynamic> m) => Usuario(
    id:             m['id'] as String,
    email:          m['email'] as String,
    nombre:         m['nombre'] as String?,
    rol:            RolUsuarioExt.fromString(m['rol'] as String? ?? 'jugador'),
    activo:         m['activo'] as bool? ?? true,
    jugadorId:      m['jugador_id'] as String?,
    creadoEn:       DateTime.parse(m['creado_en'] as String),
    actualizadoEn:  DateTime.parse(m['actualizado_en'] as String),
  );

  Map<String, dynamic> toMap() => {
    'id':             id,
    'email':          email,
    'nombre':         nombre,
    'rol':            rol.name,
    'activo':         activo,
    'jugador_id':     jugadorId,
    'actualizado_en': actualizadoEn.toIso8601String(),
  };
}
