// lib/screens/estadisticas_screen.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/temporadas_model.dart';
import '../models/estadistica_equipo_model.dart';
import '../services/estadisticas_service.dart';

class EstadisticasScreen extends StatefulWidget {
  final TemporadaModel temporada;

  const EstadisticasScreen({super.key, required this.temporada});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  final EstadisticasService _estadisticasService = EstadisticasService();

  // Agrupado por categoría → { 'Primera División': [...], 'Segunda': [...] }
  Map<String, List<EstadisticaEquipoModel>> _grupos = {};

  final ScrollController _horizontalScroll = ScrollController();

  bool _isLoading = true;
  String? _error;

  bool get _esHistorica =>
      widget.temporada.estadoId == 'af6a7363-5105-4c22-9b03-4f77be807264' ||
      widget.temporada.estadoId == '90f514a4-b43c-4fb1-b327-366b708dd9c2';

  bool get _esActiva =>
      widget.temporada.estadoId == 'a4a0e12b-40b9-4c7a-979b-654e7807e012';

  @override
  void initState() {
    super.initState();
    _cargarEstadisticas();
  }

  Future<void> _cargarEstadisticas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final List<EstadisticaEquipoModel> lista = _esHistorica
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

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColorAlt,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColorAlt,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estadísticas',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.temporada.nombre,
              style: const TextStyle(
                color: AppTheme.mutedForegroundColor,
                fontSize: 11,
              ),
            ),
          ],
        ),
        // Indicador de fuente de datos
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildError();
    }

    if (_grupos.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      onRefresh: _cargarEstadisticas,
      color: AppTheme.primaryColor,
      child: _esActiva
          ? _buildConCategorias() // ACTI → secciones por categoría
          : _buildListaPlana(), // PROG o histórica → lista plana
    );
  }

  // ── Vista ACTI: secciones colapsables por categoría ────────────────────

  Widget _buildConCategorias() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: _grupos.entries.map((entry) {
        return _buildSeccionCategoria(
          categoria: entry.key,
          equipos: entry.value,
        );
      }).toList(),
    );
  }

  Widget _buildSeccionCategoria({
    required String categoria,
    required List<EstadisticaEquipoModel> equipos,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de categoría
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
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
                categoria,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${equipos.length} equipos',
                style: const TextStyle(
                  color: AppTheme.mutedForegroundColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // Encabezado de columnas
        _buildHeaderColumnas(),
        const SizedBox(height: 4),

        // Filas de equipos
        ...equipos.asMap().entries.map(
          (e) => _buildFilaEquipo(e.value, posicion: e.key + 1),
        ),

        const SizedBox(height: 8),
        const Divider(color: AppTheme.borderColor),
      ],
    );
  }

  // ── Vista PROG / histórica: lista plana ────────────────────────────────

  Widget _buildListaPlana() {
    // En PROG puede haber una sola clave 'Sin categoría'
    final todos = _grupos.values.expand((e) => e).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _buildHeaderColumnas(),
        const SizedBox(height: 4),
        ...todos.asMap().entries.map(
          (e) => _buildFilaEquipo(e.value, posicion: e.key + 1),
        ),
      ],
    );
  }

  // ── Encabezado de columnas ──────────────────────────────────────────────

  Widget _buildHeaderColumnas() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _horizontalScroll,
      child: Container(
        constraints: const BoxConstraints(minWidth: 480),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            SizedBox(width: 24),
            SizedBox(width: 8),
            SizedBox(width: 160),
            _ColHeader('PJ'),
            _ColHeader('G'),
            _ColHeader('E'),
            _ColHeader('P'),
            _ColHeader('GF'),
            _ColHeader('GC'),
            _ColHeader('DG'),
            _ColHeader('Pts'),
          ],
        ),
      ),
    );
  }

  // ── Fila de un equipo ──────────────────────────────────────────────────

  Widget _buildFilaEquipo(EstadisticaEquipoModel e, {required int posicion}) {
    final esPrimero = posicion == 1;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: esPrimero
            ? AppTheme.primaryColor.withValues(alpha: 0.08)
            : AppTheme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: esPrimero
              ? AppTheme.primaryColor.withValues(alpha: 0.3)
              : AppTheme.borderColor,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _horizontalScroll,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Posición
              SizedBox(
                width: 24,
                child: Text(
                  '$posicion',
                  style: TextStyle(
                    color: esPrimero
                        ? AppTheme.primaryColor
                        : AppTheme.mutedForegroundColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),

              // Nombre del equipo
              SizedBox(
                width: 160,
                child: Text(
                  e.equipoNombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Columnas numéricas
              _ColValue('${e.partidosJugados}'),
              _ColValue('${e.ganados}'),
              _ColValue('${e.empates}'),
              _ColValue('${e.perdidos}'),
              _ColValue('${e.golesFavor}'),
              _ColValue('${e.golesContra}'),
              _ColValue(
                e.diferenciaGoles >= 0
                    ? '+${e.diferenciaGoles}'
                    : '${e.diferenciaGoles}',
                color: e.diferenciaGoles > 0
                    ? Colors.green
                    : e.diferenciaGoles < 0
                    ? Colors.red
                    : AppTheme.mutedForegroundColor,
              ),
              _ColValue(e.puntos != null ? '${e.puntos}' : '-', bold: true),
            ],
          ),
        ),
      ),
    );
  }

  // ── Vista vacía ────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    final esHistorica = _esHistorica;

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
              esHistorica
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
              esHistorica
                  ? 'No se encontraron estadísticas históricas\npara esta temporada.'
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

  // ── Vista de error ─────────────────────────────────────────────────────

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

  @override
  void dispose() {
    _horizontalScroll.dispose();
    super.dispose();
  }
}

// ── Widgets auxiliares de tabla ────────────────────────────────────────────

class _ColHeader extends StatelessWidget {
  final String label;
  const _ColHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.mutedForegroundColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ColValue extends StatelessWidget {
  final String value;
  final Color? color;
  final bool bold;

  const _ColValue(this.value, {this.color, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      child: Text(
        value,
        style: TextStyle(
          color: color ?? Colors.white70,
          fontSize: 12,
          fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
