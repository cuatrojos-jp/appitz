class EquipoModel {
  final String id;  // ← Se mantiene requerido (no nullable)
  final String nombre;
  final String? escudoUrl;
  final String colorPrincipal;
  final String colorSecundario;
  final String cantidad;
  final DateTime? creadoEn;

  // Constructor para EQUIPOS EXISTENTES (con id)
  EquipoModel({
    required this.id,
    required this.nombre,
    this.escudoUrl,
    required this.colorPrincipal,
    required this.colorSecundario,
    required this.cantidad,
    this.creadoEn,
  });

  // 🔹 Constructor para NUEVOS EQUIPOS (sin id)
  factory EquipoModel.nuevo({
    required String nombre,
    String? escudoUrl,
    required String colorPrincipal,
    required String colorSecundario,
    required String cantidad,
  }) {
    return EquipoModel(
      id: '',  // ID temporal que no se usará en la BD
      nombre: nombre,
      escudoUrl: escudoUrl,
      colorPrincipal: colorPrincipal,
      colorSecundario: colorSecundario,
      cantidad: cantidad,
    );
  }

  // Para INSERT (excluye id si está vacío)
  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,  // Solo incluir id si no está vacío
      'nombre': nombre,
      'escudo_url': escudoUrl,
      'color_principal': colorPrincipal,
      'color_secundario': colorSecundario,
      'cantidad': cantidad,
    };
  }

  factory EquipoModel.fromJson(Map<String, dynamic> json) {
    print('JSON recibido: $json');

    return EquipoModel(
      id: json['id'] as String,  // ← Siempre viene de Supabase
      nombre: json['nombre'] as String,
      escudoUrl: json['escudo_url'] as String?,
      colorPrincipal: json['color_principal'] as String,
      colorSecundario: json['color_secundario'] as String,
      cantidad: json['cantidad'] ?? "5v5",
      creadoEn: json['creado_en'] == null
          ? null
          : DateTime.parse(json['creado_en'].toString()),
    );
  }

  // Para actualizaciones (siempre tiene id)
  Map<String, dynamic> toUpdateJson() {
    return {
      'nombre': nombre,
      'escudo_url': escudoUrl,
      'color_principal': colorPrincipal,
      'color_secundario': colorSecundario,
      'cantidad': cantidad.toString(),
    };
  }
}