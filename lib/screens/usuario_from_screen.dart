import 'package:flutter/material.dart';
import '../models/Usuario.dart';
//import '../theme/app_theme.dart';

class UsuarioFormScreen extends StatefulWidget {
  final Usuario? usuario;
  final Future<void> Function(Usuario) onGuardar;

  const UsuarioFormScreen({
    super.key,
    this.usuario,
    required this.onGuardar,
  });

  @override
  State<UsuarioFormScreen> createState() => _UsuarioFormScreenState();
}

class _UsuarioFormScreenState extends State<UsuarioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nombreCtrl = TextEditingController(text: widget.usuario?.nombre ?? '');
  late final _emailCtrl = TextEditingController(text: widget.usuario?.email ?? '');
  late RolUsuario _rol = widget.usuario?.rol ?? RolUsuario.jugador;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final usuario = Usuario(
  id: widget.usuario?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
  email: _emailCtrl.text.trim(),
  nombre: _nombreCtrl.text.trim().isEmpty ? null : _nombreCtrl.text.trim(),
  rol: _rol,
  activo: widget.usuario?.activo ?? true,
  jugadorId: widget.usuario?.jugadorId, 
  creadoEn: widget.usuario?.creadoEn ?? DateTime.now(), // ← Requerido
  actualizadoEn: DateTime.now(), // ← Requerido
);

    await widget.onGuardar(usuario);
    if (mounted) Navigator.pop(context, usuario);
  }

  @override
  Widget build(BuildContext context) {
    final esNuevo = widget.usuario == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(esNuevo ? 'Nuevo Usuario' : 'Editar Usuario'),
      ),
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
                  if (v == null || v.trim().isEmpty) return 'El email es requerido';
                  if (!v.contains('@')) return 'Email inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<RolUsuario>(
  initialValue: _rol,
  decoration: const InputDecoration(
    labelText: 'Rol',
    prefixIcon: Icon(Icons.badge_outlined),
  ),
  items: [
    DropdownMenuItem(value: RolUsuario.jugador, child: const Text('Jugador')),
    DropdownMenuItem(value: RolUsuario.coordinador, child: const Text('Coordinador')),
    DropdownMenuItem(value: RolUsuario.admin, child: const Text('Admin')),
  ],
  onChanged: (v) => setState(() => _rol = v!),
),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _guardar,
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