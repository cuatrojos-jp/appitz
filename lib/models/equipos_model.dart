class EquipoModel {
  final String? id;
  final String nombre;
  final String? escudoUrl;
  final String colorPrincipal;
  final String colorSecundario;
  final DateTime? creadoEn;

  EquipoModel({
    this.id,
    required this.nombre,
    this.escudoUrl,
    required this.colorPrincipal,
    required this.colorSecundario,
    this.creadoEn,
  });

  // 🔹 Para INSERT (sin id ni creado_en)
  Map<String, dynamic> toJsonSinId() {
    return {
      'nombre': nombre,
      'escudo_url': escudoUrl,
      'color_principal': colorPrincipal,
      'color_secundario': colorSecundario,
    };
  }

  // 🔹 Desde Supabase
  factory EquipoModel.fromJson(Map<String, dynamic> json) {
    return EquipoModel(
      id: json['id'],
      nombre: json['nombre'],
      escudoUrl: json['escudo_url'],
      colorPrincipal: json['color_principal'],
      colorSecundario: json['color_secundario'],
      creadoEn: json['creado_en'] == null
          ? null
          : DateTime.parse(json['creado_en'].toString()),
    );
  }
}
