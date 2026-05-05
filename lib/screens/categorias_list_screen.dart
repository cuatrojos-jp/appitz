import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/categoria_service.dart';
import 'categoria_form_screen.dart';
import '../models/categorias_model.dart';

class CategoriasListScreen extends StatefulWidget {
  const CategoriasListScreen({super.key});

  @override
  State<CategoriasListScreen> createState() => _CategoriasListScreenState();
}

class _CategoriasListScreenState extends State<CategoriasListScreen> {
  final CategoriaService _categoriaService = CategoriaService();

  List<CategoriaModel> _categorias = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text('¿Eliminar la categoría "$nombre"?'),
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

    setState(() => _isLoading = true);

    try {
      await _categoriaService.eliminar(id);
      await _cargarCategorias();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Categoría eliminada')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
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
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoriaFormScreen(),
                ),
              );
              if (result == true) {
                _cargarCategorias();
              }
            },
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
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoriaFormScreen(),
                ),
              );
              if (result == true) {
                _cargarCategorias();
              }
            },
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
    final descripcion = categoria.descripcion;
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
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoriaFormScreen(
                            categoria: categoria,
                          ),
                        ),
                      );
                      if (result == true) {
                        _cargarCategorias();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: Colors.redAccent,
                    onPressed: () => _eliminarCategoria(id, nombre),
                  ),
                ],
              ),
            ],
          ),
          if (descripcion != null && descripcion.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              descripcion,
              style: TextStyle(
                color: AppTheme.mutedForegroundColor,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}