class EquipoCategoriaModel {
  final String id;
  final String equipoId;
  final String categoriaId;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final bool activo;
  final DateTime asignadoEn;

  EquipoCategoriaModel({
    required this.id,
    required this.equipoId,
    required this.categoriaId,
    this.fechaInicio,
    this.fechaFin,
    required this.activo,
    required this.asignadoEn,
  });

  factory EquipoCategoriaModel.fromJson(Map<String, dynamic> json) {
    return EquipoCategoriaModel(
      id: json['id'] as String,
      equipoId: json['equipo_id'] as String,
      categoriaId: json['categoria_id'] as String,
      fechaInicio: json['fecha_inicio'] != null 
          ? DateTime.parse(json['fecha_inicio'] as String) 
          : null,
      fechaFin: json['fecha_fin'] != null 
          ? DateTime.parse(json['fecha_fin'] as String) 
          : null,
      activo: json['activo'] as bool,
      asignadoEn: DateTime.parse(json['asignado_en'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'equipo_id': equipoId,
      'categoria_id': categoriaId,
      if (fechaInicio != null) 'fecha_inicio': fechaInicio!.toIso8601String(),
      if (fechaFin != null) 'fecha_fin': fechaFin!.toIso8601String(),
      'activo': activo,
      'asignado_en': asignadoEn.toIso8601String(),
    };
  }

  EquipoCategoriaModel copyWith({
    String? id,
    String? equipoId,
    String? categoriaId,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    bool? activo,
    DateTime? asignadoEn,
  }) {
    return EquipoCategoriaModel(
      id: id ?? this.id,
      equipoId: equipoId ?? this.equipoId,
      categoriaId: categoriaId ?? this.categoriaId,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      activo: activo ?? this.activo,
      asignadoEn: asignadoEn ?? this.asignadoEn,
    );
  }
}