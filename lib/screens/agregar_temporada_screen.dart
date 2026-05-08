import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/temporada_service.dart';
import '../widgets/show_snackbar.dart';
import '../models/temporadas_model.dart';

class AgregarTemporadaScreen extends StatefulWidget {
  final TemporadaModel? temporada;
  const AgregarTemporadaScreen({super.key, this.temporada});

  @override
  State<AgregarTemporadaScreen> createState() => _AgregarTemporadaScreenState();
}

class _AgregarTemporadaScreenState extends State<AgregarTemporadaScreen> {
  final TemporadaService _temporadaService = TemporadaService();

  // Controladores
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _fechaInicioController = TextEditingController();
  final _fechaFinController = TextEditingController();

  bool _isSaving = false;
  bool get _esEdicion => widget.temporada != null;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      _nombreController.text = widget.temporada!.nombre;
      _descripcionController.text = widget.temporada!.descripcion ?? '';
      if (widget.temporada!.fechaInicio != null) {
        _fechaInicioController.text = _formatearFecha(
          widget.temporada!.fechaInicio!,
        );
      }
      if (widget.temporada!.fechaFin != null) {
        _fechaFinController.text = _formatearFecha(widget.temporada!.fechaFin!);
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _fechaInicioController.dispose();
    _fechaFinController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.black,
              surface: AppTheme.backgroundColorAlt,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.text = _formatearFecha(picked);
    }
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  DateTime? _parseFecha(String fechaStr) {
    if (fechaStr.isEmpty) return null;
    final partes = fechaStr.split('/');
    if (partes.length != 3) return null;
    return DateTime(
      int.parse(partes[2]),
      int.parse(partes[1]),
      int.parse(partes[0]),
    );
  }

  Future<void> _guardar() async {
    if (_nombreController.text.trim().isEmpty) {
      showSnackBar(context, 'El nombre es requerido', color: Colors.red);
      return;
    }

    final fechaInicio = _fechaInicioController.text.isNotEmpty
        ? _parseFecha(_fechaInicioController.text)
        : null;
    final fechaFin = _fechaFinController.text.isNotEmpty
        ? _parseFecha(_fechaFinController.text)
        : null;

    if (fechaInicio != null &&
        fechaFin != null &&
        fechaFin.isBefore(fechaInicio)) {
      showSnackBar(
        context,
        'La fecha de cierre debe ser posterior a la de inicio',
        color: Colors.red,
      );

      final existeActiva = await _temporadaService.existeTemporadaActivaOProgramada(
        excludeId: _esEdicion ? widget.temporada?.id : null,
      );

      if (existeActiva) {
        showSnackBar(
          context,
          'Ya existe una temporada activa o programada. No puedes crear otra',
          color: Colors.orange,
        );
      }

      return;
    }

    setState(() => _isSaving = true);

    try {
      if (_esEdicion) {
        final temporadaActualizada = TemporadaModel(
          id: widget.temporada!.id,
          nombre: _nombreController.text.trim(),
          descripcion: _descripcionController.text.trim().isEmpty
              ? null
              : _descripcionController.text.trim(),
          fechaInicio: fechaInicio,
          fechaFin: fechaFin,
          estadoId: widget.temporada!.estadoId,
        );
        await _temporadaService.actualizarTemporada(temporadaActualizada);
        showSnackBar(context, 'Temporada actualizada', color: Colors.green);
      } else {
        await _temporadaService.crearTemporada(
          nombre: _nombreController.text.trim(),
          descripcion: _descripcionController.text.trim().isEmpty
              ? null
              : _descripcionController.text.trim(),
          fechaInicio: fechaInicio,
          fechaFin: fechaFin,
        );
        showSnackBar(
          context,
          'Temporada creada exitosamente',
          color: Colors.green,
        );
      }
      Navigator.pop(context, true);
    } catch (e) {
      showSnackBar(context, 'Error: ${e.toString()}', color: Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColorAlt,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header compacto
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: AppTheme.primaryColor,
                        size: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _esEdicion ? 'Editar temporada' : 'Nueva temporada',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _esEdicion
                              ? 'Modifica los datos de la temporada'
                              : 'Completa los datos de la temporada',
                          style: TextStyle(
                            color: AppTheme.mutedForegroundColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Formulario
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre
                    _buildLabel('Nombre de la temporada', isRequired: true),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _nombreController,
                      hintText: 'Ej: Apertura 2025',
                      icon: Icons.emoji_events_outlined,
                    ),

                    const SizedBox(height: 16),

                    // Descripción
                    _buildLabel('Descripción'),
                    const SizedBox(height: 6),
                    _buildTextArea(
                      controller: _descripcionController,
                      hintText: 'Describe detalles de la temporada...',
                    ),

                    const SizedBox(height: 16),

                    // Fechas en row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Fecha inicio', isRequired: false),
                              const SizedBox(height: 6),
                              _buildDateField(
                                controller: _fechaInicioController,
                                hintText: 'DD/MM/YYYY',
                                icon: Icons.calendar_today_outlined,
                                onTap: () =>
                                    _seleccionarFecha(_fechaInicioController),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Fecha cierre', isRequired: false),
                              const SizedBox(height: 6),
                              _buildDateField(
                                controller: _fechaFinController,
                                hintText: 'DD/MM/YYYY',
                                icon: Icons.event_outlined,
                                onTap: () =>
                                    _seleccionarFecha(_fechaFinController),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Botones
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.borderColor),
                              ),
                              child: const Center(
                                child: Text(
                                  'Cancelar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: _isSaving ? null : _guardar,
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isSaving)
                                    const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Color(0xFF0F0F11),
                                            ),
                                      ),
                                    )
                                  else ...[
                                    const Icon(
                                      Icons.save_outlined,
                                      color: Color(0xFF0F0F11),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Guardar',
                                      style: TextStyle(
                                        color: Color(0xFF0F0F11),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        children: isRequired
            ? [
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppTheme.primaryColor),
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(icon, color: AppTheme.mutedForegroundColor, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: AppTheme.mutedForegroundColor,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildTextArea({
    required TextEditingController controller,
    required String hintText,
  }) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: TextField(
        controller: controller,
        maxLines: 3,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: AppTheme.mutedForegroundColor,
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            const SizedBox(width: 10),
            Icon(icon, color: AppTheme.mutedForegroundColor, size: 14),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                enabled: false,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: const TextStyle(
                    color: AppTheme.mutedForegroundColor,
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
