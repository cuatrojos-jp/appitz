class EquipoModel {
  final String id;
  final String nombre;
  final String? escudoUrl;
  final String colorPrincipal;
  final String colorSecundario;
  final String cantidad;
  final DateTime? creadoEn;
  final bool habilitado; // ← NUEVO
  final String? habilitadoDescripcion; // ← NUEVO

  // Constructor para EQUIPOS EXISTENTES (con id)
  EquipoModel({
    required this.id,
    required this.nombre,
    this.escudoUrl,
    required this.colorPrincipal,
    required this.colorSecundario,
    required this.cantidad,
    this.creadoEn,
    this.habilitado = true, // ← Por defecto true
    this.habilitadoDescripcion, // ← Opcional
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
      id: '',
      nombre: nombre,
      escudoUrl: escudoUrl,
      colorPrincipal: colorPrincipal,
      colorSecundario: colorSecundario,
      cantidad: cantidad,
      habilitado: true, // ← Nuevos equipos siempre habilitados
      habilitadoDescripcion: null,
    );
  }

  // Para INSERT (excluye id si está vacío)
  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'nombre': nombre,
      'escudo_url': escudoUrl,
      'color_principal': colorPrincipal,
      'color_secundario': colorSecundario,
      'cantidad': cantidad,
      'habilitado': habilitado, // ← NUEVO
      'habilitado_descripcion': habilitadoDescripcion, // ← NUEVO
    };
  }

  // Desde JSON (para leer de la base de datos)
  factory EquipoModel.fromJson(Map<String, dynamic> json) {
    return EquipoModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      escudoUrl: json['escudo_url'] as String?,
      colorPrincipal: json['color_principal'] as String,
      colorSecundario: json['color_secundario'] as String,
      cantidad: json['cantidad'] ?? "5v5",
      creadoEn: json['creado_en'] == null
          ? null
          : DateTime.parse(json['creado_en'].toString()),
      habilitado:
          json['habilitado'] ?? true, // ← NUEVO (default true si viene null)
      habilitadoDescripcion:
          json['habilitado_descripcion'] as String?, // ← NUEVO
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
      // NOTA: habilitado NO va aquí porque se actualiza por separado
    };
  }

  // 🔹 COPIA para actualizar valores específicos
  EquipoModel copyWith({
    String? id,
    String? nombre,
    String? escudoUrl,
    String? colorPrincipal,
    String? colorSecundario,
    String? cantidad,
    DateTime? creadoEn,
    bool? habilitado,
    String? habilitadoDescripcion,
  }) {
    return EquipoModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      escudoUrl: escudoUrl ?? this.escudoUrl,
      colorPrincipal: colorPrincipal ?? this.colorPrincipal,
      colorSecundario: colorSecundario ?? this.colorSecundario,
      cantidad: cantidad ?? this.cantidad,
      creadoEn: creadoEn ?? this.creadoEn,
      habilitado: habilitado ?? this.habilitado,
      habilitadoDescripcion:
          habilitadoDescripcion ?? this.habilitadoDescripcion,
    );
  }
}
