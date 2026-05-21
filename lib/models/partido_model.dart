// lib/models/partido_model.dart
class PartidoModel {
  final String id;
  final String? categoriaId;
  final String categoriaNombre;
  final String equipoLocalId;
  final String equipoLocalNombre;
  final String equipoVisitanteId;
  final String equipoVisitanteNombre;
  final String campoId;
  final String campoNombre;
  final String campoCantidad;
  final String estadoId;
  final String estadoCodigo;
  final DateTime fechaHora;
  final String? observaciones;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  PartidoModel({
    required this.id,
    this.categoriaId,
    required this.categoriaNombre,
    required this.equipoLocalId,
    required this.equipoLocalNombre,
    required this.equipoVisitanteId,
    required this.equipoVisitanteNombre,
    required this.campoId,
    required this.campoNombre,
    required this.campoCantidad,
    required this.estadoId,
    required this.estadoCodigo,
    required this.fechaHora,
    this.observaciones,
    required this.creadoEn,
    required this.actualizadoEn,
  });

  factory PartidoModel.fromJson(Map<String, dynamic> json) {
    return PartidoModel(
      id: json['id'] as String,
      categoriaId: json['categoria_id'] as String?,
      categoriaNombre: json['categorias']?['nombre'] as String? ?? 'Amistoso',
      equipoLocalId: json['equipo_local_id'] as String,
      equipoLocalNombre: json['equipos_local']?['nombre'] as String? ?? 'Desconocido',
      equipoVisitanteId: json['equipo_visitante_id'] as String,
      equipoVisitanteNombre: json['equipos_visitante']?['nombre'] as String? ?? 'Desconocido',
      campoId: json['campo_id'] as String,
      campoNombre: json['campos']?['nombre'] as String? ?? 'Sin campo',
      campoCantidad: json['campos']?['cantidad'] as String? ?? '5v5',
      estadoId: json['estado_id'] as String,
      estadoCodigo: json['estados_partido']?['codigo'] as String? ?? 'programado',
      fechaHora: DateTime.parse(json['fecha_hora'] as String),
      observaciones: json['observaciones'] as String?,
      creadoEn: DateTime.parse(json['creado_en'] as String),
      actualizadoEn: DateTime.parse(json['actualizado_en'] as String),
    );
  }
}