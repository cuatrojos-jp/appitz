import 'package:flutter/material.dart';
import '../models/equipos_model.dart';
import '../services/equipo_service.dart';
import 'nuevo_equipo_screen.dart';

class EquipoListScreen extends StatefulWidget {
  const EquipoListScreen({super.key});

  @override
  State<EquipoListScreen> createState() => _EquipoListScreenState();
}

class _EquipoListScreenState extends State<EquipoListScreen> {
  final EquipoService _service = EquipoService();
  late Future<List<EquipoModel>> _equiposFuture;

  // 🎨 COLORES
  static const Color backgroundColor = Color(0xFF1a1a1a);
  static const Color cardColor = Color(0xFF1e1e1e);
  static const Color neon = Color(0xFF00e676);

  @override
  void initState() {
    super.initState();
    _equiposFuture = _service.obtenerEquipos();
  }

  void _recargar() {
    setState(() {
      _equiposFuture = _service.obtenerEquipos();
    });
  }

  Future<void> _editarEquipo(EquipoModel equipo) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NuevoEquipoScreen(equipo: equipo)),
    );
    if (resultado == true) _recargar();
  }

  Future<void> _eliminarEquipo(EquipoModel equipo) async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F1115),
        title: const Text(
          '¿Eliminar equipo?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Está seguro de que desea eliminar "${equipo.nombre}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirma == true) {
      try {
        await _service.eliminarEquipo(equipo.id);
        _recargar();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('✅ Equipo eliminado')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: FloatingActionButton(
        backgroundColor: neon,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () async {
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NuevoEquipoScreen()),
          );
          if (resultado == true) _recargar();
        },
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF111111), Color(0xFF1b1b1b)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(20),
              child: FutureBuilder<List<EquipoModel>>(
                future: _equiposFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: neon),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.sports_soccer,
                            size: 64,
                            color: Colors.white24,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Sin equipos creados',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Toca el + para agregar tu primer equipo',
                            style: TextStyle(
                              color: Colors.white30,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final equipos = snapshot.data!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔝 HEADER
                      const Text(
                        'Mis Equipos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${equipos.length} equipo${equipos.length != 1 ? 's' : ''} creado${equipos.length != 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 24),

                      ...equipos.map(_buildCard).toList(),
                      const SizedBox(height: 80),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🎴 CARD DEL EQUIPO
  Widget _buildCard(EquipoModel equipo) {
    Color colorPrimario = _hexToColor(equipo.colorPrincipal);
    Color colorSecundario = _hexToColor(equipo.colorSecundario);

    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🎨 COLORES DEL EQUIPO (PREVIEW)
          Container(
            height: 80,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              gradient: LinearGradient(
                colors: [colorPrimario, colorSecundario],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: equipo.escudoUrl != null && equipo.escudoUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Image.network(
                      equipo.escudoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.expand(
                        child: Icon(
                          Icons.shield,
                          color: Colors.white30,
                          size: 40,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.expand(
                    child: Icon(Icons.shield, color: Colors.white30, size: 40),
                  ),
          ),

          // 📝 INFO DEL EQUIPO
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  equipo.nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Modalidad: ${equipo.cantidad}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: colorPrimario,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: colorSecundario,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // 🔘 BOTONES DE ACCIÓN
                Row(
                  children: [
                    // EDITAR
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A6F5C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text(
                          'Editar',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: () => _editarEquipo(equipo),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // ELIMINAR
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6F2A2A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text(
                          'Eliminar',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: () => _eliminarEquipo(equipo),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🎨 CONVERTIR HEX A COLOR
  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}
