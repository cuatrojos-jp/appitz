import 'package:flutter/material.dart';
import '../models/campos_model.dart';
import '../services/campo_service.dart';

class EditarCampoScreen extends StatefulWidget {
  final CampoFutbolModel campo;
  
  const EditarCampoScreen({super.key, required this.campo});

  @override
  State<EditarCampoScreen> createState() => _EditarCampoScreenState();
}

class _EditarCampoScreenState extends State<EditarCampoScreen> {
  static const Color backgroundColor = Color(0xFF1a1a1a);
  static const Color cardColor = Color(0xFF1e1e1e);
  static const Color inputColor = Color(0xFF2a2a2a);
  static const Color primaryColor = Color(0xFF00e676);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textMuted = Color(0xFF666666);

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _fotoUrlController = TextEditingController();
  final CampoService _service = CampoService();

  String _modalidadSeleccionada = '5v5';
  final List<String> _modalidades = ['5v5', '6v6', '7v7', '11v11'];

  bool _disponible = true;
  bool _isLoading = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nombreController.text = widget.campo.nombre;
    _direccionController.text = widget.campo.direccion;
    _modalidadSeleccionada = widget.campo.cantidad;
    _disponible = widget.campo.disponible;
    _fotoUrlController.text = widget.campo.fotoUrl ?? '';
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _fotoUrlController.dispose();
    super.dispose();
  }

  Future<void> _actualizarCampo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final campoActualizado = CampoFutbolModel(
        id: widget.campo.id,
        nombre: _nombreController.text.trim(),
        direccion: _direccionController.text.trim(),
        cantidad: _modalidadSeleccionada,
        disponible: _disponible,
        fotoUrl: _fotoUrlController.text.trim().isEmpty
            ? null
            : _fotoUrlController.text.trim(),
      );

      await _service.actualizarCampo(campoActualizado);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Campo actualizado exitosamente'),
            backgroundColor: primaryColor,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.close, color: textMuted),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Editar Campo',
              style: TextStyle(
                color: textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Actualiza la información del campo',
              style: TextStyle(
                color: textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // NOMBRE - Máximo 30 caracteres
              _buildLabel('Nombre del Campo', isRequired: true),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _nombreController,
                hintText: 'Ej: Campo Central (máx. 30 caracteres)',
                icon: null,
                maxLength: 30,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre es requerido';
                  }
                  if (value.length < 3) {
                    return 'Mínimo 3 caracteres';
                  }
                  if (value.length > 30) {
                    return 'Máximo 30 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // DIRECCIÓN - Máximo 100, mínimo 10
              _buildLabel('Dirección', isRequired: true),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _direccionController,
                hintText: 'Ej: Av. Principal 123, Ciudad (máx. 100 caracteres)',
                icon: Icons.location_on_outlined,
                maxLength: 100,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La dirección es requerida';
                  }
                  if (value.length < 10) {
                    return 'Mínimo 10 caracteres';
                  }
                  if (value.length > 100) {
                    return 'Máximo 100 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // MODALIDAD
              _buildLabel('Modalidad del Campo', isRequired: true),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: inputColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.start,
                  children: _modalidades.map((modalidad) {
                    final isSelected = _modalidadSeleccionada == modalidad;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _modalidadSeleccionada = modalidad;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? primaryColor
                                : textMuted,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          modalidad,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF0a0a0a)
                                : textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // FOTO URL - Máximo 100 caracteres
              _buildLabel('URL de la Foto'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _fotoUrlController,
                hintText: 'https://ejemplo.com/foto.jpg (máx. 100 caracteres)',
                icon: Icons.image_outlined,
                maxLength: 100,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!value.startsWith('http')) {
                      return 'URL debe comenzar con http o https';
                    }
                    if (value.length < 10) {
                      return 'Mínimo 10 caracteres';
                    }
                    if (value.length > 100) {
                      return 'Máximo 100 caracteres';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // DISPONIBILIDAD
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: inputColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Campo Disponible',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Disponible para reservas',
                            style: TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _disponible = !_disponible;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 52,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _disponible
                              ? primaryColor
                              : const Color(0xFF444444),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Align(
                          alignment: _disponible
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x3F000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // BOTONES
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: inputColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text(
                            'Cancelar',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _isLoading ? null : _actualizarCampo,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: _isLoading
                              ? primaryColor.withOpacity(0.6)
                              : primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                      Color(0xFF0a0a0a),
                                    ),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.save,
                                      color: Color(0xFF0a0a0a),
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Actualizar Campo',
                                      style: TextStyle(
                                        color: Color(0xFF0a0a0a),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
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
    );
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return Text.rich(
      TextSpan(
        text: text,
        style: const TextStyle(
          color: textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        children: isRequired
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    IconData? icon,
    String? Function(String?)? validator,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: inputColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            const SizedBox(width: 14),
            Icon(
              icon,
              color: textMuted,
              size: 18,
            ),
            const SizedBox(width: 10),
          ] else ...[
            const SizedBox(width: 16),
          ],
          Expanded(
            child: TextFormField(
              controller: controller,
              style: const TextStyle(
                color: textPrimary,
                fontSize: 15,
              ),
              maxLength: maxLength,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: textMuted,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
              ),
              validator: validator,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}