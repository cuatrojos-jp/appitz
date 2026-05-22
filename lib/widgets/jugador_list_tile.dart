// lib/widgets/jugador_list_tile.dart
import 'package:flutter/material.dart';
import '../models/jugador_model.dart';
import '../theme/app_theme.dart';

class JugadorListTile extends StatelessWidget {
  final JugadorModel jugador;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final Map<String, String>? equiposMap; // ← AGREGAR ESTA LÍNEA

  const JugadorListTile({
    super.key,
    required this.jugador,
    required this.onTap,
    this.onDelete,
    this.equiposMap, // ← AGREGAR ESTA LÍNEA
  });

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'Fecha no registrada';
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    // ← AGREGAR ESTAS 2 LÍNEAS
    final equipoNombre = equiposMap?[jugador.equipoId] ?? "Sin equipo";
    final bool tieneEquipo = jugador.equipoId != null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppTheme.unfocusedBorderColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          // ← MODIFICAR EL COLOR
          backgroundColor: tieneEquipo 
              ? AppTheme.focusedLabelColor.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.2),
          child: Icon(
            Icons.person,
            color: tieneEquipo ? AppTheme.focusedLabelColor : Colors.grey,
          ),
        ),
        title: Text(
          jugador.nombreCompleto,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatearFecha(jugador.fechaNacimiento),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 4),
            // ← AGREGAR ESTAS LÍNEAS PARA MOSTRAR EL EQUIPO
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: tieneEquipo ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  equipoNombre,
                  style: TextStyle(
                    color: tieneEquipo ? Colors.green : Colors.grey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              jugador.estadisticasPublicas 
                ? Icons.public 
                : Icons.lock,
              color: jugador.estadisticasPublicas 
                ? Colors.green 
                : Colors.grey,
              size: 18,
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _confirmarEliminacion(context),
                iconSize: 20,
              ),
            ],
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  void _confirmarEliminacion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Eliminar jugador',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Eliminar a ${jugador.nombreCompleto}?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}