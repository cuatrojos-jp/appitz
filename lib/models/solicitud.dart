// ── models/solicitud.dart ────────────────────────────────────

enum EstadoSolicitud { pendiente, aprobada, rechazada }

extension EstadoSolicitudExt on EstadoSolicitud {
  String get label {
    switch (this) {
      case EstadoSolicitud.pendiente:  return 'Pendiente';
      case EstadoSolicitud.aprobada:   return 'Aprobada';
      case EstadoSolicitud.rechazada:  return 'Rechazada';
    }
  }
}

class Solicitud {
  final String id;
  final String usuarioId;
  String? jugadorId;
  final String nombreSolicitante;
  final DateTime? fechaNacimiento;
  final String? equipoSolicitado;
  final String? notasSolicitante;
  EstadoSolicitud estado;
  String? notasCoordinador;
  String? revisadoPor;
  DateTime? revisadoEn;
  final DateTime creadoEn;

  Solicitud({
    required this.id,
    required this.usuarioId,
    this.jugadorId,
    required this.nombreSolicitante,
    this.fechaNacimiento,
    this.equipoSolicitado,
    this.notasSolicitante,
    this.estado = EstadoSolicitud.pendiente,
    this.notasCoordinador,
    this.revisadoPor,
    this.revisadoEn,
    required this.creadoEn,
  });

  String get iniciales {
    final parts = nombreSolicitante.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0].substring(0, 2).toUpperCase();
  }

  String get tiempoTranscurrido {
    final diff = DateTime.now().difference(creadoEn);
    if (diff.inMinutes < 60)  return 'hace ${diff.inMinutes}m';
    if (diff.inHours < 24)    return 'hace ${diff.inHours}h';
    if (diff.inDays == 1)     return 'ayer';
    return 'hace ${diff.inDays}d';
  }

  factory Solicitud.fromMap(Map<String, dynamic> m) => Solicitud(
    id:                  m['id'] as String,
    usuarioId:           m['usuario_id'] as String,
    jugadorId:           m['jugador_id'] as String?,
    nombreSolicitante:   m['nombre_solicitante'] as String,
    fechaNacimiento:     m['fecha_nacimiento'] != null
                           ? DateTime.parse(m['fecha_nacimiento'] as String)
                           : null,
    equipoSolicitado:    m['equipo_solicitado'] as String?,
    notasSolicitante:    m['notas_solicitante'] as String?,
    estado:              EstadoSolicitud.values.firstWhere(
                           (e) => e.name == m['estado'],
                           orElse: () => EstadoSolicitud.pendiente),
    notasCoordinador:    m['notas_coordinador'] as String?,
    revisadoPor:         m['revisado_por'] as String?,
    revisadoEn:          m['revisado_en'] != null
                           ? DateTime.parse(m['revisado_en'] as String)
                           : null,
    creadoEn:            DateTime.parse(m['creado_en'] as String),
  );
}
