import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../widgets/show_snackbar.dart';
import '../services/usuario_service.dart';

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

  bool _isLoading = false;
  String? _errorMessage;

  late String _selectedRolId;

  static const String _adminRoleId = 'a0d38955-fa67-4751-a36b-777fcf4d8ed9';
  static const String _jugadorRoleId = 'uuid-jugador';

  @override
  void initState() {
    super.initState();
    _selectedRolId = widget.usuario?.rolId ?? _jugadorRoleId;
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

        await _usuarioService.crearUsuario(
          email: _emailCtrl.text.trim(),
          nombre: _nombreCtrl.text.trim().isEmpty
              ? 'Sin nombre'
              : _nombreCtrl.text.trim(),
          password: tempPassword,
          rolId: _selectedRolId,
        );

        if (mounted) {
          showSnackBar(
            context,
            'Usuario creado. Contraseña temporal: $tempPassword',
          );
          Navigator.pop(context, true);
        }
      } else {
        // EDITAR USUARIO EXISTENTE
        await _usuarioService.cambiarRol(widget.usuario!.id, _selectedRolId);
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      _errorMessage = e.toString();
      if (mounted) showSnackBar(context, 'Error: $_errorMessage', color: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esNuevo = widget.usuario == null;

    return Scaffold(
      appBar: AppBar(title: Text(esNuevo ? 'Nuevo Usuario' : 'Editar Usuario')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Nombre completo',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  hintText: 'email@ejemplo.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'El email es requerido';
                  if (!v.contains('@')) return 'Email inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedRolId,
                decoration: const InputDecoration(
                  labelText: 'Rol',
                  prefixIcon: Icon(Icons.badge_outlined),
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
                onChanged: (v) => setState(() => _selectedRolId = v!),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _guardar,
                icon: const Icon(Icons.save),
                label: Text(esNuevo ? 'Crear Usuario' : 'Guardar Cambios'),
                style: ElevatedButton.styleFrom(
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
}
