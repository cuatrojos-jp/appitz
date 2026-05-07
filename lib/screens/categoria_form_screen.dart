import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/categorias_model.dart';
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

  String? _temporadaIdAsignada;
  String? _temporadaNombreAsignada;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _esEdicion => widget.categoria != null;

  @override
  void initState() {
    super.initState();
    _cargarTemporadaProgramada();
    
    if (_esEdicion) {
      _nombreController.text = widget.categoria!.nombre;
      _descripcionController.text = widget.categoria!.descripcion ?? '';
      _temporadaIdAsignada = widget.categoria!.temporadaId;
      _temporadaNombreAsignada = widget.categoria!.temporadaNombre;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _cargarTemporadaProgramada() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_esEdicion) {
        setState(() {
          _isLoading = false;
        });
      } else {
        final temporada = await _temporadaService.obtenerPrimeraTemporadaProgramada();
        setState(() {
          _temporadaIdAsignada = temporada.id;
          _temporadaNombreAsignada = temporada.nombre;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_esEdicion && _temporadaIdAsignada == null) {
      showSnackBar(
        context,
        'No hay temporadas programadas disponibles. Crea una temporada programada primero.',
        color: Colors.orange,
      );
      return;
    }

    final nombre = _nombreController.text.trim();
    
    if (_temporadaIdAsignada != null) {
      final existe = await _categoriaService.existeNombreEnTemporada(
        nombre: nombre,
        temporadaId: _temporadaIdAsignada!,
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
    }

    setState(() => _isSaving = true);

    try {
      final categoria = CategoriaModel(
        id: _esEdicion ? widget.categoria!.id : '',
        temporadaId: _temporadaIdAsignada!,
        temporadaNombre: _temporadaNombreAsignada ?? '',
        nombre: nombre,
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

                    // Mostrar temporada asignada (solo lectura)
                    if (_temporadaIdAsignada != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Temporada',
                                    style: TextStyle(
                                      color: AppTheme.mutedForegroundColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _esEdicion ? _temporadaNombreAsignada ?? '' : _temporadaNombreAsignada!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

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

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarTemporadaProgramada,
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
      ),
    );
  }
}