// lib/screens/estadisticas_screen.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/temporadas_model.dart';
import '../models/estadistica_equipo_model.dart';
import '../services/estadisticas_service.dart';
import '../services/goleo_service.dart';
import '../models/goleo_jugador_model.dart';

// ═══════════════════════════════════════════════════════════════
// PANTALLA PRINCIPAL
// ═══════════════════════════════════════════════════════════════
class EstadisticasScreen extends StatefulWidget {
  final TemporadaModel temporada;

  const EstadisticasScreen({super.key, required this.temporada});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final EstadisticasService _estadisticasService = EstadisticasService();
  Map<String, List<EstadisticaEquipoModel>> _grupos = {};
  bool _isLoading = true;
  String? _error;

  final GoleoService _goleoService = GoleoService();
  List<GoleoJugadorModel> _estadisticasGoleo = [];
  bool _isLoadingGoleo = true;
  String? _errorGoleo;

  bool get _esHistorica =>
      widget.temporada.estadoId == 'af6a7363-5105-4c22-9b03-4f77be807264' ||
      widget.temporada.estadoId == '90f514a4-b43c-4fb1-b327-366b708dd9c2';

  bool get _esActiva =>
      widget.temporada.estadoId == 'a4a0e12b-40b9-4c7a-979b-654e7807e012';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarEstadisticas();
    _cargarEstadisticasGoleo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarEstadisticas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final lista = _esHistorica
          ? await _estadisticasService.obtenerEstadisticasHistoricas(
              widget.temporada.id,
            )
          : await _estadisticasService.obtenerEstadisticasLive(
              widget.temporada.id,
            );

      setState(() {
        _grupos = EstadisticasService.agruparPorCategoria(lista);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _cargarEstadisticasGoleo() async {
    setState(() {
      _isLoadingGoleo = true;
      _errorGoleo = null;
    });
    try {
      final lista = _esHistorica
          ? await _goleoService.obtenerGoleoHistorico(widget.temporada.id)
          : await _goleoService.obtenerGoleoLive(widget.temporada.id);
      setState(() {
        _estadisticasGoleo = lista;
        _isLoadingGoleo = false;
      });
    } catch (e) {
      setState(() {
        _errorGoleo = e.toString();
        _isLoadingGoleo = false;
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColorAlt,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildTabs(),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [_buildStandingsContent(), _buildGoleoContent()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.2),
                  AppTheme.primaryColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.25),
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.bar_chart_rounded,
                color: AppTheme.primaryColor,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estadísticas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  widget.temporada.nombre,
                  style: const TextStyle(
                    color: AppTheme.mutedForegroundColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Chip de fuente de datos
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _esHistorica
                  ? Colors.grey.withValues(alpha: 0.15)
                  : AppTheme.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _esHistorica
                    ? Colors.grey.withValues(alpha: 0.3)
                    : AppTheme.primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _esHistorica ? Icons.history : Icons.circle,
                  size: 8,
                  color: _esHistorica ? Colors.grey : AppTheme.primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  _esHistorica ? 'Histórico' : 'En vivo',
                  style: TextStyle(
                    color: _esHistorica ? Colors.grey : AppTheme.primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tabs ───────────────────────────────────────────────────

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          indicator: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withValues(alpha: 0.2),
                AppTheme.primaryColor.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.4),
            ),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.mutedForegroundColor,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          padding: const EdgeInsets.all(3),
          tabs: const [
            Tab(
              icon: Icon(Icons.table_chart_outlined, size: 16),
              text: 'Tabla General',
            ),
            Tab(
              icon: Icon(Icons.sports_soccer_outlined, size: 16),
              text: 'Goleo',
            ),
          ],
        ),
      ),
    );
  }

  // ── Contenido tabla general ────────────────────────────────

  Widget _buildStandingsContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildError();
    }
    if (_grupos.isEmpty) {
      return _buildEmpty();
    }

    final mostrarCategoria = _esActiva || _esHistorica;

    return RefreshIndicator(
      onRefresh: _cargarEstadisticas,
      color: AppTheme.primaryColor,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
        child: Column(
          children: _grupos.entries.map((entry) {
            return _CategoryTable(
              categoria: entry.key,
              equipos: entry.value,
              mostrarCategoria: mostrarCategoria,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildGoleoContent() {
    if (_isLoadingGoleo) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorGoleo != null) {
      return _buildGoleoError();
    }
    if (_estadisticasGoleo.isEmpty) {
      return _buildGoleoEmpty();
    }

    return RefreshIndicator(
      onRefresh: _cargarEstadisticasGoleo,
      color: AppTheme.primaryColor,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
        child: Column(
          children: [
            _buildGoleoTopMetrics(),
            const SizedBox(height: 20),
            _buildGoleoTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildGoleoTopMetrics() {
    final topGoles = _estadisticasGoleo.isNotEmpty
        ? _estadisticasGoleo.reduce((a, b) => a.goles > b.goles ? a : b)
        : null;
    final topAsistencias = _estadisticasGoleo.isNotEmpty
        ? _estadisticasGoleo.reduce(
            (a, b) => a.asistencias > b.asistencias ? a : b,
          )
        : null;
    final topPenales = _estadisticasGoleo.isNotEmpty
        ? _estadisticasGoleo.reduce((a, b) => a.penales > b.penales ? a : b)
        : null;
    final topAmarillas = _estadisticasGoleo.isNotEmpty
        ? _estadisticasGoleo.reduce((a, b) => a.amarillas > b.amarillas ? a : b)
        : null;
    final topRojas = _estadisticasGoleo.isNotEmpty
        ? _estadisticasGoleo.reduce((a, b) => a.rojas > b.rojas ? a : b)
        : null;

    final validTopGoles = (topGoles != null && topGoles.goles > 0)
        ? topGoles
        : null;
    final validTopAsistencias =
        (topAsistencias != null && topAsistencias.asistencias > 0)
        ? topAsistencias
        : null;
    final validTopPenales = (topPenales != null && topPenales.penales > 0)
        ? topPenales
        : null;
    final validTopAmarillas =
        (topAmarillas != null && topAmarillas.amarillas > 0)
        ? topAmarillas
        : null;
    final validTopRojas = (topRojas != null && topRojas.rojas > 0)
        ? topRojas
        : null;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        TopMetricCard(
          label: 'Máximo Goleador',
          value: validTopGoles != null
              ? '${validTopGoles.nombreCompleto}\n${validTopGoles.goles} goles'
              : '-',
          icon: Icons.sports_soccer,
          iconColor: AppTheme.primaryColor,
        ),
        TopMetricCard(
          label: 'Más Asistencias',
          value: validTopAsistencias != null
              ? '${validTopAsistencias.nombreCompleto}\n${validTopAsistencias.asistencias}'
              : '-',
          icon: Icons.handshake,
          iconColor: const Color(0xFF60A5FA),
        ),
        TopMetricCard(
          label: 'Más Penales',
          value: validTopPenales != null
              ? '${validTopPenales.nombreCompleto}\n${validTopPenales.penales}'
              : '-',
          icon: Icons.sports_soccer,
          iconColor: const Color(0xFFFACC15),
        ),
        TopMetricCard(
          label: 'Más Amarillas',
          value: validTopAmarillas != null
              ? '${validTopAmarillas.nombreCompleto}\n${validTopAmarillas.amarillas}'
              : '-',
          icon: Icons.square,
          iconColor: Colors.orange,
        ),
        TopMetricCard(
          label: 'Más Rojas',
          value: validTopRojas != null
              ? '${validTopRojas.nombreCompleto}\n${validTopRojas.rojas}'
              : '-',
          icon: Icons.square,
          iconColor: Colors.redAccent,
        ),
      ],
    );
  }

  Widget _buildGoleoTable() {
    // Ancho total de la tabla: suma de los anchos de cada columna
    // Jugador: 140 + Goles:60 + Asist:60 + Penales:60 + Amar:60 + Rojas:60 = 440
    const double totalWidth = 440;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título (sin scroll)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tabla de Goleo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Text(
                      '${_estadisticasGoleo.length} jugadores',
                      style: TextStyle(
                        color: AppTheme.mutedForegroundColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Único scroll horizontal para toda la tabla
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: totalWidth,
                child: Column(
                  children: [
                    // Encabezados
                    Container(
                      color: AppTheme.secondaryColor,
                      child: Row(
                        children: [
                          const TableHeader('Jugador', width: 140),
                          const TableHeader('Goles', width: 60),
                          const TableHeader('Asist.', width: 60),
                          const TableHeader('Penales', width: 60),
                          const TableHeader('Amar.', width: 60),
                          const TableHeader('Rojas', width: 60),
                        ],
                      ),
                    ),
                    Container(height: 1, color: AppTheme.borderColor),
                    // Filas
                    ..._estadisticasGoleo.asMap().entries.map((entry) {
                      final index = entry.key;
                      final jugador = entry.value;
                      final isEven = index % 2 == 0;
                      return Column(
                        children: [
                          Container(
                            color: isEven
                                ? AppTheme.cardColor
                                : AppTheme.secondaryColor.withOpacity(0.35),
                            child: Row(
                              children: [
                                PlayerCell(
                                  name: jugador.nombreCompleto,
                                  width: 140,
                                ),
                                StatCell(
                                  value: '${jugador.goles}',
                                  width: 60,
                                  highlight: true,
                                  highlightColor: AppTheme.primaryColor,
                                ),
                                StatCell(
                                  value: '${jugador.asistencias}',
                                  width: 60,
                                ),
                                StatCell(
                                  value: '${jugador.penales}',
                                  width: 60,
                                ),
                                StatCell(
                                  value: '${jugador.amarillas}',
                                  width: 60,
                                  highlight: true,
                                  highlightColor: Colors.orange,
                                ),
                                StatCell(
                                  value: '${jugador.rojas}',
                                  width: 60,
                                  highlight: true,
                                  highlightColor: Colors.redAccent,
                                ),
                              ],
                            ),
                          ),
                          if (index < _estadisticasGoleo.length - 1)
                            Container(
                              height: 1,
                              color: AppTheme.borderColor.withOpacity(0.4),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildGoleoError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar estadísticas de goleo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorGoleo!,
              style: const TextStyle(
                color: AppTheme.mutedForegroundColor,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _cargarEstadisticasGoleo,
              icon: const Icon(
                Icons.refresh,
                size: 16,
                color: AppTheme.primaryColor,
              ),
              label: const Text(
                'Reintentar',
                style: TextStyle(color: AppTheme.primaryColor),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoleoEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Icon(
                Icons.sports_soccer_outlined,
                size: 36,
                color: AppTheme.mutedForegroundColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _esHistorica
                  ? 'Sin estadísticas históricas de goleo'
                  : 'Aún no hay estadísticas de goleo',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _esHistorica
                  ? 'No se encontraron datos de goleo para esta temporada.'
                  : 'Los datos aparecerán conforme se registren partidos finalizados.',
              style: const TextStyle(
                color: AppTheme.mutedForegroundColor,
                fontSize: 13,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _cargarEstadisticasGoleo,
              icon: const Icon(
                Icons.refresh,
                size: 16,
                color: AppTheme.primaryColor,
              ),
              label: const Text(
                'Reintentar',
                style: TextStyle(color: AppTheme.primaryColor),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Estados vacío y error ──────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Icon(
                Icons.bar_chart_outlined,
                size: 36,
                color: AppTheme.mutedForegroundColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _esHistorica
                  ? 'Sin estadísticas guardadas'
                  : 'Aún no hay estadísticas',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _esHistorica
                  ? 'No se encontraron datos históricos\npara esta temporada.'
                  : 'Las estadísticas aparecerán conforme\nse registren partidos finalizados.',
              style: const TextStyle(
                color: AppTheme.mutedForegroundColor,
                fontSize: 13,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _cargarEstadisticas,
              icon: const Icon(
                Icons.refresh,
                size: 16,
                color: AppTheme.primaryColor,
              ),
              label: const Text(
                'Reintentar',
                style: TextStyle(color: AppTheme.primaryColor),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar estadísticas',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(
                color: AppTheme.mutedForegroundColor,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _cargarEstadisticas,
              icon: const Icon(
                Icons.refresh,
                size: 16,
                color: AppTheme.primaryColor,
              ),
              label: const Text(
                'Reintentar',
                style: TextStyle(color: AppTheme.primaryColor),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES PARA GOLEO (CLASES INDEPENDIENTES)
// ═══════════════════════════════════════════════════════════════

class TopMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const TopMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [iconColor.withOpacity(0.2), iconColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withOpacity(0.25)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.mutedForegroundColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(icon, color: iconColor, size: 18),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class TableHeader extends StatelessWidget {
  final String text;
  final double width;

  const TableHeader(this.text, {super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: AppTheme.mutedForegroundColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class PlayerCell extends StatelessWidget {
  final String name;
  final double width;

  const PlayerCell({super.key, required this.name, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      alignment: Alignment.centerLeft,
      child: Text(
        name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class StatCell extends StatelessWidget {
  final String value;
  final double width;
  final bool highlight;
  final Color? highlightColor;

  const StatCell({
    super.key,
    required this.value,
    required this.width,
    this.highlight = false,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlightColor;
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      child: highlight && color != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          : Text(
              value,
              style: TextStyle(
                color: AppTheme.mutedForegroundColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TABLA POR CATEGORÍA
// StatefulWidget para alojar su propio ScrollController horizontal
// ═══════════════════════════════════════════════════════════════
class _CategoryTable extends StatefulWidget {
  final String categoria;
  final List<EstadisticaEquipoModel> equipos;
  final bool mostrarCategoria;

  const _CategoryTable({
    required this.categoria,
    required this.equipos,
    required this.mostrarCategoria,
  });

  @override
  State<_CategoryTable> createState() => _CategoryTableState();
}

class _CategoryTableState extends State<_CategoryTable> {
  // Un solo controlador compartido entre el header y todas las filas
  // → cuando se desliza cualquier fila, las demás se mueven en sincronía
  final ScrollController _hScroll = ScrollController();

  @override
  void dispose() {
    _hScroll.dispose();
    super.dispose();
  }

  // Anchos de columna — la suma (~422px) excede la mayoría de pantallas,
  // activando el scroll horizontal
  static const double _wPos = 36;
  static const double _wName = 110;
  static const double _wStat = 30;
  static const double _wJeg = 34;
  static const double _wDif = 34;
  static const double _wPts = 38;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado de categoría (solo cuando aplica)
        if (widget.mostrarCategoria && widget.categoria != 'Sin categoría') ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                widget.categoria,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.equipos.length} equipos',
                style: const TextStyle(
                  color: AppTheme.mutedForegroundColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ] else
          const SizedBox(height: 4),

        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _hScroll,
            child: SizedBox(
              width: 432,
              child: Column(
                children: [
                  _buildHeader(),
                  Container(height: 1, color: AppTheme.borderColor),
                  ...widget.equipos.asMap().entries.map((entry) {
                    return _AnimatedRow(
                      delay: entry.key * 45,
                      child: Column(
                        children: [
                          _buildRow(
                            equipo: entry.value,
                            posicion: entry.key + 1,
                            isEven: entry.key % 2 == 0,
                          ),
                          if (entry.key < widget.equipos.length - 1)
                            Container(
                              height: 1,
                              color: AppTheme.borderColor.withValues(
                                alpha: 0.4,
                              ),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                            ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  // ── Header row ────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      color: AppTheme.secondaryColor,
      child: Row(
        children: [
          _HeaderCell(text: '#', width: _wPos),
          _HeaderCell(text: 'EQUIPO', width: _wName, alignLeft: true),
          _HeaderCell(text: 'JJ', width: _wStat),
          _HeaderCell(text: 'JG', width: _wStat),
          _HeaderCell(text: 'JE', width: _wStat),
          _HeaderCell(text: 'JEG', width: _wJeg),
          _HeaderCell(text: 'JP', width: _wStat),
          _HeaderCell(text: 'GF', width: _wStat),
          _HeaderCell(text: 'GC', width: _wStat),
          _HeaderCell(text: 'DIF', width: _wDif),
          _HeaderCell(text: 'PTS', width: _wPts, highlighted: true),
        ],
      ),
    );
  }

  // ── Data row ──────────────────────────────────────────────

  Widget _buildRow({
    required EstadisticaEquipoModel equipo,
    required int posicion,
    required bool isEven,
  }) {
    final isTop3 = posicion <= 3;
    final dif = equipo.diferenciaGoles;

    // JEG: null cuando modalidad 11v11 → mostrar '-'
    final jegText = equipo.empatesGanados != null
        ? '${equipo.empatesGanados}'
        : '-';

    final difText = dif > 0 ? '+$dif' : '$dif';
    final difColor = dif > 0
        ? Colors.green
        : dif < 0
        ? Colors.redAccent
        : AppTheme.mutedForegroundColor;

    return Container(
      color: isEven
          ? AppTheme.cardColor
          : AppTheme.secondaryColor.withValues(alpha: 0.35),
      child: Row(
        children: [
          // Posición con medalla para top 3
          SizedBox(
            width: _wPos,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: isTop3
                    ? _Medal(position: posicion)
                    : Text(
                        '$posicion',
                        style: const TextStyle(
                          color: AppTheme.mutedForegroundColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
          // Nombre del equipo
          SizedBox(
            width: _wName,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              child: Text(
                equipo.equipoNombre,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
          _StatCell(text: '${equipo.partidosJugados}', width: _wStat),
          _StatCell(text: '${equipo.ganados}', width: _wStat),
          _StatCell(text: '${equipo.empates}', width: _wStat),
          _StatCell(text: jegText, width: _wJeg),
          _StatCell(text: '${equipo.perdidos}', width: _wStat),
          _StatCell(text: '${equipo.golesFavor}', width: _wStat),
          _StatCell(text: '${equipo.golesContra}', width: _wStat),
          _StatCell(text: difText, width: _wDif, color: difColor),
          _PtsCell(pts: equipo.puntos, width: _wPts),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ANIMACIÓN DE ENTRADA POR FILA
// ═══════════════════════════════════════════════════════════════
class _AnimatedRow extends StatefulWidget {
  final Widget child;
  final int delay;

  const _AnimatedRow({required this.child, this.delay = 0});

  @override
  State<_AnimatedRow> createState() => _AnimatedRowState();
}

class _AnimatedRowState extends State<_AnimatedRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ═══════════════════════════════════════════════════════════════

class _HeaderCell extends StatelessWidget {
  final String text;
  final double width;
  final bool highlighted;
  final bool alignLeft;

  const _HeaderCell({
    required this.text,
    required this.width,
    this.highlighted = false,
    this.alignLeft = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(
        vertical: 10,
        horizontal: alignLeft ? 6 : 0,
      ),
      alignment: alignLeft ? Alignment.centerLeft : Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: highlighted
              ? AppTheme.primaryColor
              : AppTheme.mutedForegroundColor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String text;
  final double width;
  final Color? color;

  const _StatCell({required this.text, required this.width, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color ?? AppTheme.mutedForegroundColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PtsCell extends StatelessWidget {
  final int? pts;
  final double width;

  const _PtsCell({required this.pts, required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.2),
                  AppTheme.primaryColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              pts != null ? '$pts' : '-',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Medal extends StatelessWidget {
  final int position;
  const _Medal({required this.position});

  List<Color> get _colors {
    switch (position) {
      case 1:
        return const [Color(0xFFFFD700), Color(0xFFFFA500)];
      case 2:
        return const [Color(0xFFE8E8E8), Color(0xFFA0A0A0)];
      default:
        return const [Color(0xFFCD7F32), Color(0xFF8B6914)];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: _colors.first.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$position',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
