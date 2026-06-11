import 'package:flutter/material.dart';
import '../services/jugador_service.dart';
import '../services/auth_service.dart';
import '../models/jugador_model.dart';
import '../theme/app_theme.dart';
import '../widgets/jugador_list_tile.dart';
import '../widgets/loading_widget.dart';
import 'jugador_form_screen.dart';
import 'perfil_jugador_screen.dart';
//import '../services/equipo_service.dart';

class JugadoresListScreen extends StatefulWidget {
  const JugadoresListScreen({super.key});

  @override
  State<JugadoresListScreen> createState() => _JugadoresListScreenState();
}

class _JugadoresListScreenState extends State<JugadoresListScreen> {
  static const String _adminRoleId = 'a0d38955-fa67-4751-a36b-777fcf4d8ed9';

  final JugadorService _jugadorService = JugadorService();
  final AuthService _authService = AuthService();
  //final EquipoService _equipoService = EquipoService();

  List<JugadorModel> _jugadores = [];
  //Map<String, String> _equiposMap = {};
  bool _isLoading = true;
  String? _errorMessage;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _verificarPermisos();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    await _cargarJugadores();
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

  Future<void> _cargarJugadores() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final jugadores = await _jugadorService.obtenerJugadores();
      setState(() {
        _jugadores = jugadores;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar jugadores: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Future<void> _cargarEquiposMap() async {
  //   try {
  //     final equipos = await _equipoService.obtenerEquipos();
  //     setState(() {
  //       _equiposMap = {for (var e in equipos) e.id: e.nombre};
  //     });
  //   } catch (e) {
  //     print('Error cargando equipos: $e');
  //     _equiposMap = {};
  //   }
  // }

  Future<void> _eliminarJugador(String id, String nombre) async {
    setState(() => _isLoading = true);

    try {
      await _jugadorService.eliminarJugador(id);
      await _cargarJugadores();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$nombre eliminado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _navegarAAgregar() async {
    if (!_isAdmin) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const JugadorFormScreen()),
    );

    if (result == true) {
      await _cargarJugadores();
    }
  }

  void _navegarAEditar(JugadorModel jugador) async {
    if (!_isAdmin) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JugadorFormScreen(jugador: jugador),
      ),
    );
    if (result == true) {
      await _cargarDatos(); // recarga la lista después de editar
    }
  }

  void _navegarAlPerfil(JugadorModel jugador) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PerfilJugadorScreen(jugadorId: jugador.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Jugadores",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.titleTextColor,
          ),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.add, color: AppTheme.titleTextColor),
              onPressed: _navegarAAgregar,
              tooltip: 'Agregar jugador',
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _errorMessage != null
          ? CustomErrorWidget(
              message: _errorMessage!,
              onRetry: _cargarJugadores,
            )
          : _jugadores.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              itemCount: _jugadores.length,
              itemBuilder: (context, index) {
                final jugador = _jugadores[index];
                return JugadorListTile(
                  jugador: jugador,
                  onTap: () => _navegarAlPerfil(jugador),
                  onEdit: _isAdmin ? () => _navegarAEditar(jugador) : null,
                  onDelete: _isAdmin
                      ? () => _eliminarJugador(
                          jugador.id!,
                          jugador.nombreCompleto,
                        )
                      : null,
                );
              },
            ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: _navegarAAgregar,
              backgroundColor: AppTheme.focusedLabelColor,
              child: const Icon(Icons.add, color: Colors.black),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No hay jugadores registrados',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 24),
          if (_isAdmin)
            ElevatedButton(
              onPressed: _navegarAAgregar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.buttonColor,
                foregroundColor: AppTheme.buttonTextColor,
              ),
              child: const Text('Agregar primer jugador'),
            )
          else
            const Text(
              'Solo los administradores pueden crear jugadores.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}
