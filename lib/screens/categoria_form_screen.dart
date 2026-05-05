import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/categorias_model.dart';
import '../models/temporadas_model.dart';
import '../services/categoria_service.dart';
import '../services/temporada_service.dart';
import '../widgets/show_snackbar.dart';
import '../utils/string_utils.dart';

class CategoriaFormScreen extends StatefulWidget {
  final CategoriaModel? categoria;

  const CategoriaFormScreen({super.key, this.categoria});

  @override
  State<CategoriaFormScreen> createState() => _CategoriaFormScreenState();
}

class _CategoriaFormScreenState extends State<CategoriaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();

  final CategoriaService _categoriaService = CategoriaService();
  final TemporadaService _temporadaService = TemporadaService();

  List<TemporadaModel> _temporadas = [];
  String? _selectedTemporadaId;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _esEdicion => widget.categoria != null;

  @override
  void initState() {
    super.initState();
    _cargarTemporadas();

    if (_esEdicion) {
      _nombreController.text = widget.categoria!.nombre;
      _descripcionController.text = widget.categoria!.descripcion ?? '';
      _selectedTemporadaId = widget.categoria!.temporadaId;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _cargarTemporadas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final temporadas = await _temporadaService
          .obtenerTemporadasActivasYProgramadas();
      setState(() {
        _temporadas = temporadas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTemporadaId == null) {
      showSnackBar(context, 'Selecciona una temporada');
      return;
    }

    final nombre = _nombreController.text.trim();
    final existe = await _categoriaService.existeNombreEnTemporada(
      nombre: nombre,
      temporadaId: _selectedTemporadaId!,
      excludeId: _esEdicion ? widget.categoria!.id : null,
    );

    if (existe) {
      showSnackBar(
        context,
        'Ya existe una categoría con este nombre en la temporada seleccionada',
        color: Colors.redAccent,
        textColor: Colors.white,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final categoria = CategoriaModel(
        id: _esEdicion ? widget.categoria!.id : '',
        temporadaId: _selectedTemporadaId!,
        temporadaNombre: '',
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim().isEmpty
            ? null
            : _descripcionController.text.trim(),
      );

      if (_esEdicion) {
        await _categoriaService.actualizar(categoria);
        showSnackBar(
          context,
          'Categoría actualizada',
          color: Colors.greenAccent,
          textColor: Colors.black,
        );
      } else {
        await _categoriaService.crear(categoria);
        showSnackBar(
          context,
          'Categoría creada',
          color: Colors.greenAccent,
          textColor: Colors.black,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        showSnackBar(
          context,
          'Error: ${e.toString()}',
          color: AppTheme.errorColor,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColorAlt,
      appBar: AppBar(
        title: Text(
          _esEdicion ? 'Editar Categoría' : 'Nueva Categoría',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.backgroundColorAlt,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _guardar,
            child: Text(
              'Guardar',
              style: TextStyle(
                color: _isSaving ? Colors.grey : AppTheme.primaryColor,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Campo: Nombre
                    TextFormField(
                      controller: _nombreController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Nombre *',
                        labelStyle: const TextStyle(
                          color: AppTheme.mutedForegroundColor,
                        ),
                        filled: true,
                        fillColor: AppTheme.secondaryColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.borderColor,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.borderColor,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'El nombre es requerido'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Dropdown: Temporada
                    DropdownButtonFormField<String>(
                      value: _selectedTemporadaId,
                      isExpanded: true,
                      style: const TextStyle(color: Colors.white),
                      dropdownColor: AppTheme.cardColor,
                      decoration: InputDecoration(
                        labelText: 'Temporada *',
                        labelStyle: const TextStyle(
                          color: AppTheme.mutedForegroundColor,
                        ),
                        filled: true,
                        fillColor: AppTheme.secondaryColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.borderColor,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.borderColor,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                      items: _temporadas.map((t) {
                        return DropdownMenuItem(
                          value: t.id,
                          child: Text(t.nombre),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedTemporadaId = value),
                      validator: (v) =>
                          v == null ? 'Selecciona una temporada' : null,
                    ),
                    const SizedBox(height: 16),

                    // Campo: Descripción (opcional)
                    TextFormField(
                      controller: _descripcionController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Descripción',
                        labelStyle: const TextStyle(
                          color: AppTheme.mutedForegroundColor,
                        ),
                        filled: true,
                        fillColor: AppTheme.secondaryColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.borderColor,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.borderColor,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // En CategoriaFormScreen, agregar método de validación

  Future<String?> _validarNombreUnico(String? value) async {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es requerido';
    }

    final nombreNormalizado = StringUtils.normalize(value);
    if (nombreNormalizado.isEmpty) {
      return 'Nombre inválido';
    }

    // Verificar si ya existe otra categoría con el mismo nombre en esta temporada
    final existe = await _categoriaService.existeNombreEnTemporada(
      nombre: value,
      temporadaId: _selectedTemporadaId ?? '',
      excludeId: _esEdicion ? widget.categoria!.id : null,
    );

    if (existe) {
      return 'Ya existe una categoría con este nombre en la temporada seleccionada';
    }

    return null;
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _cargarTemporadas,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text(
              'Reintentar',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
