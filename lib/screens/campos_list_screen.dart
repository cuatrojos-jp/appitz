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

  // 🎨 COLORES DEL HTML
  static const Color primaryColor = Color(0xFF00e676); // Verde neón
  static const Color secondaryColor = Color(0xFFf5f5f5); // Gris claro
  static const Color textMuted = Color(0xFF999999); // Gris texto
  static const Color backgroundColor = Color(0xFFFAFAFA);

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

  // ✅ ACTUALIZAR DISPONIBILIDAD CORRECTAMENTE
  Future<void> _toggleDisponible(CampoFutbolModel campo, bool nuevoEstado) async {
    try {
      // 1. Actualizar en el servicio/backend
      //await _service.actualizarDisponibilidad(campo.id, nuevoEstado);

      // 2. Actualizar localmente en el modelo
      setState(() {
        campo.disponible = nuevoEstado;
      });

      // 3. Mostrar confirmación
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${campo.nombre} ${nuevoEstado ? 'disponible ✅' : 'no disponible ❌'}',
            ),
            backgroundColor: nuevoEstado ? primaryColor : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Listado de Campos'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.black,
        elevation: 2,
      ),

      // ✅ BOTÓN PARA NUEVO CAMPO
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: () async {
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NuevoCampoScreen(),
            ),
          );
          if (resultado == true) {
            _recargar();
          }
        },
        child: const Icon(Icons.add, color: Colors.black, size: 28),
      ),

      body: FutureBuilder<List<CampoFutbolModel>>(
        future: _camposFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _recargar,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final campos = snapshot.data ?? [];

          if (campos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.sports_soccer,
                    size: 64,
                    color: textMuted,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay campos registrados',
                    style: TextStyle(
                      fontSize: 16,
                      color: textMuted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NuevoCampoScreen(),
                        ),
                      );
                      _recargar();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Crear primer campo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // 📱 GRID DE CAMPOS IGUAL AL HTML
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1, // Cambiar a 2 para dos columnas en pantalla grande
              childAspectRatio: 0.9,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemCount: campos.length,
            itemBuilder: (context, index) {
              final campo = campos[index];
              return _buildDeportivoCard(campo);
            },
          );
        },
      ),
    );
  }

  // 🎴 CARD DEL CAMPO - IGUAL AL DISEÑO HTML
  Widget _buildDeportivoCard(CampoFutbolModel campo) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🖼️ IMAGEN O PLACEHOLDER
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: secondaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: campo.fotoUrl != null && campo.fotoUrl!.isNotEmpty
                ? Image.network(
                    campo.fotoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildImagePlaceholder();
                    },
                  )
                : _buildImagePlaceholder(),
          ),

          // 📋 CONTENIDO DE LA CARD
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🏷️ NOMBRE
                  Text(
                    campo.nombre,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // 📍 DIRECCIÓN
                  Text(
                    'Dirección: ${campo.direccion}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // 🔘 SWITCH DE DISPONIBILIDAD
                  _buildAvailabilitySwitch(campo),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🖼️ PLACEHOLDER PARA IMAGEN
  Widget _buildImagePlaceholder() {
    return Container(
      color: secondaryColor,
      child: const Center(
        child: Text(
          'Sin imagen',
          style: TextStyle(
            fontSize: 14,
            color: textMuted,
          ),
        ),
      ),
    );
  }

  // 🔘 SWITCH DE DISPONIBILIDAD PERSONALIZADO
  Widget _buildAvailabilitySwitch(CampoFutbolModel campo) {
    return GestureDetector(
      onTap: () {
        _toggleDisponible(campo, !campo.disponible);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // Switch animado
            SizedBox(
              width: 50,
              child: Switch(
                value: campo.disponible,
                onChanged: (value) {
                  _toggleDisponible(campo, value);
                },
                activeColor: primaryColor,
                inactiveThumbColor: Colors.grey,
                activeTrackColor: primaryColor.withOpacity(0.3),
              ),
            ),
            const SizedBox(width: 12),
            // Etiqueta
            Text(
              'Disponible',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: campo.disponible ? primaryColor : textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}