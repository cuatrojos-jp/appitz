import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/equipos_model.dart';
import '../services/equipo_service.dart';

class NuevoEquipoScreen extends StatefulWidget {
  final EquipoModel? equipo;

  const NuevoEquipoScreen({super.key, this.equipo});

  @override
  State<NuevoEquipoScreen> createState() => _NuevoEquipoScreenState();
}

class _NuevoEquipoScreenState extends State<NuevoEquipoScreen> {
  final _formKey = GlobalKey<FormState>();
  final EquipoService _service = EquipoService();

  late TextEditingController nombreController;
  late TextEditingController logoController;

  Color colorPrimario = const Color(0xFF6EE7B7);
  Color colorSecundario = const Color(0xFF1A1A1E);

  bool get editando => widget.equipo != null;

  @override
  void initState() {
    super.initState();

    nombreController = TextEditingController(text: widget.equipo?.nombre ?? '');
    logoController = TextEditingController(
      text: widget.equipo?.escudoUrl ?? '',
    );

    if (widget.equipo != null) {
      colorPrimario = _hexToColor(widget.equipo!.colorPrincipal);
      colorSecundario = _hexToColor(widget.equipo!.colorSecundario);
    }
  }

  Future<void> guardarEquipo() async {
    if (!_formKey.currentState!.validate()) return;

    final equipo = EquipoModel(
      nombre: nombreController.text.trim(),
      escudoUrl: logoController.text.trim(),
      colorPrincipal: _colorToHex(colorPrimario),
      colorSecundario: _colorToHex(colorSecundario),
    );

    if (editando) {
      await _service.actualizarEquipo(widget.equipo!.id!, equipo);
    } else {
      await _service.crearEquipo(equipo);
    }

    if (mounted) Navigator.pop(context, true);
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  String _colorToHex(Color c) {
    return '#${c.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  void _abrirPicker(Color actual, Function(Color) onSelect) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F1115),
        title: const Text(
          'Selecciona un color',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: actual,
            onColorChanged: onSelect,
            enableAlpha: false,
            labelTypes: const [],
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  backgroundColor: Colors.black,
  body: Center(
    child: Container(
      width: 550,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1115),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const Center(
                      child: Text(
                        'Crear Equipo',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    const Text(
                      "Nombre del Equipo *",
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: nombreController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration("Ej: Los Halcones"),
                      validator: (v) => v!.isEmpty ? 'Ingresa el nombre' : null,
                    ),

                    const SizedBox(height: 30),

                    Row(
                      children: [
                        Expanded(
                          child: _colorPickerBox(
                            "Color Principal",
                            colorPrimario,
                            () => _abrirPicker(
                              colorPrimario,
                              (c) => setState(() => colorPrimario = c),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _colorPickerBox(
                            "Color Secundario",
                            colorSecundario,
                            () => _abrirPicker(
                              colorSecundario,
                              (c) => setState(() => colorSecundario = c),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      "URL del Logo (opcional)",
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: logoController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        "https://ejemplo.com/logo.png",
                      ),
                    ),

                    const SizedBox(height: 40),

                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: guardarEquipo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF34D399),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Guardar Equipo",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
  }

  Widget _colorPickerBox(String label, Color color, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 55,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D23),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 55,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _colorToHex(color),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF1A1D23),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }
}
