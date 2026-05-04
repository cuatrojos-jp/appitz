import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/temporada_service.dart';
import '../models/temporadas_model.dart';
// import '../widgets/show_snackbar.dart';

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

  final TemporadaService _temporadaService = TemporadaService();
  List<TemporadaModel> _temporadas = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filtroEstado =
      'todos'; // 'todos', 'activo', 'programado', 'finalizado'

  @override
  void initState() {
    super.initState();
    _cargarTemporadas();
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
        // Botón Nueva Temporada
        GestureDetector(
          onTap: () {
            // TODO: Navegar a pantalla de crear temporada
            print('Navegar a crear temporada');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icono
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
                  // Nombre y estado
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.4,
                        child: Text(
                          temporada.nombre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
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
                              Icon(
                                Icons.schedule,
                                color: estadoColor,
                                size: 10,
                              ),
                              const SizedBox(width: 6),
                            ] else if (estadoIcon == 'check') ...[
                              Icon(Icons.check, color: estadoColor, size: 10),
                              const SizedBox(width: 6),
                            ] else if (estadoIcon == 'stop') ...[
                              // ← AGREGAR ESTO
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
                ],
              ),
              // Acciones
              Row(
                children: [
                  _buildActionButton(
                    icon: Icons.edit_outlined,
                    onTap: () {
                      // TODO: Navegar a editar temporada
                      print('Editar: ${temporada.nombre}');
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.delete_outline,
                    iconColor: const Color(0xFFEF4444),
                    onTap: () {
                      // TODO: Eliminar temporada
                      print('Eliminar: ${temporada.nombre}');
                    },
                  ),
                ],
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
}
