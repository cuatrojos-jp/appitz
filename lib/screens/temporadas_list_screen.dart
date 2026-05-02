// lib/screens/temporadas_list_screen.dart
import 'package:flutter/material.dart';
import '../services/temporada_service.dart';
import '../models/temporadas_model.dart';
import '../theme/app_theme.dart';
import 'temporada_form_screen.dart';
import 'temporada_detail_screen.dart';

class TemporadasListScreen extends StatefulWidget {
  const TemporadasListScreen({super.key});

  @override
  State<TemporadasListScreen> createState() => _TemporadasListScreenState();
}

class _TemporadasListScreenState extends State<TemporadasListScreen> {
  final TemporadaService _temporadaService = TemporadaService();
  List<TemporadaModel> _temporadas = [];
  bool _isLoading = true;
  String? _errorMessage;

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

  Color _getEstadoColor(String estadoId) {
    // Colores temporales hasta tener los UUIDs reales
    const activoId = 'a4a0e12b-40b9-4c7a-979b-654e7807e012';
    const finalizadoId = 'af6a7363-5105-4c22-9b03-4f77be807264';
    const suspendidoId = '90f514a4-b43c-4fb1-b327-366b708dd9c2';

    if (estadoId == activoId) return Colors.green;
    if (estadoId == finalizadoId) return Colors.grey;
    if (estadoId == suspendidoId) return Colors.orange;
    return Colors.blue; // Programado por defecto
  }

  String _getEstadoNombre(String estadoId) {
    const activoId = 'a4a0e12b-40b9-4c7a-979b-654e7807e012';
    const finalizadoId = 'af6a7363-5105-4c22-9b03-4f77be807264';
    const suspendidoId = '90f514a4-b43c-4fb1-b327-366b708dd9c2';

    if (estadoId == activoId) return 'Activo';
    if (estadoId == finalizadoId) return 'Finalizado';
    if (estadoId == suspendidoId) return 'Suspendido';
    return 'Programado';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColorAlt,
      appBar: AppBar(
        title: const Text('Temporadas', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.backgroundColorAlt,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : _temporadas.isEmpty
          ? _buildEmptyView()
          : ListView.builder(
              itemCount: _temporadas.length,
              itemBuilder: (context, index) {
                final temporada = _temporadas[index];
                return GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TemporadaDetailScreen(temporada: temporada),
                      ),
                    );
                    if (result == true) {
                      _cargarTemporadas();
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.borderColor,
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                temporada.nombre,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (temporada.fechaInicio != null) ...[
                                Text(
                                  'Inicio: ${_formatFecha(temporada.fechaInicio!)}',
                                  style: const TextStyle(
                                    color: AppTheme.mutedForegroundColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              if (temporada.fechaFin != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Fin: ${_formatFecha(temporada.fechaFin!)}',
                                  style: const TextStyle(
                                    color: AppTheme.mutedForegroundColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getEstadoColor(
                              temporada.estadoId,
                            ).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _getEstadoNombre(temporada.estadoId),
                            style: TextStyle(
                              color: _getEstadoColor(temporada.estadoId),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TemporadaFormScreen(),
            ),
          );
          if (result == true) {
            _cargarTemporadas();
          }
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              child: const Text(
                'Reintentar',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
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
            Icons.calendar_month,
            size: 64,
            color: AppTheme.mutedForegroundColor,
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay temporadas creadas',
            style: TextStyle(color: AppTheme.mutedForegroundColor),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // TODO: Navegar a pantalla de crear temporada
              print('Navegar a crear temporada');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Crear primera temporada'),
          ),
        ],
      ),
    );
  }

  String _formatFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }
}
