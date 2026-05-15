class EventoPartidoModel {
  final String id;
  final String partidoId;
  final String? jugadorId;
  final String? jugadorSecundarioId;
  final String tipoEventoId;
  final int minuto;
  final int? tiempo;
  final String? descripcion;
  final DateTime registradoEn;
  final String? registradoPor;
  final String? temporadaId;
  final String? equipoId;
  final bool? golLocal;

  EventoPartidoModel({
    required this.id,
    required this.partidoId,
    this.jugadorId,
    this.jugadorSecundarioId,
    required this.tipoEventoId,
    required this.minuto,
    this.tiempo,
    this.descripcion,
    required this.registradoEn,
    this.registradoPor,
    this.temporadaId,
    this.equipoId,
    this.golLocal,
  });

  factory EventoPartidoModel.fromJson(Map<String, dynamic> json) {
    return EventoPartidoModel(
      id: json['id'] as String,
      partidoId: json['partido_id'] as String,
      jugadorId: json['jugador_id'] as String?,
      jugadorSecundarioId: json['jugador_secundario_id'] as String?,
      tipoEventoId: json['tipo_evento_id'] as String,
      minuto: json['minuto'] as int,
      tiempo: json['tiempo'] as int?,
      descripcion: json['descripcion'] as String?,
      registradoEn: DateTime.parse(json['registrado_en'] as String),
      registradoPor: json['registrado_por'] as String?,
      temporadaId: json['temporada_id'] as String?,
      equipoId: json['equipo_id'] as String?,
      golLocal: json['golLocal'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'partido_id': partidoId,
      if (jugadorId != null) 'jugador_id': jugadorId,
      if (jugadorSecundarioId != null) 'jugador_secundario_id': jugadorSecundarioId,
      'tipo_evento_id': tipoEventoId,
      'minuto': minuto,
      if (tiempo != null) 'tiempo': tiempo,
      if (descripcion != null) 'descripcion': descripcion,
      'registrado_en': registradoEn.toIso8601String(),
      if (registradoPor != null) 'registrado_por': registradoPor,
      if (temporadaId != null) 'temporada_id': temporadaId,
      if (equipoId != null) 'equipo_id': equipoId,
      if (golLocal != null) 'golLocal': golLocal,
    };
  }
}