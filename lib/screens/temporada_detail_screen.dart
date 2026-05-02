// lib/screens/temporada_detail_screen.dart
import 'package:flutter/material.dart';
import '../services/temporada_service.dart';
import '../models/temporadas_model.dart';
import '../theme/app_theme.dart';
import '../widgets/show_snackbar.dart';

class TemporadaDetailScreen extends StatefulWidget {
  final TemporadaModel temporada;

  const TemporadaDetailScreen({super.key, required this.temporada});

  @override
  State<TemporadaDetailScreen> createState() => _TemporadaDetailScreenState();
}

class _TemporadaDetailScreenState extends State<TemporadaDetailScreen> {
  late TemporadaModel _temporada;
  bool _isEditing = false;
  bool _isLoading = false;

  // Controladores para edición
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _fechaInicioController;
  late TextEditingController _fechaFinController;

  final TemporadaService _temporadaService = TemporadaService();

  @override
  void initState() {
    super.initState();
    _temporada = widget.temporada;
    _nombreController = TextEditingController(text: _temporada.nombre);
    _descripcionController = TextEditingController(text: _temporada.descripcion ?? '');
    _fechaInicioController = TextEditingController(
      text: _temporada.fechaInicio != null 
          ? _formatFecha(_temporada.fechaInicio!) 
          : '',
    );
    _fechaFinController = TextEditingController(
      text: _temporada.fechaFin != null 
          ? _formatFecha(_temporada.fechaFin!) 
          : '',
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _fechaInicioController.dispose();
    _fechaFinController.dispose();
    super.dispose();
  }

  String _formatFecha(DateTime fecha) {
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
      setState(() {
        controller.text = _formatFecha(picked);
      });
    }
  }

  Future<void> _guardar() async {
    setState(() => _isLoading = true);

    try {
      final fechaInicio = _parseFecha(_fechaInicioController.text);
      final fechaFin = _parseFecha(_fechaFinController.text);

      final temporadaActualizada = TemporadaModel(
        id: _temporada.id,
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim().isEmpty 
            ? null 
            : _descripcionController.text.trim(),
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        estadoId: _temporada.estadoId,
      );

      await _temporadaService.actualizarTemporada(temporadaActualizada);

      setState(() {
        _temporada = temporadaActualizada;
        _isEditing = false;
        _isLoading = false;
      });

      if (mounted) {
        showSnackBar(context, 'Temporada actualizada');
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        showSnackBar(context, 'Error: ${e.toString()}', color: AppTheme.errorColor);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColorAlt,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Editar Temporada' : _temporada.nombre,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.backgroundColorAlt,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            TextButton(
              onPressed: _isLoading ? null : _guardar,
              child: const Text(
                'Guardar',
                style: TextStyle(color: AppTheme.primaryColor),
              ),
            ),
        ],
      ),
      body: _isEditing ? _buildEditForm() : _buildDetailView(),
    );
  }

  // Vista estática (solo lectura)
  Widget _buildDetailView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Nombre', _temporada.nombre),
          const Divider(color: AppTheme.borderColor),
          if (_temporada.descripcion != null) ...[
            _buildDetailRow('Descripción', _temporada.descripcion!),
            const Divider(color: AppTheme.borderColor),
          ],
          if (_temporada.fechaInicio != null) ...[
            _buildDetailRow('Fecha de inicio', _formatFecha(_temporada.fechaInicio!)),
            const Divider(color: AppTheme.borderColor),
          ],
          if (_temporada.fechaFin != null) ...[
            _buildDetailRow('Fecha de fin', _formatFecha(_temporada.fechaFin!)),
            const Divider(color: AppTheme.borderColor),
          ],
          _buildDetailRow('Estado', _getEstadoNombre(_temporada.estadoId)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.mutedForegroundColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // Formulario de edición
  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nombre
          TextFormField(
            controller: _nombreController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Nombre *'),
            validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
          ),
          const SizedBox(height: 16),

          // Descripción
          TextFormField(
            controller: _descripcionController,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: _inputDecoration('Descripción'),
          ),
          const SizedBox(height: 16),

          // Fecha Inicio
          GestureDetector(
            onTap: () => _seleccionarFecha(_fechaInicioController),
            child: AbsorbPointer(
              child: TextFormField(
                controller: _fechaInicioController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Fecha de inicio', hint: 'DD/MM/YYYY'),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Fecha Fin
          GestureDetector(
            onTap: () => _seleccionarFecha(_fechaFinController),
            child: AbsorbPointer(
              child: TextFormField(
                controller: _fechaFinController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Fecha de fin', hint: 'DD/MM/YYYY'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppTheme.mutedForegroundColor),
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.mutedForegroundColor),
      filled: true,
      fillColor: AppTheme.secondaryColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
    );
  }

  String _getEstadoNombre(String estadoId) {
    const activoId = 'activo-uuid';
    const finalizadoId = 'finalizado-uuid';
    const suspendidoId = 'suspendido-uuid';
    
    if (estadoId == activoId) return 'Activo';
    if (estadoId == finalizadoId) return 'Finalizado';
    if (estadoId == suspendidoId) return 'Suspendido';
    return 'Programado';
  }
}