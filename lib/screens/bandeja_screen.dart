// lib/screens/bandeja_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/notification_model.dart';
import '../services/bandeja_service.dart';
import '../services/auth_service.dart';
import '../widgets/show_snackbar.dart';
import 'partidos_list_screen.dart';

class BandejaScreen extends StatefulWidget {
  final VoidCallback? onNotificacionLeida;

  const BandejaScreen({super.key, this.onNotificacionLeida});

  @override
  State<BandejaScreen> createState() => BandejaScreenState();
}

class BandejaScreenState extends State<BandejaScreen> {
  final BandejaService _bandejaService = BandejaService();
  final AuthService _authService = AuthService();

  List<NotificationModel> _notificaciones = [];
  bool _isLoading = true;
  String? _usuarioId;

  @override
  void initState() {
    super.initState();
    cargarNotificaciones();
  }

  Future<void> cargarNotificaciones() async {
    setState(() => _isLoading = true);

    _usuarioId ??= await _authService.getUsuarioId();
    if (_usuarioId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final data = await _bandejaService.obtenerNotificaciones(_usuarioId!);
    setState(() {
      _notificaciones = data.map(NotificationModel.fromJson).toList();
      _isLoading = false;
    });
  }

  // ── Marcar una como leída y navegar si tiene ruta ──────────

  Future<void> _onTapNotificacion(NotificationModel notif) async {
    if (!notif.leida) {
      await _bandejaService.marcarComoLeida(notif.id);
      setState(() {
        final idx = _notificaciones.indexWhere((n) => n.id == notif.id);
        if (idx != -1) {
          _notificaciones[idx] = notif.copyWith(
            leida: true,
            leidaEn: DateTime.now(),
          );
        }
      });
      widget.onNotificacionLeida?.call();
    }

    // Navegar según url_destino
    if (notif.urlDestino == '/partidos' && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PartidosListScreen()),
      );
    }
  }

  // ── Marcar todas como leídas ───────────────────────────────

  Future<void> _marcarTodasLeidas() async {
    if (_usuarioId == null) return;
    final confirm = await _confirmar(
      titulo: 'Marcar todas como leídas',
      mensaje: '¿Marcar todas las notificaciones como leídas?',
      confirmaciones: 1,
    );
    if (!confirm) return;

    await _bandejaService.marcarTodasComoLeidas(_usuarioId!);
    await cargarNotificaciones();
    widget.onNotificacionLeida?.call();
    if (mounted)
      showSnackBar(context, 'Todas marcadas como leídas', color: Colors.green);
  }

  // ── Vaciar bandeja ─────────────────────────────────────────
  // Primera llamada: elimina solo las leídas.
  // Si no quedan leídas, elimina todas (las no leídas restantes).

  Future<void> _vaciarBandeja() async {
    if (_usuarioId == null) return;

    final tieneLeidas = _notificaciones.any((n) => n.leida);

    if (tieneLeidas) {
      // Primer vaciado: solo leídas — pide confirmación dos veces
      final confirm = await _confirmar(
        titulo: 'Vaciar bandeja',
        mensaje:
            'Se eliminarán todas las notificaciones ya leídas. ¿Continuar?',
        confirmaciones: 2,
      );
      if (!confirm) return;

      final idsLeidas = _notificaciones
          .where((n) => n.leida)
          .map((n) => n.id)
          .toList();
      for (final id in idsLeidas) {
        await _bandejaService.eliminarNotificacion(id);
      }
      if (mounted) {
        showSnackBar(
          context,
          'Notificaciones leídas eliminadas',
          color: Colors.green,
        );
      }
    } else {
      // No quedan leídas: eliminar todo — pide confirmación dos veces
      final confirm = await _confirmar(
        titulo: 'Vaciar bandeja',
        mensaje:
            'No hay notificaciones leídas. ¿Eliminar todas las notificaciones restantes?',
        confirmaciones: 2,
      );
      if (!confirm) return;

      await _bandejaService.eliminarTodas(_usuarioId!);
      if (mounted) {
        showSnackBar(context, 'Bandeja vaciada', color: Colors.green);
      }
    }

    await cargarNotificaciones();
    widget.onNotificacionLeida?.call();
  }

  // ── Helper: diálogo de confirmación (1 o 2 pasos) ─────────

  Future<bool> _confirmar({
    required String titulo,
    required String mensaje,
    required int confirmaciones,
  }) async {
    final primera = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Text(titulo, style: const TextStyle(color: Colors.white)),
        content: Text(
          mensaje,
          style: const TextStyle(color: AppTheme.mutedForegroundColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.mutedForegroundColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (primera != true) return false;
    if (confirmaciones < 2) return true;

    // Segunda confirmación
    final segunda = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text(
          '¿Estás seguro?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Esta acción no se puede deshacer.',
          style: TextStyle(color: AppTheme.mutedForegroundColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.mutedForegroundColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sí, eliminar'),
          ),
        ],
      ),
    );

    return segunda == true;
  }

  // ── Helpers de formato ─────────────────────────────────────

  String _formatearFecha(DateTime fecha) {
    final local = fecha.toLocal();
    final ahora = DateTime.now();
    final diferencia = ahora.difference(local);

    if (diferencia.inMinutes < 1) return 'Justo ahora';
    if (diferencia.inMinutes < 60) return 'Hace ${diferencia.inMinutes} min';
    if (diferencia.inHours < 24) return 'Hace ${diferencia.inHours} h';
    if (diferencia.inDays == 1) return 'Ayer';
    return '${local.day}/${local.month}/${local.year}';
  }

  IconData _iconoPorTipo(String tipo) {
    switch (tipo) {
      case 'partido':
        return Icons.sports_soccer;
      case 'rol':
        return Icons.calendar_month;
      default:
        return Icons.notifications;
    }
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final noLeidas = _notificaciones.where((n) => !n.leida).length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColorAlt,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColorAlt,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Text(
              'Bandeja',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (noLeidas > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$noLeidas',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_notificaciones.any((n) => !n.leida))
            IconButton(
              icon: const Icon(
                Icons.done_all,
                color: AppTheme.mutedForegroundColor,
              ),
              tooltip: 'Marcar todas como leídas',
              onPressed: _marcarTodasLeidas,
            ),
          if (_notificaciones.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.delete_sweep_outlined,
                color: AppTheme.mutedForegroundColor,
              ),
              tooltip: 'Vaciar bandeja',
              onPressed: _vaciarBandeja,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notificaciones.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
              onRefresh: cargarNotificaciones,
              color: AppTheme.primaryColor,
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  MediaQuery.of(context).padding.bottom + 16,
                ),
                itemCount: _notificaciones.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) =>
                    _buildNotificacionCard(_notificaciones[index]),
              ),
            ),
    );
  }

  Widget _buildNotificacionCard(NotificationModel notif) {
    // No leída: fondo ligeramente más claro con borde de color primario
    // Leída: fondo normal sin borde destacado
    final esNoLeida = !notif.leida;

    return GestureDetector(
      onTap: () => _onTapNotificacion(notif),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: esNoLeida ? AppTheme.cardColor : AppTheme.backgroundColorAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: esNoLeida
                ? AppTheme.primaryColor.withValues(alpha: 0.5)
                : AppTheme.borderColor,
            width: esNoLeida ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícono por tipo
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: esNoLeida
                    ? AppTheme.primaryColor.withValues(alpha: 0.15)
                    : AppTheme.secondaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _iconoPorTipo(notif.tipo),
                size: 18,
                color: esNoLeida
                    ? AppTheme.primaryColor
                    : AppTheme.mutedForegroundColor,
              ),
            ),
            const SizedBox(width: 12),

            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.titulo,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: esNoLeida
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatearFecha(notif.creadoEn),
                        style: const TextStyle(
                          color: AppTheme.mutedForegroundColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.mensaje,
                    style: TextStyle(
                      color: esNoLeida
                          ? Colors.white70
                          : AppTheme.mutedForegroundColor,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (notif.urlDestino != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.arrow_forward,
                          size: 11,
                          color: AppTheme.primaryColor.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Ver detalle',
                          style: TextStyle(
                            color: AppTheme.primaryColor.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Punto indicador de no leída
            if (esNoLeida)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: AppTheme.mutedForegroundColor,
          ),
          SizedBox(height: 16),
          Text(
            'Sin notificaciones',
            style: TextStyle(
              color: AppTheme.mutedForegroundColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
