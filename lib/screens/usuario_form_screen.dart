// lib/screens/usuario_form_screen.dart
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/jugador_model.dart';
import '../widgets/show_snackbar.dart';
import '../services/usuario_service.dart';
import '../services/jugador_service.dart';
import '../theme/app_theme.dart';

class UsuarioFormScreen extends StatefulWidget {
  final UserModel? usuario;
  final Future<void> Function(UserModel) onGuardar;

  const UsuarioFormScreen({super.key, this.usuario, required this.onGuardar});

  @override
  State<UsuarioFormScreen> createState() => _UsuarioFormScreenState();
}

class _UsuarioFormScreenState extends State<UsuarioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nombreCtrl = TextEditingController(
    text: widget.usuario?.nombre ?? '',
  );
  late final _emailCtrl = TextEditingController(
    text: widget.usuario?.email ?? '',
  );
  final UsuarioService _usuarioService = UsuarioService();
  final JugadorService _jugadorService = JugadorService();

  bool _isLoading = false;
  bool _cargandoJugadores = true;
  List<JugadorModel> _jugadoresDisponibles = [];
  List<JugadorModel> _todosLosJugadores = [];
  String? _selectedJugadorId;
  bool _cargandoJugadorActual = true;

  late String _selectedRolId;

  static const String _adminRoleId = 'a0d38955-fa67-4751-a36b-777fcf4d8ed9';
  static const String _jugadorRoleId = '6c3d23ab-6228-44b8-8216-6f25ff1b7a4f';

  @override
  void initState() {
    super.initState();
    final rolId = widget.usuario?.rolId;
    _selectedRolId = (rolId == null || rolId.isEmpty) ? _jugadorRoleId : rolId;
    _cargarJugadores();
    if (widget.usuario != null) {
      _cargarJugadorActual();
    }
  }

  Future<void> _cargarJugadores() async {
    setState(() => _cargandoJugadores = true);
    try {
      final todos = await _jugadorService.obtenerJugadores();
      setState(() {
        _todosLosJugadores = todos;
        _cargandoJugadores = false;
      });
    } catch (e) {
      print('Error al cargar jugadores: $e');
      setState(() => _cargandoJugadores = false);
    }
  }

  Future<void> _cargarJugadorActual() async {
    setState(() => _cargandoJugadorActual = true);
    try {
      final jugador = await _usuarioService.obtenerJugadorPorUsuarioId(
        widget.usuario!.id,
      );
      setState(() {
        _selectedJugadorId = jugador?.id;
        _cargandoJugadorActual = false;
      });
    } catch (e) {
      print('Error al cargar jugador actual: $e');
      setState(() => _cargandoJugadorActual = false);
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.usuario == null) {
        const tempPassword = 'Temporal123!';

        // Crear usuario
        await _usuarioService.crearUsuarioPorCoordinador(
          email: _emailCtrl.text.trim(),
          nombre: _nombreCtrl.text.trim().isEmpty
              ? 'Sin nombre'
              : _nombreCtrl.text.trim(),
          password: tempPassword,
          rolId: _selectedRolId,
        );

        if (_selectedJugadorId != null && _selectedJugadorId!.isNotEmpty) {
          await _usuarioService.vincularJugadorAUsuario(
            usuarioEmail: _emailCtrl.text.trim(),
            jugadorId: _selectedJugadorId!,
          );
        }

        if (mounted) {
          setState(() => _isLoading = false);
          showSnackBar(
            context,
            'Usuario creado. Contraseña temporal: $tempPassword',
          );
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.pop(context, true);
          }
        }
      } else {
        await _usuarioService.editarUsuario(
          usuarioId: widget.usuario!.id,
          nuevoRolId: _selectedRolId,
          nuevoNombre: _nombreCtrl.text.trim().isEmpty
              ? 'Sin nombre'
              : _nombreCtrl.text.trim(),
        );

        final jugadorActual = await _usuarioService.obtenerJugadorPorUsuarioId(
          widget.usuario!.id,
        );
        final jugadorActualId = jugadorActual?.id;

        if (_selectedJugadorId != jugadorActualId) {
          if (_selectedJugadorId != null && _selectedJugadorId!.isNotEmpty) {
            // Vincular nuevo jugador
            await _usuarioService.vincularJugadorAUsuario(
              usuarioId: widget.usuario!.id,
              jugadorId: _selectedJugadorId!,
            );
          } else if (jugadorActualId != null) {
            // Desvincular jugador actual
            await _usuarioService.desvincularJugador(widget.usuario!.id);
          }
        }

        if (mounted) {
          setState(() => _isLoading = false);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pop(context, true);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showSnackBar(context, 'Error: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final esNuevo = widget.usuario == null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColorAlt,
      appBar: AppBar(
        title: Text(
          esNuevo ? 'Nuevo Usuario' : 'Editar Usuario',
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
            onPressed: _isLoading ? null : _guardar,
            child: Text(
              'Guardar',
              style: TextStyle(
                color: _isLoading ? Colors.grey : AppTheme.primaryColor,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Campo Nombre
              TextFormField(
                controller: _nombreCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  labelStyle: const TextStyle(
                    color: AppTheme.mutedForegroundColor,
                  ),
                  hintText: 'Nombre completo',
                  hintStyle: const TextStyle(
                    color: AppTheme.mutedForegroundColor,
                  ),
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: AppTheme.mutedForegroundColor,
                  ),
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
                    borderSide: const BorderSide(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Campo Email (solo en creación)
              if (esNuevo) ...[
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    labelStyle: const TextStyle(
                      color: AppTheme.mutedForegroundColor,
                    ),
                    hintText: 'email@ejemplo.com',
                    hintStyle: const TextStyle(
                      color: AppTheme.mutedForegroundColor,
                    ),
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: AppTheme.mutedForegroundColor,
                    ),
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
                      borderSide: const BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'El email es requerido';
                    if (!v.contains('@')) return 'Email inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Dropdown Rol
              DropdownButtonFormField<String>(
                value: (_selectedRolId.isEmpty || _selectedRolId == '')
                    ? null
                    : _selectedRolId,
                style: const TextStyle(color: Colors.white),
                dropdownColor: AppTheme.cardColor,
                decoration: InputDecoration(
                  labelText: 'Rol',
                  labelStyle: const TextStyle(
                    color: AppTheme.mutedForegroundColor,
                  ),
                  prefixIcon: const Icon(
                    Icons.badge_outlined,
                    color: AppTheme.mutedForegroundColor,
                  ),
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
                    borderSide: const BorderSide(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: _jugadorRoleId,
                    child: const Text('Jugador'),
                  ),
                  DropdownMenuItem(
                    value: _adminRoleId,
                    child: const Text('Coordinador'),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedRolId = v ?? ''),
              ),
              const SizedBox(height: 16),

              // Dropdown: Asociar Jugador (opcional)
              _buildJugadorDropdown(),
              const SizedBox(height: 32),

              // Botón Guardar
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _guardar,
                icon: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(esNuevo ? 'Crear Usuario' : 'Guardar Cambios'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJugadorDropdown() {
    if (_cargandoJugadorActual && widget.usuario != null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Asociar a Jugador (opcional)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        _cargandoJugadores
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : DropdownButtonFormField<String>(
                initialValue: _selectedJugadorId,
                isExpanded: true,
                hint: const Text(
                  'Selecciona un jugador',
                  style: TextStyle(color: AppTheme.mutedForegroundColor),
                ),
                style: const TextStyle(color: Colors.white),
                dropdownColor: AppTheme.cardColor,
                decoration: InputDecoration(
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
                    borderSide: const BorderSide(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Sin asociar'),
                  ),
                  ..._todosLosJugadores.map((jugador) {
                    return DropdownMenuItem(
                      value: jugador.id,
                      child: Text(jugador.nombreCompleto),
                    );
                  }),
                ],
                onChanged: (value) =>
                    setState(() => _selectedJugadorId = value),
              ),
      ],
    );
  }
}
