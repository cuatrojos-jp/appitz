// lib/screens/partido_detail_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/partido_model.dart';
import '../models/evento_model.dart';
import '../services/evento_service.dart';
import '../services/auth_service.dart';
import 'eventos_register_screen.dart';

class PartidoDetailScreen extends StatefulWidget {
  final PartidoModel partido;

  const PartidoDetailScreen({super.key, required this.partido});

  @override
  State<PartidoDetailScreen> createState() => _PartidoDetailScreenState();
}

class _PartidoDetailScreenState extends State<PartidoDetailScreen> {
  final EventoService _eventoService = EventoService();
  final AuthService _authService = AuthService();

  List<EventoModel> _eventos = [];
  List<EventoModel> get _eventosMostrados =>
      _eventos.where((e) => e.golLocal == true || e.golLocal == null).toList();
  bool _isLoading = true;
  bool _esCoordinador = false;

  // UUID del rol coordinador — igual que en DashboardScreen
  static const String _rolCoordinadorId =
      'a0d38955-fa67-4751-a36b-777fcf4d8ed9';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);

    // Verificar rol del usuario actual
    Future<String?> usuarioId = _authService.getUsuarioId();
    String usuarioIdString = await usuarioId ?? '';
    final rolId = await _authService.getRolId(usuarioIdString);
    _esCoordinador = rolId == _rolCoordinadorId;

    final eventos = await _eventoService.obtenerEventosPorPartido(
      widget.partido.id,
    );

    setState(() {
      _eventos = eventos;
      _isLoading = false;
    });
  }

  // ── Eliminar evento ──────────────────────────────────────

  Future<void> _eliminarEvento(EventoModel evento) async {
    await _eventoService.eliminarEventoPorGrupoId(evento.id);
    await _cargarDatos();
  }

  Future<void> _confirmarEliminarEvento(EventoModel evento) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text(
          'Eliminar evento',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Eliminar el evento de ${evento.jugadorNombre} en el minuto ${evento.minuto}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _eliminarEvento(evento);
    }
  }

  // ── Marcador calculado desde eventos ──────────────────────

  int get _golesLocal {
    return _eventos
        .where(
          (e) =>
              e.golLocal == true &&
              e.equipoId == widget.partido.equipoLocalId &&
              (e.tipoCodigo == 'gol' ||
                  e.tipoCodigo == 'asistencia' ||
                  e.tipoCodigo == 'autogol' ||
                  (e.tipoCodigo == 'penal' &&
                      e.minuto > 0)), // penal dentro del partido
        )
        .length;
  }

  int get _golesVisitante {
    return _eventos
        .where(
          (e) =>
              e.golLocal == true &&
              e.equipoId == widget.partido.equipoVisitanteId &&
              (e.tipoCodigo == 'gol' ||
                  e.tipoCodigo == 'asistencia' ||
                  e.tipoCodigo == 'autogol' ||
                  (e.tipoCodigo == 'penal' &&
                      e.minuto > 0)), // penal dentro del partido
        )
        .length;
  }

  // Solo tanda (minuto == 0)
  bool get _hayPenales =>
      _eventos.any((e) => e.tipoCodigo == 'penal' && e.minuto == 0);

  int get _penalesLocal {
    return _eventos
        .where(
          (e) =>
              e.golLocal == true &&
              e.equipoId == widget.partido.equipoLocalId &&
              e.tipoCodigo == 'penal' &&
              e.minuto == 0, // solo tanda
        )
        .length;
  }

  int get _penalesVisitante {
    return _eventos
        .where(
          (e) =>
              e.golLocal == true &&
              e.equipoId == widget.partido.equipoVisitanteId &&
              e.tipoCodigo == 'penal' &&
              e.minuto == 0, // solo tanda
        )
        .length;
  }

  // ── Helpers visuales ───────────────────────────────────────

  String _formatearFecha(DateTime fecha) {
    final local = fecha.toLocal();
    return '${local.day}/${local.month}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  IconData _iconoPorTipo(String codigo) {
    switch (codigo) {
      case 'gol':
        return Icons.sports_soccer;
      case 'autogol':
        return Icons.sports_soccer;
      case 'asistencia':
        return Icons.sports_soccer;
      case 'tarjeta_amarilla':
        return Icons.square;
      case 'tarjeta_roja':
        return Icons.square;
      case 'sustitucion':
        return Icons.swap_horiz;
      case 'penal':
        return Icons.sports_soccer;
      default:
        return Icons.event;
    }
  }

  Color _colorPorTipo(String codigo) {
    switch (codigo) {
      case 'gol':
        return Colors.green;
      case 'autogol':
        return Colors.red;
      case 'asistencia':
        return Colors.lightGreen;
      case 'tarjeta_amarilla':
        return Colors.amber;
      case 'tarjeta_roja':
        return Colors.red;
      case 'sustitucion':
        return Colors.blue;
      case 'penal':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _labelPorTipo(String codigo) {
    switch (codigo) {
      case 'gol':
        return 'Gol';
      case 'autogol':
        return 'Autogol';
      case 'asistencia':
        return 'Asistencia';
      case 'tarjeta_amarilla':
        return 'Tarjeta amarilla';
      case 'tarjeta_roja':
        return 'Tarjeta roja';
      case 'sustitucion':
        return 'Sustitución';
      case 'penal':
        return 'Penal';
      default:
        return codigo;
    }
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final partido = widget.partido;
    final esAccesible = partido.estadoCodigo == 'finalizado';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColorAlt,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColorAlt,
        elevation: 0,
        title: const Text(
          'Detalle del partido',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Solo coordinador en partido finalizado puede registrar eventos
          if (esAccesible && _esCoordinador)
            IconButton(
              icon: const Icon(Icons.edit_note, color: AppTheme.primaryColor),
              tooltip: 'Registrar eventos',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventosRegisterScreen(partido: partido),
                  ),
                );
                if (result == true) _cargarDatos();
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Marcador
                SliverToBoxAdapter(child: _buildMarcador(partido)),

                // Info del partido
                SliverToBoxAdapter(child: _buildInfoPartido(partido)),

                const SliverToBoxAdapter(
                  child: Divider(color: AppTheme.borderColor),
                ),

                // Header eventos
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.event_note,
                          color: AppTheme.primaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Eventos',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_eventosMostrados.length}',
                          style: const TextStyle(
                            color: AppTheme.mutedForegroundColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Lista de eventos o vacío
                _eventos.isEmpty
                    ? SliverFillRemaining(child: _buildEmpty(esAccesible))
                    : SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          4,
                          16,
                          MediaQuery.of(context).padding.bottom + 16,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) =>
                                _buildEventoRow(_eventosMostrados[index]),
                            childCount: _eventosMostrados.length,
                          ),
                        ),
                      ),
              ],
            ),
    );
  }

  Widget _buildMarcador(PartidoModel partido) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          // Equipo local
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.shield,
                    color: AppTheme.primaryColor,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  partido.equipoLocalNombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Marcador central
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      '$_golesLocal',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '-',
                        style: TextStyle(
                          color: AppTheme.mutedForegroundColor,
                          fontSize: 32,
                        ),
                      ),
                    ),
                    Text(
                      '$_golesVisitante',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                if (_hayPenales) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'P  $_penalesLocal  -  $_penalesVisitante  P',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatearFecha(partido.fechaHora),
                    style: const TextStyle(
                      color: AppTheme.mutedForegroundColor,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Equipo visitante
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.shield,
                    color: AppTheme.primaryColor,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  partido.equipoVisitanteNombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPartido(PartidoModel partido) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          const Icon(
            Icons.location_on,
            color: AppTheme.mutedForegroundColor,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            partido.campoNombre,
            style: const TextStyle(
              color: AppTheme.mutedForegroundColor,
              fontSize: 12,
            ),
          ),
          if (partido.categoriaNombre != 'Amistoso') ...[
            const SizedBox(width: 16),
            const Icon(
              Icons.category,
              color: AppTheme.mutedForegroundColor,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              partido.categoriaNombre,
              style: const TextStyle(
                color: AppTheme.mutedForegroundColor,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventoRow(EventoModel evento) {
    final esLocal = evento.equipoId == widget.partido.equipoLocalId;
    final color = _colorPorTipo(evento.tipoCodigo);
    final icono = _iconoPorTipo(evento.tipoCodigo);
    final label = _labelPorTipo(evento.tipoCodigo);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          // Minuto
          SizedBox(
            width: 36,
            child: Text(
              evento.tipoCodigo == 'penal' && evento.minuto == 0
                  ? 'P'
                  : "${evento.minuto}'",
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),

          // Ícono tipo
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icono, size: 14, color: color),
          ),
          const SizedBox(width: 10),

          // Nombre jugador y tipo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evento.jugadorNombre ?? 'Jugador desconocido',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    Text(label, style: TextStyle(color: color, fontSize: 11)),
                    if (evento.jugadorSecundarioNombre != null) ...[
                      Text(
                        ' · ${evento.jugadorSecundarioNombre}',
                        style: const TextStyle(
                          color: AppTheme.mutedForegroundColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Equipo (local / visitante)
          Text(
            esLocal
                ? widget.partido.equipoLocalNombre
                : widget.partido.equipoVisitanteNombre,
            style: const TextStyle(
              color: AppTheme.mutedForegroundColor,
              fontSize: 11,
            ),
            textAlign: TextAlign.right,
          ),

          // Botón de eliminar
          if (_esCoordinador)
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 18,
                color: Colors.redAccent,
              ),
              onPressed: () => _confirmarEliminarEvento(evento),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool esAccesible) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.event_busy,
            size: 64,
            color: AppTheme.mutedForegroundColor,
          ),
          const SizedBox(height: 16),
          Text(
            esAccesible
                ? 'No hay eventos registrados'
                : 'Los eventos se registran\ncuando el partido finaliza',
            style: const TextStyle(
              color: AppTheme.mutedForegroundColor,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          if (esAccesible && _esCoordinador) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        EventosRegisterScreen(partido: widget.partido),
                  ),
                );
                if (result == true) _cargarDatos();
              },
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text(
                'Registrar eventos',
                style: TextStyle(color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
