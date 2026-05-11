// lib/screens/equipo_list_screen.dart
import 'package:flutter/material.dart';
import '../models/equipos_model.dart';
import '../services/equipo_service.dart';
import 'nuevo_equipo_screen.dart';
import '../widgets/confirmacion_dialog.dart';

class EquipoListScreen extends StatefulWidget {
  const EquipoListScreen({super.key});

  @override
  State<EquipoListScreen> createState() => _EquipoListScreenState();
}

class _EquipoListScreenState extends State<EquipoListScreen>
    with AutomaticKeepAliveClientMixin {
  // ← Mixin para mantener estado vivo

  final EquipoService _service = EquipoService();
  late Future<List<EquipoModel>> _equiposFuture;

  // 🎨 COLORES
  static const Color backgroundColor = Color(0xFF1a1a1a);
  static const Color cardColor = Color(0xFF1e1e1e);
  static const Color neon = Color(0xFF00e676);
  static const Color disabledBadgeColor = Color(0xFF6F2A2A);
  static const Color enabledBadgeColor = Color(0xFF2A6F5C);

  @override
  bool get wantKeepAlive => true; // ← Para AutomaticKeepAliveClientMixin

  @override
  void initState() {
    super.initState();
    _equiposFuture = _service.obtenerEquipos();
  }

  void _recargar() {
    if (mounted) {
      print('🔵 _recargar llamado, mounted: ${mounted}');
      setState(() {
        // ✅ Crear NUEVO Future para forzar reconstrucción limpia
        _equiposFuture = _service.obtenerEquipos();
      });
    }
  }

  Future<void> _editarEquipo(EquipoModel equipo) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NuevoEquipoScreen(equipo: equipo)),
    );
    if (resultado == true && mounted) _recargar();
  }

  // ============================================================
  // MÉTODOS PARA HABILITAR/DESHABILITAR
  // ============================================================

  Future<void> _deshabilitarEquipo(EquipoModel equipo) async {
    final resultado = await mostrarDialogoConfirmacion(
      context: context,
      titulo: 'Deshabilitar equipo',
      contenido:
          '¿Estás seguro de deshabilitar a "${equipo.nombre}"?\n\n'
          'Un equipo deshabilitado no podrá ser seleccionado en nuevos partidos.',
      requiereRazon: true,
      hintRazon: 'Ej: Equipo suspendido por sanción, falta de jugadores, etc.',
      botonConfirmacion: 'Deshabilitar',
      colorConfirmacion: Colors.redAccent,
    );

    if (resultado == null || resultado['confirmado'] != true) return;

    final razon = resultado['razon'] as String;

    try {
      await _service.deshabilitarEquipo(equipoId: equipo.id, razon: razon);

      if (mounted) {
        _recargar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Equipo deshabilitado'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _habilitarEquipo(EquipoModel equipo) async {
    final resultado = await mostrarDialogoConfirmacion(
      context: context,
      titulo: 'Habilitar equipo',
      contenido:
          '¿Estás seguro de habilitar nuevamente a "${equipo.nombre}"?\n\n'
          'El equipo volverá a estar disponible para seleccionar en partidos.',
      requiereRazon: false,
      botonConfirmacion: 'Habilitar',
      colorConfirmacion: Colors.green,
    );

    if (resultado == null || resultado['confirmado'] != true) return;

    try {
      await _service.habilitarEquipo(equipo.id);

      if (mounted) {
        _recargar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Equipo habilitado'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
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

    if (confirma != true) return;

    try {
      await _service.eliminarEquipo(equipo.id);
      if (mounted) {
        _recargar();
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

  @override
  Widget build(BuildContext context) {
    super.build(context); // ← Importante para AutomaticKeepAliveClientMixin

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
          if (resultado == true && mounted) _recargar();
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

                      // ✅ LISTVIEW.BUILDER en lugar de Column + map
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: equipos.length,
                        itemBuilder: (context, index) =>
                            _buildCard(equipos[index]),
                      ),

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

  // 🎴 CARD DEL EQUIPO (con Key única)
  Widget _buildCard(EquipoModel equipo) {
    Color colorPrimario = _hexToColor(equipo.colorPrincipal);
    Color colorSecundario = _hexToColor(equipo.colorSecundario);

    final bool estaDeshabilitado = !equipo.habilitado;

    return Container(
      key: ValueKey(
        equipo.id,
      ), // ✅ CLAVE ÚNICA para evitar errores de reutilización
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: estaDeshabilitado
              ? Colors.redAccent.withOpacity(0.3)
              : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🎨 COLORES DEL EQUIPO (PREVIEW) con overlay si está deshabilitado
          Stack(
            children: [
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
                        child: Icon(
                          Icons.shield,
                          color: Colors.white30,
                          size: 40,
                        ),
                      ),
              ),
              // Overlay si está deshabilitado
              if (estaDeshabilitado)
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    color: Colors.black.withOpacity(0.6),
                  ),
                  child: const Center(
                    child: Icon(Icons.block, color: Colors.redAccent, size: 32),
                  ),
                ),
            ],
          ),

          // 📝 INFO DEL EQUIPO
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre y badge de estado
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        equipo.nombre,
                        style: TextStyle(
                          color: estaDeshabilitado
                              ? Colors.white54
                              : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: estaDeshabilitado
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    // Badge de estado
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: estaDeshabilitado
                            ? disabledBadgeColor
                            : enabledBadgeColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        estaDeshabilitado ? 'Deshabilitado' : 'Activo',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Modalidad: ${equipo.cantidad}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 6),
                // Mostrar razón si está deshabilitado
                if (estaDeshabilitado && equipo.habilitadoDescripcion != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.redAccent.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.redAccent,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Razón: ${equipo.habilitadoDescripcion}',
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
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
                    // TOGGLE HABILITAR/DESHABILITAR
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: estaDeshabilitado
                              ? enabledBadgeColor // Verde para habilitar
                              : disabledBadgeColor, // Rojo para deshabilitar
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: Icon(
                          estaDeshabilitado ? Icons.play_arrow : Icons.block,
                          size: 16,
                        ),
                        label: Text(
                          estaDeshabilitado ? 'Habilitar' : 'Deshabilitar',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () {
                          if (estaDeshabilitado) {
                            _habilitarEquipo(equipo);
                          } else {
                            _deshabilitarEquipo(equipo);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
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
