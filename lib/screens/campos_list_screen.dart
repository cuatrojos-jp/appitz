import 'package:flutter/material.dart';
import '../models/campos_model.dart';
import '../services/campo_service.dart';
import 'nuevo_campo_screen.dart';

class CamposListScreen extends StatefulWidget {
  const CamposListScreen({super.key});

  @override
  State<CamposListScreen> createState() => _CamposListScreenState();
}

class _CamposListScreenState extends State<CamposListScreen> {
  final CampoService _service = CampoService();
  late Future<List<CampoFutbolModel>> _camposFuture;

  // 🎨 COLORES (IGUAL QUE NUEVO CAMPO)
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

 Future<void> _toggleDisponible(
    CampoFutbolModel campo, bool nuevoEstado) async {
  await _service.cambiarDisponibilidad(campo.id!, nuevoEstado);

  setState(() {
    campo.disponible = nuevoEstado;
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: FloatingActionButton(
        backgroundColor: neon,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () async {
          final r = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NuevoCampoScreen()),
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
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                width: 520, // 🔥 MISMO ANCHO QUE NUEVO CAMPO
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
                        // 🔝 HEADER
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
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 24),

                        ...campos.map(_buildCard).toList(),
                        const SizedBox(height: 80),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🎴 CARD EXACTA AL DISEÑO
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
          // 🖼 IMAGEN
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
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
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
                    )
                  ],
                )
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
        style: TextStyle(
          color: Colors.white24,
          fontSize: 13,
        ),
      ),
    );
  }
}