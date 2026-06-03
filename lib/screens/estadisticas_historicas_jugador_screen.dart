// lib/screens/estadisticas_historicas_jugador_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/estadisticas_jugadores_model.dart';
import '../services/estadisticas_jugador_service.dart';
import '../services/temporada_service.dart';
import '../models/temporadas_model.dart';
import '../theme/app_theme.dart';

class EstadisticasHistoricasJugadorScreen extends StatefulWidget {
  const EstadisticasHistoricasJugadorScreen({super.key});

  @override
  State<EstadisticasHistoricasJugadorScreen> createState() =>
      _EstadisticasHistoricasJugadorScreenState();
}

class _EstadisticasHistoricasJugadorScreenState
    extends State<EstadisticasHistoricasJugadorScreen> {
  final _statsService = EstadisticasJugadorService();
  final _temporadaService = TemporadaService();

  List<TemporadaModel> _temporadas = [];
  List<EstadisticasJugadorModel> _historico = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      // Corremos ambas consultas en paralelo
      final results = await Future.wait([
        _temporadaService.listarTemporadas(),
        _statsService.getHistoricoPropio(limite: 5),
      ]);

      final todasTemporadas = results[0] as List<TemporadaModel>;
      final historico = results[1] as List<EstadisticasJugadorModel>;

      // Nos quedamos solo con las últimas 5
      final ultimas = todasTemporadas.take(5).toList();

      setState(() {
        _temporadas = ultimas;
        _historico = historico;
        _cargando = false;
      });
    } catch (_) {
      setState(() => _cargando = false);
    }
  }

  EstadisticasJugadorModel? _statsDeTemporada(String temporadaId) {
    try {
      return _historico.firstWhere((s) => s.temporadaId == temporadaId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColorAlt,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColorAlt,
        elevation: 0,
        title: const Text(
          'Estadísticas anteriores',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _temporadas.isEmpty
          ? const Center(
              child: Text(
                'No hay temporadas registradas',
                style: TextStyle(color: Colors.white54),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: _temporadas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final temporada = _temporadas[i];
                final stats = _statsDeTemporada(temporada.id);
                return _TarjetaTemporada(temporada: temporada, stats: stats);
              },
            ),
    );
  }
}

// ── Tarjeta por temporada ────────────────────────────────────────────────────

class _TarjetaTemporada extends StatefulWidget {
  final TemporadaModel temporada;
  final EstadisticasJugadorModel? stats;

  const _TarjetaTemporada({required this.temporada, required this.stats});

  @override
  State<_TarjetaTemporada> createState() => _TarjetaTemporadaState();
}

class _TarjetaTemporadaState extends State<_TarjetaTemporada> {
  bool _expandida = false;

  @override
  Widget build(BuildContext context) {
    final tieneStats = widget.stats != null;

    return GestureDetector(
      onTap: tieneStats ? () => setState(() => _expandida = !_expandida) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _expandida
                ? AppTheme.primaryColor.withOpacity(0.4)
                : AppTheme.borderColor,
          ),
        ),
        child: Column(
          children: [
            // ── Cabecera ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Ícono de temporada
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: tieneStats
                          ? AppTheme.primaryColor.withOpacity(0.12)
                          : AppTheme.secondaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.emoji_events_rounded,
                      color: tieneStats
                          ? AppTheme.primaryColor
                          : AppTheme.mutedForegroundColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Nombre y fechas
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.temporada.nombre,
                          style: TextStyle(
                            color: tieneStats
                                ? Colors.white
                                : AppTheme.mutedForegroundColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        if (widget.temporada.fechaInicio != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            _rangoFechas(
                              widget.temporada.fechaInicio,
                              widget.temporada.fechaFin,
                            ),
                            style: const TextStyle(
                              color: AppTheme.mutedForegroundColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Estado derecho
                  if (!tieneStats)
                    const Text(
                      'Sin estadísticas',
                      style: TextStyle(
                        color: AppTheme.mutedForegroundColor,
                        fontSize: 12,
                      ),
                    )
                  else
                    Icon(
                      _expandida
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.primaryColor,
                    ),
                ],
              ),
            ),

            // ── Estadísticas expandidas ─────────────────────────────────────
            if (_expandida && tieneStats)
              Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppTheme.borderColor)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatItem(
                            label: 'Goles',
                            valor: widget.stats!.goles,
                            icon: Icons.sports_soccer_rounded,
                          ),
                        ),
                        Expanded(
                          child: _StatItem(
                            label: 'Asistencias',
                            valor: widget.stats!.asistencias,
                            icon: Icons.assistant_rounded,
                          ),
                        ),
                        Expanded(
                          child: _StatItem(
                            label: 'Penales',
                            valor: widget.stats!.penales,
                            icon: Icons.sports_rounded,
                          ),
                        ),
                      ],
                    ),
                    if (widget.stats!.cerradoEn != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Cerrada el ${DateFormat('dd MMM yyyy', 'es').format(widget.stats!.cerradoEn!)}',
                        style: const TextStyle(
                          color: AppTheme.mutedForegroundColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _rangoFechas(DateTime? inicio, DateTime? fin) {
    final fmt = DateFormat('MMM yyyy', 'es');
    if (inicio == null) return '';
    if (fin == null) return 'Desde ${fmt.format(inicio)}';
    return '${fmt.format(inicio)} – ${fmt.format(fin)}';
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int valor;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.valor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 18),
        const SizedBox(height: 6),
        Text(
          '$valor',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.mutedForegroundColor,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
