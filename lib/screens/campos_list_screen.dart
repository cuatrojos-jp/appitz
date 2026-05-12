import 'package:flutter/material.dart';
import '../models/campos_model.dart';
import '../services/campo_service.dart';
import 'nuevo_campo_screen.dart';
import 'editar_campo_screen.dart';

class CamposListScreen extends StatefulWidget {
  const CamposListScreen({super.key});

  @override
  State<CamposListScreen> createState() => _CamposListScreenState();
}

class _CamposListScreenState extends State<CamposListScreen> {
  final CampoService _service = CampoService();
  late Future<List<CampoFutbolModel>> _camposFuture;

  static const Color backgroundColor = Color(0xFF1a1a1a);
  static const Color cardColor = Color(0xFF1e1e1e);
  static const Color neon = Color(0xFF00e676);

  @override
  void initState() {
    super.initState();
    _camposFuture = _service.obtenerCampos();
  }

  void _recargar() {
    setState(() {
      _camposFuture = _service.obtenerCampos();
    });
  }

  Future<void> _toggleDisponible(CampoFutbolModel campo, bool nuevoEstado) async {
    await _service.cambiarDisponibilidad(campo.id!, nuevoEstado);
    setState(() {
      campo.disponible = nuevoEstado;
    });
  }

  Future<void> _eliminarCampo(CampoFutbolModel campo) async {
    try {
      await _service.eliminarCampo(campo.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Campo eliminado'),
            backgroundColor: neon,
            duration: Duration(seconds: 2),
          ),
        );
        _recargar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarConfirmacionEliminar(CampoFutbolModel campo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text(
            '¿Eliminar campo?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            '¿Estás seguro de que quieres eliminar "${campo.nombre}"?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _eliminarCampo(campo);
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: FloatingActionButton(
        backgroundColor: neon,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () async {
          // ✅ CORREGIDO: Usar NuevoCampoScreen para CREAR
          final r = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NuevoCampoScreen(),
            ),
          );
          if (r == true) _recargar();
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
              child: FutureBuilder<List<CampoFutbolModel>>(
                future: _camposFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: neon),
                    );
                  }

                  final campos = snapshot.data!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Listado de Campos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'campos: nombre, direccion, disponible, foto url',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                      const SizedBox(height: 24),
                      ...campos.map((campo) => _buildCard(campo)).toList(),
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

  Widget _buildCard(CampoFutbolModel campo) {
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
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  color: const Color(0xFF191919),
                  child: campo.fotoUrl != null && campo.fotoUrl!.isNotEmpty
                      ? Image.network(
                          campo.fotoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
              ),
              // ✅ Botón EDITAR (usa EditarCampoScreen con campo)
              Positioned(
                top: 8,
                left: 8,
                child: GestureDetector(
                  onTap: () async {
                    final resultado = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditarCampoScreen(campo: campo),
                      ),
                    );
                    if (resultado == true) _recargar();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: neon.withOpacity(0.85),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.edit,
                      color: Color(0xFF0a0a0a),
                      size: 20,
                    ),
                  ),
                ),
              ),
              // Botón ELIMINAR
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _mostrarConfirmacionEliminar(campo),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.85),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  campo.nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Dirección: ${campo.direccion}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  'Modalidad: ${campo.cantidad}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Switch(
                      value: campo.disponible,
                      onChanged: (v) => _toggleDisponible(campo, v),
                      activeColor: neon,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Disponible',
                      style: TextStyle(
                        color: campo.disponible ? neon : Colors.white38,
                        fontSize: 12,
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

  Widget _placeholder() {
    return const Center(
      child: Text(
        'Sin imagen',
        style: TextStyle(color: Colors.white24, fontSize: 13),
      ),
    );
  }
}