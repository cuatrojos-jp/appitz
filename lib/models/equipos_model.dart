class EquipoModel {
  final String? id;
  final String nombre;
  final String categoria; // Ej: Infantil, Juvenil, Libre
  final String? fotoUrl;
  bool activo;

  EquipoModel({
    this.id,
    required this.nombre,
    required this.categoria,
    this.fotoUrl,
    this.activo = true,
  });

  // 🔹 Para INSERT y UPDATE (sin id)
  Map<String, dynamic> toJsonSinId() {
    return {
      'nombre': nombre,
      'categoria': categoria,
      'foto_url': fotoUrl,
      'activo': activo,
    };
  }

  // 🔹 Desde Supabase
  factory EquipoModel.fromJson(Map<String, dynamic> json) {
    return EquipoModel(
      id: json['id'],
      nombre: json['nombre'],
      categoria: json['categoria'],
      fotoUrl: json['foto_url'],
      activo: json['activo'] ?? true,
    );
  }
}