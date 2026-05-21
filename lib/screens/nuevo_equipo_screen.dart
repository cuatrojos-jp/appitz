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
  String cantidad = "5v5";

  bool _isLoading = false;
  List<EquipoModel> _equiposExistentes = [];

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
      cantidad = widget.equipo!.cantidad;
    }

    _cargarEquiposExistentes();
  }

  Future<void> _cargarEquiposExistentes() async {
    _equiposExistentes = await _service.obtenerEquipos();
    setState(() {});
  }

  @override
  void dispose() {
    nombreController.dispose();
    logoController.dispose();
    super.dispose();
  }

  String? _validarNombre(String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre del equipo es requerido';
    }
    if (value.length < 3) {
      return 'Mínimo 3 caracteres';
    }
    if (value.length > 50) {
      return 'Máximo 50 caracteres';
    }

    final nombreNormalizado = value.trim().toLowerCase();

    if (editando) {
      final existe = _equiposExistentes.any(
        (equipo) =>
            equipo.id != widget.equipo!.id &&
            equipo.nombre.trim().toLowerCase() == nombreNormalizado,
      );
      if (existe) {
        return 'El nombre del equipo ya se encuentra registrado previamente, utilice uno diferente';
      }
    } else {
      final existe = _equiposExistentes.any(
        (equipo) => equipo.nombre.trim().toLowerCase() == nombreNormalizado,
      );
      if (existe) {
        return 'El nombre del equipo ya se encuentra registrado previamente, utilice uno diferente';
      }
    }

    return null;
  }

  Future<void> guardarEquipo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (editando) {
        final equipo = EquipoModel(
          id: widget.equipo!.id,
          nombre: nombreController.text.trim(),
          escudoUrl: logoController.text.trim().isEmpty
              ? null
              : logoController.text.trim(),
          colorPrincipal: _colorToHex(colorPrimario),
          colorSecundario: _colorToHex(colorSecundario),
          cantidad: cantidad,
        );
        await _service.actualizarEquipo(equipo);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '✅ Equipo actualizado exitosamente',
                style: TextStyle(fontSize: 14),
              ),
              backgroundColor: Color(0xFF34D399),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        final equipo = EquipoModel.nuevo(
          nombre: nombreController.text.trim(),
          escudoUrl: logoController.text.trim().isEmpty
              ? null
              : logoController.text.trim(),
          colorPrincipal: _colorToHex(colorPrimario),
          colorSecundario: _colorToHex(colorSecundario),
          cantidad: cantidad,
        );
        await _service.crearEquipo(equipo);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '✅ Equipo creado exitosamente',
                style: TextStyle(fontSize: 14),
              ),
              backgroundColor: Color(0xFF34D399),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Error al ${editando ? "actualizar" : "crear"} el equipo: $e',
              style: const TextStyle(fontSize: 14),
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                  Center(
                    child: Text(
                      editando ? 'Editar Equipo' : 'Crear Equipo',
                      style: const TextStyle(
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
                    decoration: _inputDecoration(
                      "Ej: Los Halcones (máx. 50 caracteres)",
                    ),
                    maxLength: 50,
                    validator: _validarNombre,
                  ),
                  const SizedBox(height: 30),

                  const Text(
                    "URL del Escudo (opcional)",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: logoController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      "https://ejemplo.com/escudo.png",
                    ),
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
                    "Modalidad de Campo *",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: cantidad,
                    style: const TextStyle(color: Colors.white),
                    dropdownColor: const Color(0xFF1A1A1E),
                    decoration: _inputDecoration("Selecciona la modalidad"),
                    items: const [
                      DropdownMenuItem(value: "5v5", child: Text("5v5")),
                      DropdownMenuItem(value: "6v6", child: Text("6v6")),
                      DropdownMenuItem(value: "7v7", child: Text("7v7")),
                      DropdownMenuItem(value: "11v11", child: Text("11v11")),
                    ],
                    onChanged: (value) => setState(() => cantidad = value!),
                    validator: (v) =>
                        v == null ? 'Selecciona una modalidad' : null,
                  ),

                  const SizedBox(height: 40),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white54,
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : guardarEquipo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF34D399),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : Text(
                                  editando
                                      ? "Actualizar Equipo"
                                      : "Guardar Equipo",
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
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
