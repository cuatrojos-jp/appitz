class TipoEventoModel {
  final String id;
  final String codigo;
  final String? descripcion;
  final bool afectaMarcador;
  final bool requiereJugadorSecundario;

  TipoEventoModel({
    required this.id,
    required this.codigo,
    this.descripcion,
    required this.afectaMarcador,
    required this.requiereJugadorSecundario,
  });

  factory TipoEventoModel.fromJson(Map<String, dynamic> json) {
    return TipoEventoModel(
      id: json['id'] as String,
      codigo: json['codigo'] as String,
      descripcion: json['descripcion'] as String?,
      afectaMarcador: json['afecta_marcador'] as bool,
      requiereJugadorSecundario: json['requiere_jugador_secundario'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'descripcion': descripcion,
      'afecta_marcador': afectaMarcador,
      'requiere_jugador_secundario': requiereJugadorSecundario,
    };
  }
}
