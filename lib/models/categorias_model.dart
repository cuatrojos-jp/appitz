class CategoriaModel {
  final String id;
  final String temporadaId;
  final String nombre;
  final String? descripcion;
  final int? maxJugadores;
  final int? maxEquipos;

  CategoriaModel({
    required this.id,
    required this.temporadaId,
    required this.nombre,
    this.descripcion,
    this.maxJugadores,
    this.maxEquipos,
  });

  factory CategoriaModel.fromJson(Map<String, dynamic> json) {
    return CategoriaModel(
      id: json['id'] as String,
      temporadaId: json['temporadaId'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      maxJugadores: json['max_jugadores'] as int?,
      maxEquipos: json['max_equipos'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'temporada_id': temporadaId,
      'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
      if (maxJugadores != null) 'max_jugadores': maxJugadores,
      if (maxEquipos != null) 'max_equipos': maxEquipos,
    };
  }

  CategoriaModel copyWith({
    String? id,
    String? temporadaId,
    String? nombre,
    String? descripcion,
    int? maxJugadores,
    int? maxEquipos,
  }) {
    return CategoriaModel(
      id: id ?? this.id,
      temporadaId: temporadaId ?? this.temporadaId,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      maxJugadores: maxJugadores ?? this.maxJugadores,
      maxEquipos: maxEquipos ?? this.maxEquipos,
    );
  }
}
