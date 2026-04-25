import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../widgets/show_snackbar.dart';
import '../services/usuario_service.dart';
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

  bool _isLoading = false;

  late String _selectedRolId;

  static const String _adminRoleId = 'a0d38955-fa67-4751-a36b-777fcf4d8ed9';
  static const String _jugadorRoleId = '6c3d23ab-6228-44b8-8216-6f25ff1b7a4f';

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

        await _usuarioService.crearUsuarioPorCoordinador(
          email: _emailCtrl.text.trim(),
          nombre: _nombreCtrl.text.trim().isEmpty ? 'Sin nombre' : _nombreCtrl.text.trim(),
          password: tempPassword,
          rolId: _selectedRolId,
        );

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
        await _usuarioService.cambiarRol(widget.usuario!.id, _selectedRolId);
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
                  labelStyle: const TextStyle(color: AppTheme.mutedForegroundColor),
                  hintText: 'Nombre completo',
                  hintStyle: const TextStyle(color: AppTheme.mutedForegroundColor),
                  prefixIcon: const Icon(Icons.person_outline, color: AppTheme.mutedForegroundColor),
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
                ),
              ),
              const SizedBox(height: 16),

              // Campo Email
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Correo electrónico',
                  labelStyle: const TextStyle(color: AppTheme.mutedForegroundColor),
                  hintText: 'email@ejemplo.com',
                  hintStyle: const TextStyle(color: AppTheme.mutedForegroundColor),
                  prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.mutedForegroundColor),
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
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'El email es requerido';
                  if (!v.contains('@')) return 'Email inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Dropdown Rol
              DropdownButtonFormField<String>(
                value: _selectedRolId,
                style: const TextStyle(color: Colors.white),
                dropdownColor: AppTheme.cardColor,
                decoration: InputDecoration(
                  labelText: 'Rol',
                  labelStyle: const TextStyle(color: AppTheme.mutedForegroundColor),
                  prefixIcon: const Icon(Icons.badge_outlined, color: AppTheme.mutedForegroundColor),
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

              // Botón Guardar
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _guardar,
                icon: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
}