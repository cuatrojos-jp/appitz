class EventoModel {
  final String id;
  final String partidoId;
  final String? jugadorId;
  final String? jugadorNombre;
  final String? jugadorSecundarioId;
  final String? jugadorSecundarioNombre;
  final String tipoEventoId;
  final String tipoCodigo;
  final int minuto;
  final int? tiempo;
  final String? descripcion;
  final String? equipoId;
  final bool? golLocal;
  final bool validoParaEstadisticasJugador;
  final DateTime registradoEn;

  EventoModel({
    required this.id,
    required this.partidoId,
    this.jugadorId,
    this.jugadorNombre,
    this.jugadorSecundarioId,
    this.jugadorSecundarioNombre,
    required this.tipoEventoId,
    required this.tipoCodigo,
    required this.minuto,
    this.tiempo,
    this.descripcion,
    this.equipoId,
    this.golLocal,
    required this.validoParaEstadisticasJugador,
    required this.registradoEn,
  });

  factory EventoModel.fromJson(Map<String, dynamic> json) {
    return EventoModel(
      id: json['id'] as String,
      partidoId: json['partido_id'] as String,
      jugadorId: json['jugador_id'] as String?,
      jugadorNombre: json['jugador']?['nombre_completo'] as String?,
      jugadorSecundarioId: json['jugador_secundario_id'] as String?,
      jugadorSecundarioNombre:
          json['jugador_secundario']?['nombre_completo'] as String?,
      tipoEventoId: json['tipo_evento_id'] as String,
      tipoCodigo: json['tipos_evento']?['codigo'] as String? ?? '',
      minuto: json['minuto'] as int,
      tiempo: json['tiempo'] as int?,
      descripcion: json['descripcion'] as String?,
      equipoId: json['equipo_id'] as String?,
      golLocal: json['golLocal'] as bool?,
      validoParaEstadisticasJugador:
          json['valido_para_estadisticas_jugador'] as bool? ?? true,
      registradoEn: DateTime.parse(json['registrado_en'] as String),
    );
  }
}
