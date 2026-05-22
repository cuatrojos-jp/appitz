// lib/screens/jugadores_list_screen.dart
import 'package:flutter/material.dart';
import '../services/jugador_service.dart';
import '../services/auth_service.dart';
import '../services/equipo_service.dart'; // ← AGREGAR ESTE IMPORT
import '../models/jugador_model.dart';
import '../models/equipos_model.dart'; // ← AGREGAR ESTE IMPORT
import '../theme/app_theme.dart';
import '../widgets/jugador_list_tile.dart';
import '../widgets/loading_widget.dart';
import 'jugador_form_screen.dart';

class JugadoresListScreen extends StatefulWidget {
  const JugadoresListScreen({super.key});

  @override
  State<JugadoresListScreen> createState() => _JugadoresListScreenState();
}

class _JugadoresListScreenState extends State<JugadoresListScreen> {
  final JugadorService _jugadorService = JugadorService();
  final AuthService _authService = AuthService();
  final EquipoService _equipoService = EquipoService(); // ← AGREGAR
  
  List<JugadorModel> _jugadores = [];
  Map<String, String> _equiposMap = {}; // ← AGREGAR
  bool _isLoading = true;
  String? _errorMessage;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _verificarPermisos();
    _cargarDatos(); // ← CAMBIAR: usar _cargarDatos en lugar de solo _cargarJugadores
  }

  Future<void> _verificarPermisos() async {
    final userId = _authService.getCurrentUserId();
    if (userId != null) {
      final rolId = await _authService.getPermisos(userId);
      setState(() {
        _isAdmin = rolId != null;
      });
    }
  }

  // ← AGREGAR ESTE MÉTODO
  Future<void> _cargarDatos() async {
    await Future.wait([
      _cargarJugadores(),
      _cargarEquiposMap(),
    ]);
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

  // ← AGREGAR ESTE MÉTODO
  Future<void> _cargarEquiposMap() async {
    try {
      final equipos = await _equipoService.obtenerEquipos();
      setState(() {
        _equiposMap = {for (var e in equipos) e.id: e.nombre};
      });
    } catch (e) {
      print('Error cargando equipos: $e');
    }
  }

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
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const JugadorFormScreen()),
    );
    
    if (result == true) {
      await _cargarDatos();
    }
  }

  void _navegarAEditar(JugadorModel jugador) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => JugadorFormScreen(jugador: jugador)),
    );
    
    if (result == true) {
      await _cargarDatos();
    }
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
                  onRetry: _cargarDatos,
                )
              : _jugadores.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: _jugadores.length,
                      itemBuilder: (context, index) {
                        final jugador = _jugadores[index];
                        return JugadorListTile(
                          jugador: jugador,
                          equiposMap: _equiposMap, // ← PASAR equiposMap
                          onTap: () => _navegarAEditar(jugador),
                          onDelete: _isAdmin
                              ? () => _eliminarJugador(jugador.id!, jugador.nombreCompleto)
                              : null,
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navegarAAgregar,
        backgroundColor: AppTheme.focusedLabelColor,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay jugadores registrados',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _navegarAAgregar,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.buttonColor,
              foregroundColor: AppTheme.buttonTextColor,
            ),
            child: const Text('Agregar primer jugador'),
          ),
        ],
      ),
    );
  }
}

// Widget de error (si no lo tienes)
class CustomErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const CustomErrorWidget({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}