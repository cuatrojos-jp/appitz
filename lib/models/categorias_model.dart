class CategoriaModel {
  final String id;
  final String temporadaId;
  final String? temporadaNombre;
  final String nombre;
  final String? descripcion;

  CategoriaModel({
    required this.id,
    required this.temporadaId,
    this.temporadaNombre, 
    required this.nombre,
    this.descripcion,
  });

  factory CategoriaModel.fromJson(Map<String, dynamic> json) {
    return CategoriaModel(
      id: json['id'] as String,
      temporadaId: json['temporada_id'] as String,
      temporadaNombre: (json['temporadas'] as Map<String, dynamic>?)?['nombre'] as String?,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'temporada_id': temporadaId,
      'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
    };
  }

  CategoriaModel copyWith({
    String? id,
    String? temporadaId,
    String? temporadaNombre,
    String? nombre,
    String? descripcion,
  }) {
    return CategoriaModel(
      id: id ?? this.id,
      temporadaId: temporadaId ?? this.temporadaId,
      temporadaNombre: temporadaNombre ?? this.temporadaNombre,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
    );
  }
}