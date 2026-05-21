// lib/screens/configuracion_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../widgets/show_snackbar.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();

  bool _notificacionesActivas = true;
  bool _isLoading = true;
  String? _usuarioId;

  @override
  void initState() {
    super.initState();
    _cargarEstado();
  }

  Future<void> _cargarEstado() async {
    _usuarioId = await _authService.getUsuarioId();
    final activas = await _notificationService.getNotificacionesActivas();
    setState(() {
      _notificacionesActivas = activas;
      _isLoading = false;
    });
  }

  Future<void> _toggleNotificaciones(bool valor) async {
    if (_usuarioId == null) return;
    setState(() => _isLoading = true);

    try {
      if (valor) {
        await _notificationService.activarNotificaciones(_usuarioId!);
      } else {
        await _notificationService.desactivarNotificaciones(_usuarioId!);
      }
      setState(() => _notificacionesActivas = valor);
      if (mounted) {
        showSnackBar(
          context,
          valor ? 'Notificaciones activadas' : 'Notificaciones desactivadas',
          color: Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error: ${e.toString()}', color: Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColorAlt,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColorAlt,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: const Text(
          'Configuración',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              children: [
                // Sección notificaciones
                const Text(
                  'NOTIFICACIONES',
                  style: TextStyle(
                    color: AppTheme.mutedForegroundColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: SwitchListTile(
                    title: const Text(
                      'Recibir notificaciones',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    subtitle: Text(
                      _notificacionesActivas
                          ? 'Recibirás recordatorios de partidos y roles'
                          : 'No recibirás ninguna notificación',
                      style: const TextStyle(
                        color: AppTheme.mutedForegroundColor,
                        fontSize: 12,
                      ),
                    ),
                    value: _notificacionesActivas,
                    onChanged: _toggleNotificaciones,
                    activeColor: AppTheme.primaryColor,
                    inactiveThumbColor: AppTheme.mutedForegroundColor,
                    inactiveTrackColor: AppTheme.secondaryColor,
                  ),
                ),
              ],
            ),
    );
  }
}
