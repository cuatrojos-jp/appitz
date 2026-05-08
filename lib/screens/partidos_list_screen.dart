// lib/screens/partidos_list_screen.dart
import 'package:appitz/screens/partido_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../theme/app_theme.dart';
import '../services/partido_service.dart';
import '../models/partido_model.dart';
import '../widgets/show_snackbar.dart';

class PartidosListScreen extends StatefulWidget {
  const PartidosListScreen({super.key});

  @override
  State<PartidosListScreen> createState() => _PartidosListScreenState();
}

class _PartidosListScreenState extends State<PartidosListScreen> {
  final PartidoService _partidoService = PartidoService();
  List<PartidoModel> _partidos = [];
  List<PartidoModel> _partidosDelDia = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Calendario
  DateTime _fechaSeleccionada = DateTime.now();
  DateTime _fechaEnfoque = DateTime.now();
  Map<DateTime, List<PartidoModel>> _eventosCalendario = {};

  @override
  void initState() {
    super.initState();
    _fechaEnfoque = DateTime.now();
    _cargarPartidos();
  }

  Future<void> _cargarPartidos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final partidos = await _partidoService.obtenerTodosLosPartidos();
      setState(() {
        _partidos = partidos;
        _partidosDelDia = _partidos
            .where(
              (p) =>
                  p.fechaHora.year == _fechaSeleccionada.year &&
                  p.fechaHora.month == _fechaSeleccionada.month &&
                  p.fechaHora.day == _fechaSeleccionada.day,
            )
            .toList();
        _actualizarEventosCalendario();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _actualizarEventosCalendario() {
    _eventosCalendario = {};
    for (var partido in _partidos) {
      final fecha = DateTime(
        partido.fechaHora.year,
        partido.fechaHora.month,
        partido.fechaHora.day,
      );
      if (_eventosCalendario[fecha] == null) {
        _eventosCalendario[fecha] = [];
      }
      _eventosCalendario[fecha]!.add(partido);
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _fechaSeleccionada = selectedDay;
      _fechaEnfoque = focusedDay;
      _partidosDelDia = _partidos
          .where(
            (p) =>
                p.fechaHora.year == selectedDay.year &&
                p.fechaHora.month == selectedDay.month &&
                p.fechaHora.day == selectedDay.day,
          )
          .toList();
    });
  }

  Future<void> _actualizarEstadoPartido(
    PartidoModel partido,
    String nuevoEstadoId,
    String nuevoEstadoCodigo,
  ) async {
    try {
      await _partidoService.cambiarEstado(partido.id, nuevoEstadoId);
      await _cargarPartidos();
      if (mounted) {
        showSnackBar(
          context,
          'Partido ${partido.equipoLocalNombre} vs ${partido.equipoVisitanteNombre} ${nuevoEstadoCodigo}',
          color: Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error: ${e.toString()}', color: Colors.red);
      }
    }
  }

  Future<void> _eliminarPartido(PartidoModel partido) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar partido'),
        content: Text(
          '¿Eliminar el partido entre ${partido.equipoLocalNombre} y ${partido.equipoVisitanteNombre}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _partidoService.eliminarPartido(partido.id);
      await _cargarPartidos();
      if (mounted) {
        showSnackBar(context, 'Partido eliminado', color: Colors.green);
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error: ${e.toString()}', color: Colors.red);
      }
    }
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year} - ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  Color _getEstadoColor(String codigo) {
    switch (codigo) {
      case 'programado':
        return Colors.orange;
      case 'en_curso':
        return Colors.green;
      case 'finalizado':
        return Colors.grey;
      case 'suspendido':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getEstadoLabel(String codigo) {
    switch (codigo) {
      case 'programado':
        return 'Programado';
      case 'en_curso':
        return 'En curso';
      case 'finalizado':
        return 'Finalizado';
      case 'suspendido':
        return 'Suspendido';
      default:
        return codigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColorAlt,
      appBar: AppBar(
        title: const Text('Partidos', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.backgroundColorAlt,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primaryColor),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PartidoFormScreen()),
              );
              if (result == true) {
                _cargarPartidos();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : Column(
              children: [
                _buildCalendar(),
                const Divider(color: AppTheme.borderColor),

                // Título con contador
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.list_alt,
                        color: AppTheme.primaryColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Próximos Partidos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_partidos.length} partidos',
                        style: const TextStyle(
                          color: AppTheme.mutedForegroundColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Lista de partidos
                Expanded(
                  child: _partidos.isEmpty
                      ? _buildEmptyView()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: _partidos.length,
                          itemBuilder: (context, index) =>
                              _buildPartidoCard(_partidos[index]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TableCalendar(
        firstDay: DateTime(2024, 1, 1),
        lastDay: DateTime(2030, 12, 31),
        focusedDay: _fechaEnfoque,
        onDaySelected: _onDaySelected,
        onPageChanged: (focusedDay) {
          setState(() {
            _fechaEnfoque = focusedDay;
          });
        },
        calendarFormat: CalendarFormat.month,
        eventLoader: (day) => _eventosCalendario[day] ?? [],
        selectedDayPredicate: (day) {
          return _fechaSeleccionada.year == day.year &&
              _fechaSeleccionada.month == day.month &&
              _fechaSeleccionada.day == day.day;
        },
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
          ),
          weekendTextStyle: const TextStyle(color: Colors.grey),
          defaultTextStyle: const TextStyle(color: Colors.white),
        ),
        headerStyle: const HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
          rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: Colors.grey),
          weekendStyle: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.sports_soccer,
            size: 64,
            color: AppTheme.mutedForegroundColor,
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay partidos programados',
            style: TextStyle(color: AppTheme.mutedForegroundColor),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PartidoFormScreen()),
              );
              if (result == true) {
                _cargarPartidos();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text(
              'Crear partido',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
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
          Text(_errorMessage!, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _cargarPartidos,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text(
              'Reintentar',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartidoCard(PartidoModel partido) {
    final estadoColor = _getEstadoColor(partido.estadoCodigo);
    final estadoLabel = _getEstadoLabel(partido.estadoCodigo);
    final puedeCambiarEstado =
        partido.estadoCodigo != 'finalizado' &&
        partido.estadoCodigo != 'suspendido';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: fecha, hora y estado
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: AppTheme.primaryColor,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatearFecha(partido.fechaHora),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.location_on,
                    color: AppTheme.primaryColor,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    partido.campoNombre,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: estadoColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  estadoLabel,
                  style: TextStyle(
                    color: estadoColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Equipos
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.shield,
                        color: AppTheme.primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      partido.equipoLocalNombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'VS',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.shield,
                        color: AppTheme.primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      partido.equipoVisitanteNombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
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

          const SizedBox(height: 16),

          // Categoría (si tiene)
          if (partido.categoriaId != null &&
              partido.categoriaNombre != 'Amistoso')
            Row(
              children: [
                const Icon(
                  Icons.category,
                  color: AppTheme.mutedForegroundColor,
                  size: 12,
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
            ),

          const SizedBox(height: 16),

          // Botones de acción
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (puedeCambiarEstado)
                _buildActionButton(
                  icon: Icons.swap_horiz,
                  color: Colors.orange,
                  onTap: () => _mostrarMenuEstados(partido),
                ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.edit_outlined,
                color: AppTheme.primaryColor,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PartidoFormScreen(),
                    ),
                  );
                  if (result == true) {
                    _cargarPartidos();
                  }
                },
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.delete_outline,
                color: Colors.redAccent,
                onTap: () => _eliminarPartido(partido),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
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
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  void _mostrarMenuEstados(PartidoModel partido) {
    final opciones = [
      {
        'label': 'Finalizar',
        'estadoId': 'e73aa6c1-ab11-45b1-af27-81e0c3ad2e74',
        'codigo': 'finalizado',
      },
      {
        'label': 'Suspender',
        'estadoId': 'bb3959bf-6593-4a65-8afa-cc12c71f730f',
        'codigo': 'suspendido',
      },
    ];

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
                  leading: Icon(
                    opcion['label'] == 'Finalizar'
                        ? Icons.check_circle_outline
                        : Icons.pause_circle_outline,
                    color: Colors.grey,
                  ),
                  title: Text(
                    opcion['label']!,
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _actualizarEstadoPartido(
                      partido,
                      opcion['estadoId']!,
                      opcion['codigo']!,
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
}
