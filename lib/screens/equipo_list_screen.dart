// lib/screens/equipo_list_screen.dart
import 'package:flutter/material.dart';
import '../models/equipos_model.dart';
import '../services/auth_service.dart';
import '../services/equipo_service.dart';
import 'nuevo_equipo_screen.dart';
import '../widgets/confirmacion_dialog.dart';

class EquipoListScreen extends StatefulWidget {
  const EquipoListScreen({super.key});

  @override
  State<EquipoListScreen> createState() => _EquipoListScreenState();
}

class _EquipoListScreenState extends State<EquipoListScreen>
    with AutomaticKeepAliveClientMixin {
  static const String _adminRoleId = 'a0d38955-fa67-4751-a36b-777fcf4d8ed9';

  final EquipoService _service = EquipoService();
  final AuthService _authService = AuthService();
  late Future<List<EquipoModel>> _equiposFuture;

  // 🔍 PARA EL BUSCADOR
  List<EquipoModel> _todosLosEquipos = [];
  List<EquipoModel> _equiposFiltrados = [];
  bool _isSearching = false;
  bool _isAdmin = false;
  final TextEditingController _searchController = TextEditingController();

  // 🎨 COLORES
  static const Color backgroundColor = Color(0xFF1a1a1a);
  static const Color cardColor = Color(0xFF1e1e1e);
  static const Color neon = Color(0xFF00e676);
  static const Color disabledBadgeColor = Color(0xFF6F2A2A);
  static const Color enabledBadgeColor = Color(0xFF2A6F5C);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _verificarPermisos();
    _cargarEquipos();
  }

  Future<void> _verificarPermisos() async {
    final userId = _authService.getCurrentUserId();
    if (userId == null) {
      if (mounted) setState(() => _isAdmin = false);
      return;
    }

    final rolId = await _authService.getRolId(userId);
    if (mounted) {
      setState(() => _isAdmin = rolId == _adminRoleId);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _cargarEquipos() {
    _equiposFuture = _service.obtenerEquipos().then((equipos) {
      _todosLosEquipos = equipos;
      _equiposFiltrados = equipos;
      return equipos;
    });
    setState(() {});
  }

  void _recargar() {
    _cargarEquipos();
    _limpiarBusqueda();
  }

  void _limpiarBusqueda() {
    _searchController.clear();
    _isSearching = false;
    _equiposFiltrados = _todosLosEquipos;
    setState(() {});
  }

  void _filtrarEquipos(String query) {
    setState(() {
      if (query.isEmpty) {
        _equiposFiltrados = _todosLosEquipos;
        _isSearching = false;
      } else {
        _equiposFiltrados = _todosLosEquipos.where((equipo) {
          return equipo.nombre.toLowerCase().contains(query.toLowerCase());
        }).toList();
        _isSearching = true;
      }
    });
  }

  Future<void> _editarEquipo(EquipoModel equipo) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NuevoEquipoScreen(equipo: equipo)),
    );
    if (resultado == true && mounted) _recargar();
  }

  Future<void> _deshabilitarEquipo(EquipoModel equipo) async {
    final resultado = await mostrarDialogoConfirmacion(
      context: context,
      titulo: 'Deshabilitar equipo',
      contenido:
          '¿Estás seguro de deshabilitar a "${equipo.nombre}"?\n\n'
          'Un equipo deshabilitado no podrá ser seleccionado en nuevos partidos.',
      requiereRazon: true,
      hintRazon: 'Ej: Equipo suspendido por sanción, falta de jugadores, etc.',
      botonConfirmacion: 'Deshabilitar',
      colorConfirmacion: Colors.redAccent,
    );

    if (resultado == null || resultado['confirmado'] != true) return;

    final razon = resultado['razon'] as String;

    try {
      await _service.deshabilitarEquipo(equipoId: equipo.id, razon: razon);
      if (mounted) {
        _recargar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Equipo deshabilitado'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _habilitarEquipo(EquipoModel equipo) async {
    final resultado = await mostrarDialogoConfirmacion(
      context: context,
      titulo: 'Habilitar equipo',
      contenido:
          '¿Estás seguro de habilitar nuevamente a "${equipo.nombre}"?\n\n'
          'El equipo volverá a estar disponible para seleccionar en partidos.',
      requiereRazon: false,
      botonConfirmacion: 'Habilitar',
      colorConfirmacion: Colors.green,
    );

    if (resultado == null || resultado['confirmado'] != true) return;

    try {
      await _service.habilitarEquipo(equipo.id);
      if (mounted) {
        _recargar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Equipo habilitado'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _eliminarEquipo(EquipoModel equipo) async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F1115),
        title: const Text(
          '¿Eliminar equipo?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Está seguro de que desea eliminar "${equipo.nombre}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirma != true) return;

    try {
      await _service.eliminarEquipo(equipo.id);
      if (mounted) {
        _recargar();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ Equipo eliminado')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              backgroundColor: neon,
              child: const Icon(Icons.add, color: Colors.black),
              onPressed: () async {
                final resultado = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NuevoEquipoScreen()),
                );
                if (resultado == true && mounted) _recargar();
              },
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF111111), Color(0xFF1b1b1b)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 🔍 BARRA DE BÚSQUEDA (LUPA)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    onChanged: _filtrarEquipos,
                    decoration: InputDecoration(
                      hintText: 'Buscar equipo por nombre...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.search, color: neon),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.white38,
                              ),
                              onPressed: _limpiarBusqueda,
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ),

              // CONTADOR DE RESULTADOS
              if (_isSearching && _equiposFiltrados.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        '${_equiposFiltrados.length} resultado${_equiposFiltrados.length != 1 ? 's' : ''}',
                        style: const TextStyle(color: neon, fontSize: 12),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _limpiarBusqueda,
                        child: const Text(
                          'Limpiar',
                          style: TextStyle(color: neon, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_isSearching && _equiposFiltrados.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.search_off,
                        color: Colors.white38,
                        size: 60,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No se encontraron equipos con "${_searchController.text}"',
                        style: const TextStyle(color: Colors.white38),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

              // LISTA DE EQUIPOS
              Expanded(
                child: _equiposFiltrados.isEmpty && !_isSearching
                    ? FutureBuilder<List<EquipoModel>>(
                        future: _equiposFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(color: neon),
                            );
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.sports_soccer,
                                    size: 64,
                                    color: Colors.white24,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Sin equipos creados',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (_isAdmin) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Toca el + para agregar tu primer equipo',
                                      style: TextStyle(
                                        color: Colors.white30,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }
                          return _buildListaEquipos(snapshot.data!);
                        },
                      )
                    : _buildListaEquipos(_equiposFiltrados),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListaEquipos(List<EquipoModel> equipos) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ...equipos.map((equipo) => _buildCard(equipo)).toList(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCard(EquipoModel equipo) {
    Color colorPrimario = _hexToColor(equipo.colorPrincipal);
    Color colorSecundario = _hexToColor(equipo.colorSecundario);

    final bool estaDeshabilitado = !equipo.habilitado;

    return Container(
      key: ValueKey(equipo.id),
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: estaDeshabilitado
              ? Colors.redAccent.withOpacity(0.3)
              : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  gradient: LinearGradient(
                    colors: [colorPrimario, colorSecundario],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: equipo.escudoUrl != null && equipo.escudoUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image.network(
                          equipo.escudoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.expand(
                            child: Icon(
                              Icons.shield,
                              color: Colors.white30,
                              size: 40,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.expand(
                        child: Icon(
                          Icons.shield,
                          color: Colors.white30,
                          size: 40,
                        ),
                      ),
              ),
              if (estaDeshabilitado)
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    color: Colors.black.withOpacity(0.6),
                  ),
                  child: const Center(
                    child: Icon(Icons.block, color: Colors.redAccent, size: 32),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        equipo.nombre,
                        style: TextStyle(
                          color: estaDeshabilitado
                              ? Colors.white54
                              : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: estaDeshabilitado
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: estaDeshabilitado
                            ? disabledBadgeColor
                            : enabledBadgeColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        estaDeshabilitado ? 'Deshabilitado' : 'Activo',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Modalidad: ${equipo.cantidad}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                if (estaDeshabilitado && equipo.habilitadoDescripcion != null && _isAdmin)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.redAccent,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Razón: ${equipo.habilitadoDescripcion}',
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                if (_isAdmin)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: estaDeshabilitado
                                ? enabledBadgeColor
                                : disabledBadgeColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: Icon(
                            estaDeshabilitado ? Icons.play_arrow : Icons.block,
                            size: 16,
                          ),
                          label: Text(
                            estaDeshabilitado ? 'Habilitar' : 'Deshabilitar',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onPressed: () {
                            if (estaDeshabilitado) {
                              _habilitarEquipo(equipo);
                            } else {
                              _deshabilitarEquipo(equipo);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2A6F5C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text(
                            'Editar',
                            style: TextStyle(fontSize: 12),
                          ),
                          onPressed: () => _editarEquipo(equipo),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6F2A2A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.delete, size: 16),
                          label: const Text(
                            'Eliminar',
                            style: TextStyle(fontSize: 12),
                          ),
                          onPressed: () => _eliminarEquipo(equipo),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}
