// lib/models/temporada_model.dart
class TemporadaModel {
  final String id;
  final String nombre;
  final String? descripcion;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String estadoId;

  TemporadaModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.fechaInicio,
    this.fechaFin,
    required this.estadoId,
  });

  factory TemporadaModel.fromJson(Map<String, dynamic> json) {
    return TemporadaModel(
      id: json['id'],
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      fechaInicio: json['fecha_inicio'] != null
          ? DateTime.parse(json['fecha_inicio'] as String)
          : null,
      fechaFin: json['fecha_fin'] != null
          ? DateTime.parse(json['fecha_fin'] as String)
          : null,
      estadoId: json['estado_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'fecha_inicio': fechaInicio?.toIso8601String(),
      'fecha_fin': fechaFin?.toIso8601String(),
      'estado_id': estadoId,
    };
  }
}