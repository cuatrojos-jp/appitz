import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/categoria_service.dart';
import 'categoria_form_screen.dart';
import '../models/categorias_model.dart';
import '../services/temporada_service.dart';
import '../widgets/show_snackbar.dart';

class CategoriasListScreen extends StatefulWidget {
  const CategoriasListScreen({super.key});

  @override
  State<CategoriasListScreen> createState() => _CategoriasListScreenState();
}

class _CategoriasListScreenState extends State<CategoriasListScreen> {
  final CategoriaService _categoriaService = CategoriaService();
  final TemporadaService _temporadaService = TemporadaService();

  List<CategoriaModel> _categorias = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _existeTemporadaProgramada = false;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
    _verificarTemporadaProgramada();
  }

  Future<void> _verificarTemporadaProgramada() async {
    try {
      await _temporadaService.obtenerPrimeraTemporadaProgramada();
      setState(() {
        _existeTemporadaProgramada = true;
      });
    } catch (e) {
      setState(() {
        _existeTemporadaProgramada = false;
      });
    }
  }

  void _navegarACrearCategoria() async {
    if (!_existeTemporadaProgramada) {
      showSnackBar(
        context,
        'No hay temporadas programadas. Crea una temporada primero.',
        color: Colors.orange,
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CategoriaFormScreen()),
    );
    if (result == true) {
      _cargarCategorias();
      _verificarTemporadaProgramada();
    }
  }

  Future<void> _cargarCategorias() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final categorias = await _categoriaService.obtenerTodasConTemporada();
      setState(() {
        _categorias = categorias;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _eliminarCategoria(String id, String nombre) async {
    // 1. Mostrar diálogo de confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text(
          '¿Estás seguro de eliminar la categoría "$nombre"?\n\n'
          '⚠️ Solo se pueden eliminar categorías de temporadas PROGRAMADAS '
          'que no tengan equipos asignados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 2. Mostrar indicador de carga
    setState(() {
      _isLoading = true;
    });

    try {
      // 3. Intentar eliminar (el service validará internamente)
      await _categoriaService.eliminar(id);

      // 4. Recargar la lista
      await _cargarCategorias();

      if (mounted) {
        showSnackBar(
          context,
          'Categoría "$nombre" eliminada correctamente',
          color: Colors.green,
        );
      }
    } catch (e) {
      // 5. Mostrar el error específico de validación
      if (mounted) {
        showSnackBar(
          context,
          'No se pudo eliminar: ${e.toString()}',
          color: Colors.red,
          duration: const Duration(seconds: 5), // Más tiempo para leer el error
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

  Future<bool> _puedeEliminarCategoria(String categoriaId) async {
    try {
      await _categoriaService.validarEliminacionCategoria(categoriaId);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColorAlt,
      appBar: AppBar(
        title: const Text('Categorías', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.backgroundColorAlt,
        elevation: 0,
        actions: [
          // Botón de agregar del AppBar
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primaryColor),
            onPressed: _navegarACrearCategoria,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : _categorias.isEmpty
          ? _buildEmptyView()
          : ListView.builder(
              itemCount: _categorias.length,
              itemBuilder: (context, index) {
                final categoria = _categorias[index];
                return _buildCategoriaCard(categoria);
              },
            ),
    );
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
            onPressed: _cargarCategorias,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.category_outlined,
            size: 64,
            color: AppTheme.mutedForegroundColor,
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay categorías registradas',
            style: TextStyle(color: AppTheme.mutedForegroundColor),
          ),

          // Botón de agregar categoría dentro de la pantalla vacia
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _navegarACrearCategoria,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text(
              'Crear nueva categoría',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriaCard(CategoriaModel categoria) {
    final nombre = categoria.nombre;
    final temporadaNombre = categoria.temporadaNombre;
    final id = categoria.id;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icono
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.category,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Nombre y temporada
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Temporada: $temporadaNombre',
                      style: const TextStyle(
                        color: AppTheme.mutedForegroundColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Botones de acción
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    color: AppTheme.primaryColor,
                    onPressed: () async {
                      final esEditable = await _temporadaService
                          .esTemporadaEditable(categoria.temporadaId);

                      if (!esEditable) {
                        showSnackBar(
                          context,
                          'No se puede editar. La temporada ya está activa, finalizada o suspendida.',
                          color: Colors.orange,
                        );
                        return;
                      }

                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CategoriaFormScreen(categoria: categoria),
                        ),
                      );
                      if (result == true) {
                        _cargarCategorias();
                      }
                    },
                  ),
                  FutureBuilder<bool>(
                    future: _puedeEliminarCategoria(categoria.id),
                    builder: (context, snapshot) {
                      final puedeEliminar = snapshot.data ?? false;
                      return IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: puedeEliminar ? Colors.redAccent : Colors.grey,
                        onPressed: puedeEliminar
                            ? () => _eliminarCategoria(
                                categoria.id,
                                categoria.nombre,
                              )
                            : null, // Deshabilitado
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
