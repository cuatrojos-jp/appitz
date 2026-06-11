import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/temporada_service.dart';
import '../models/temporadas_model.dart';
import 'agregar_temporada_screen.dart';
import '../widgets/show_snackbar.dart';
import 'estadisticas_screen.dart';

class TemporadaScreen extends StatefulWidget {
  const TemporadaScreen({super.key});

  @override
  State<TemporadaScreen> createState() => _TemporadaScreenState();
}

class _TemporadaScreenState extends State<TemporadaScreen> {
  static const String _estadoActivoId = 'a4a0e12b-40b9-4c7a-979b-654e7807e012';
  static const String _estadoProgramadoId =
      '32dd8daf-4d3f-4a2d-9cda-98f13af88493';
  static const String _estadoFinalizadoId =
      'af6a7363-5105-4c22-9b03-4f77be807264';
  static const String _estadoSuspendidoId =
      '90f514a4-b43c-4fb1-b327-366b708dd9c2';

  static const String _adminRoleId = 'a0d38955-fa67-4751-a36b-777fcf4d8ed9';

  final TemporadaService _temporadaService = TemporadaService();
  final AuthService _authService = AuthService();
  List<TemporadaModel> _temporadas = [];
  bool _isLoading = true;
  bool _existeTemporadaActivaProgramada = false;
  bool _isAdmin = false;
  String? _errorMessage;
  final String _filtroEstado =
      'todos'; // 'todos', 'activo', 'programado', 'finalizado'

  @override
  void initState() {
    super.initState();
    _verificarPermisos();
    _cargarTemporadas();
    _verificarExistenciaTemporada();
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

  Future<void> _verificarExistenciaTemporada() async {
    final existe = await _temporadaService.existeTemporadaActivaOProgramada();
    setState(() {
      _existeTemporadaActivaProgramada = existe;
    });
  }

  Future<void> _cargarTemporadas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final temporadas = await _temporadaService.listarTemporadas();
      setState(() {
        _temporadas = temporadas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _mostrarMenuEstados(TemporadaModel temporada) {
    final estadoActual = temporada.estadoId;

    List<Map<String, dynamic>> opciones = [];

    if (estadoActual == _estadoProgramadoId) {
      opciones = [
        {
          'label': 'Activar',
          'icon': Icons.play_arrow,
          'estadoId': _estadoActivoId,
          'color': Colors.green,
        },
        {
          'label': 'Suspender',
          'icon': Icons.pause,
          'estadoId': _estadoSuspendidoId,
          'color': Colors.orange,
        },
      ];
    } else if (estadoActual == _estadoActivoId) {
      opciones = [
        {
          'label': 'Finalizar',
          'icon': Icons.check,
          'estadoId': _estadoFinalizadoId,
          'color': Colors.blue,
        },
        {
          'label': 'Suspender',
          'icon': Icons.pause,
          'estadoId': _estadoSuspendidoId,
          'color': Colors.orange,
        },
      ];
    } else {
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Cambiar estado',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Divider(color: AppTheme.borderColor),
              ...opciones.map(
                (opcion) => ListTile(
                  leading: Icon(opcion['icon'], color: opcion['color']),
                  title: Text(
                    opcion['label'],
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _cambiarEstadoTemporada(
                      temporada.id,
                      opcion['estadoId'],
                      opcion['label'],
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _cambiarEstadoTemporada(
    String id,
    String nuevoEstadoId,
    String accion,
  ) async {
    if (nuevoEstadoId == _estadoActivoId) {
      final existeOtraActiva = await _temporadaService
          .existeTemporadaActivaOProgramada(excludeId: id);
      if (existeOtraActiva) {
        showSnackBar(
          context,
          'No se puede activar. Ya hay otra temporada activa.',
          color: Colors.orange,
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      if (nuevoEstadoId == _estadoActivoId) {
        await _temporadaService.activarTemporada(id);
      } else if (nuevoEstadoId == _estadoFinalizadoId) {
        await _temporadaService.finalizarTemporada(id);
      } else if (nuevoEstadoId == _estadoSuspendidoId) {
        await _temporadaService.suspenderTemporada(id);
      }

      showSnackBar(context, 'Temporada $accion', color: Colors.green);
      await _cargarTemporadas();
    } catch (e) {
      showSnackBar(context, 'Error: ${e.toString()}', color: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<TemporadaModel> get _temporadasFiltradas {
    if (_filtroEstado == 'todos') return _temporadas;

    String filtroId;
    if (_filtroEstado == 'activo') {
      filtroId = _estadoActivoId;
    } else if (_filtroEstado == 'programado') {
      filtroId = _estadoProgramadoId;
    } else if (_filtroEstado == 'finalizado') {
      filtroId = _estadoFinalizadoId;
    } else if (_filtroEstado == 'suspendido') {
      filtroId = _estadoSuspendidoId;
    } else {
      filtroId = _estadoActivoId;
    }

    return _temporadas.where((t) => t.estadoId == filtroId).toList();
  }

  int get _activasCount =>
      _temporadas.where((t) => t.estadoId == _estadoActivoId).length;
  int get _programadasCount =>
      _temporadas.where((t) => t.estadoId == _estadoProgramadoId).length;
  int get _finalizadasCount =>
      _temporadas.where((t) => t.estadoId == _estadoFinalizadoId).length;
  int get _suspendidasCount =>
      _temporadas.where((t) => t.estadoId == _estadoSuspendidoId).length;

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'No definida';
    final meses = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${fecha.day} ${meses[fecha.month - 1]} ${fecha.year}';
  }

  Color _getEstadoColor(String estadoId) {
    if (estadoId == _estadoActivoId) return AppTheme.primaryColor;
    if (estadoId == _estadoProgramadoId)
      return const Color.fromARGB(255, 43, 163, 219);
    if (estadoId == _estadoFinalizadoId) return AppTheme.mutedForegroundColor;
    if (estadoId == _estadoSuspendidoId) return Colors.redAccent;
    return AppTheme.mutedForegroundColor;
  }

  Color _getEstadoBg(String estadoId) {
    if (estadoId == _estadoActivoId) return const Color(0xFF064E3B);
    if (estadoId == _estadoProgramadoId)
      return const Color.fromARGB(255, 17, 31, 94);
    if (estadoId == _estadoFinalizadoId) return AppTheme.secondaryColor;
    if (estadoId == _estadoSuspendidoId)
      return const Color.fromARGB(255, 68, 28, 28);
    return AppTheme.secondaryColor;
  }

  String _getEstadoLabel(String estadoId) {
    if (estadoId == _estadoActivoId) return 'Activo';
    if (estadoId == _estadoProgramadoId) return 'Pendiente';
    if (estadoId == _estadoFinalizadoId) return 'Finalizada';
    if (estadoId == _estadoSuspendidoId) return 'Suspendido';
    return 'Desconocido';
  }

  String _getEstadoIcon(String estadoId) {
    if (estadoId == _estadoActivoId) return 'play';
    if (estadoId == _estadoProgramadoId) return 'schedule';
    if (estadoId == _estadoFinalizadoId) return 'check';
    if (estadoId == _estadoSuspendidoId) return 'stop';
    return 'help';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColorAlt,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildErrorView()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 28),
                    _buildFilterButtons(),
                    const SizedBox(height: 28),
                    _buildSectionByEstado(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _cargarTemporadas,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Icono y título en un Row interno
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Icon(
                Icons.emoji_events_outlined,
                color: AppTheme.primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'Temporadas',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        if (_isAdmin)
          GestureDetector(
            onTap: _existeTemporadaActivaProgramada
                ? () {
                    showSnackBar(
                      context,
                      'No puedes crear una nueva temporada mientras exista una activa o programada.',
                      color: Colors.orange,
                    );
                  }
                : () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AgregarTemporadaScreen(),
                      ),
                    );
                    if (result == true) {
                      _cargarTemporadas();
                    }
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _existeTemporadaActivaProgramada
                    ? Colors.blueGrey
                    : Colors.greenAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Color(0xFF0F0F11), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Nueva',
                    style: TextStyle(
                      color: Color(0xFF0F0F11),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterButtons() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _buildFilterButton(
          label: 'Activa',
          count: _activasCount,
          isActive: _filtroEstado == 'activo',
          icon: Icons.play_circle_outline,
          estado: 'activo',
        ),
        _buildFilterButton(
          label: 'Pendiente',
          count: _programadasCount,
          isActive: _filtroEstado == 'programado',
          icon: Icons.schedule_outlined,
          estado: 'programado',
        ),
        _buildFilterButton(
          label: 'Finalizada',
          count: _finalizadasCount,
          isActive: _filtroEstado == 'finalizado',
          icon: Icons.check_circle_outline,
          estado: 'finalizado',
        ),
        _buildFilterButton(
          label: 'Suspendida',
          count: _suspendidasCount,
          isActive: _filtroEstado == 'suspendido',
          icon: Icons.block,
          estado: 'suspendido',
        ),
      ],
    );
  }

  Widget _buildFilterButton({
    required String label,
    required int count,
    required bool isActive,
    required IconData icon,
    required String estado,
  }) {
    return IntrinsicWidth(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : AppTheme.secondaryColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? AppTheme.primaryColor : AppTheme.borderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive
                  ? const Color(0xFF0F0F11)
                  : AppTheme.mutedForegroundColor,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? const Color(0xFF0F0F11)
                    : AppTheme.mutedForegroundColor,
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF0F0F11).withValues(alpha: 0.15)
                    : AppTheme.cardColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isActive
                      ? const Color(0xFF0F0F11)
                      : AppTheme.mutedForegroundColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionByEstado() {
    final Map<String, List<TemporadaModel>> agrupadas = {
      'activo': _temporadasFiltradas
          .where((t) => t.estadoId == _estadoActivoId)
          .toList(),
      'programado': _temporadasFiltradas
          .where((t) => t.estadoId == _estadoProgramadoId)
          .toList(),
      'finalizado': _temporadasFiltradas
          .where((t) => t.estadoId == _estadoFinalizadoId)
          .toList(),
      'suspendido': _temporadasFiltradas
          .where((t) => t.estadoId == _estadoSuspendidoId)
          .toList(),
    };

    final List<Widget> secciones = [];

    if (agrupadas['activo']!.isNotEmpty) {
      secciones.add(
        _buildSectionTitle(
          icon: Icons.play_circle_outline,
          title: 'Temporadas Activas',
          color: AppTheme.primaryColor,
        ),
      );
      secciones.add(const SizedBox(height: 16));
      secciones.addAll(agrupadas['activo']!.map((t) => _buildTemporadaCard(t)));
      secciones.add(const SizedBox(height: 32));
    }

    if (agrupadas['programado']!.isNotEmpty) {
      secciones.add(
        _buildSectionTitle(
          icon: Icons.schedule_outlined,
          title: 'Temporadas Programadas',
          color: const Color.fromARGB(255, 43, 163, 219),
        ),
      );
      secciones.add(const SizedBox(height: 16));
      secciones.addAll(
        agrupadas['programado']!.map((t) => _buildTemporadaCard(t)),
      );
      secciones.add(const SizedBox(height: 32));
    }

    if (agrupadas['finalizado']!.isNotEmpty) {
      secciones.add(
        _buildSectionTitle(
          icon: Icons.check_circle_outline,
          title: 'Temporadas Finalizadas',
          color: AppTheme.mutedForegroundColor,
        ),
      );
      secciones.add(const SizedBox(height: 16));
      secciones.addAll(
        agrupadas['finalizado']!.map((t) => _buildTemporadaCard(t)),
      );
    }

    if (agrupadas['suspendido']!.isNotEmpty) {
      secciones.add(
        _buildSectionTitle(
          icon: Icons.block,
          title: 'Temporadas Suspendidas',
          color: Colors.redAccent,
        ),
      );
      secciones.add(const SizedBox(height: 16));
      secciones.addAll(
        agrupadas['suspendido']!.map((t) => _buildTemporadaCard(t)),
      );
    }

    if (secciones.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(
                Icons.inbox_outlined,
                size: 64,
                color: AppTheme.mutedForegroundColor,
              ),
              const SizedBox(height: 16),
              Text(
                'No hay temporadas ${_filtroEstado != 'todos' ? 'con este estado' : 'registradas'}',
                style: const TextStyle(color: AppTheme.mutedForegroundColor),
              ),
            ],
          ),
        ),
      );
    }

    return Column(children: secciones);
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: AppTheme.borderColor)),
      ],
    );
  }

  Widget _buildTemporadaCard(TemporadaModel temporada) {
    final estadoId = temporada.estadoId;
    final estadoColor = _getEstadoColor(estadoId);
    final estadoBg = _getEstadoBg(estadoId);
    final estadoIcon = _getEstadoIcon(estadoId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la card
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono (tamaño fijo)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Icon(
                  estadoId == _estadoActivoId
                      ? Icons.play_circle_outline
                      : estadoId == _estadoProgramadoId
                      ? Icons.schedule_outlined
                      : estadoId == _estadoFinalizadoId
                      ? Icons.check_circle_outline
                      : Icons.block,
                  color: estadoColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Nombre y estado - Expanded para ocupar espacio restante
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      temporada.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: estadoBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: estadoColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (estadoIcon == 'play') ...[
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: estadoColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ] else if (estadoIcon == 'schedule') ...[
                            Icon(Icons.schedule, color: estadoColor, size: 10),
                            const SizedBox(width: 6),
                          ] else if (estadoIcon == 'check') ...[
                            Icon(Icons.check, color: estadoColor, size: 10),
                            const SizedBox(width: 6),
                          ] else if (estadoIcon == 'stop') ...[
                            Icon(Icons.block, color: estadoColor, size: 10),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            _getEstadoLabel(estadoId),
                            style: TextStyle(
                              color: estadoColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Botones de acción - Wrap para que se envuelvan automáticamente
              if (_isAdmin)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      _buildActionButton(
                        icon: Icons.edit_outlined,
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AgregarTemporadaScreen(temporada: temporada),
                            ),
                          );
                          if (result == true) {
                            _cargarTemporadas();
                          }
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.delete_outline,
                        iconColor: const Color(0xFFEF4444),
                        onTap: () => _confirmarEliminacion(temporada),
                      ),
                      _buildActionButton(
                        icon: Icons.swap_horiz,
                        iconColor: Colors.orange,
                        onTap: () => _mostrarMenuEstados(temporada),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Descripción
          Text(
            temporada.descripcion ?? 'Sin descripción',
            style: TextStyle(
              color: AppTheme.mutedForegroundColor,
              fontSize: 14,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 20),

          // Fechas
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              children: [
                // Fecha inicio
                Expanded(
                  child: _buildDateItem(
                    label: 'Fecha de inicio',
                    fecha: _formatearFecha(temporada.fechaInicio),
                    icon: Icons.calendar_today_outlined,
                  ),
                ),
                Container(width: 1, height: 40, color: AppTheme.borderColor),
                // Fecha fin
                Expanded(
                  child: _buildDateItem(
                    label: 'Fecha de cierre',
                    fecha: _formatearFecha(temporada.fechaFin),
                    icon: Icons.event_outlined,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                final esHistorica =
                    estadoId == _estadoFinalizadoId ||
                    estadoId == _estadoSuspendidoId;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EstadisticasScreen(temporada: temporada),
                  ),
                );
              },
              icon: Icon(
                Icons.bar_chart_outlined,
                size: 16,
                color: estadoColor,
              ),
              label: Text(
                'Ver estadísticas',
                style: TextStyle(
                  color: estadoColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: estadoColor.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateItem({
    required String label,
    required String fecha,
    required IconData icon,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 14),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppTheme.mutedForegroundColor,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              fecha,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Icon(icon, color: iconColor ?? AppTheme.primaryColor, size: 16),
      ),
    );
  }

  Future<void> _confirmarEliminacion(TemporadaModel temporada) async {
    // Primera confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar temporada'),
        content: Text('¿Eliminar la temporada "${temporada.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    // Segunda confirmación (doble verificación)
    final confirmarSegunda = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmación final'),
        content: Text(
          'Esta acción eliminará la temporada "${temporada.nombre}" '
          'y TODAS sus categorías asociadas.\n\n'
          '¿Estás ABSOLUTAMENTE seguro?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sí, eliminar permanentemente'),
          ),
        ],
      ),
    );

    if (confirmarSegunda != true) return;

    // Ejecutar eliminación
    await _eliminarTemporada(temporada.id, temporada.nombre);
  }

  Future<void> _eliminarTemporada(String id, String nombre) async {
    setState(() => _isLoading = true);

    try {
      await _temporadaService.eliminar(id);
      await _cargarTemporadas();
      await _verificarExistenciaTemporada();

      if (mounted) {
        showSnackBar(
          context,
          'Temporada "$nombre" eliminada',
          color: Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(
          context,
          'Error al eliminar: ${e.toString()}',
          color: Colors.red,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
