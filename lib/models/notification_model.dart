class NotificationModel {
  final String id;
  final String usuarioId;
  final String titulo;
  final String mensaje;
  final String tipo;
  final bool leida;
  final String? urlDestino;
  final DateTime creadoEn;
  final DateTime? leidaEn;

  NotificationModel({
    required this.id,
    required this.usuarioId,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    required this.leida,
    this.urlDestino,
    required this.creadoEn,
    this.leidaEn,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      usuarioId: json['usuario_id'] as String,
      titulo: json['titulo'] as String,
      mensaje: json['mensaje'] as String,
      tipo: json['tipo'] as String,
      leida: json['leida'] as bool? ?? false,
      urlDestino: json['url_destino'] as String?,
      creadoEn: DateTime.parse(json['creado_en'] as String),
      leidaEn: json['leida_en'] != null
          ? DateTime.parse(json['leida_en'] as String)
          : null,
    );
  }

  NotificationModel copyWith({bool? leida, DateTime? leidaEn}) {
    return NotificationModel(
      id: id,
      usuarioId: usuarioId,
      titulo: titulo,
      mensaje: mensaje,
      tipo: tipo,
      leida: leida ?? this.leida,
      urlDestino: urlDestino,
      creadoEn: creadoEn,
      leidaEn: leidaEn ?? this.leidaEn,
    );
  }
}