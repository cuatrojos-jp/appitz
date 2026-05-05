class CampoFutbolModel {
  final String? id;
  final String nombre;
  final String direccion;
  final String cantidad;
  final String? fotoUrl;
  bool disponible;

  CampoFutbolModel({
    this.id,
    required this.nombre,
    required this.direccion,
    required this.cantidad,
    this.fotoUrl,
    this.disponible = true,
  });

  Map<String, dynamic> toJsonSinId() {
    return {
      'nombre': nombre,
      'direccion': direccion,
      'cantidad': cantidad,
      'foto_url': fotoUrl,
      'disponible': disponible,
    };
  }

  factory CampoFutbolModel.fromJson(Map<String, dynamic> json) {
    return CampoFutbolModel(
      id: json['id'],
      nombre: json['nombre'],
      direccion: json['direccion'],
      cantidad: json['cantidad'],
      fotoUrl: json['foto_url'],
      disponible: json['disponible'] ?? true,
    );
  }
}