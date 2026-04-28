import 'package:flutter/material.dart';

class RolBadge extends StatelessWidget {
  final String rolId;

  const RolBadge({super.key, required this.rolId});

  // UUIDs de roles
  static const String _adminRoleId = 'a0d38955-fa67-4751-a36b-777fcf4d8ed9';
  static const String _jugadorRoleId = '6c3d23ab-6228-44b8-8216-6f25ff1b7a4f';

  String _getLabel() {
    if (rolId == _adminRoleId) return 'Coordinador';  // ← Visualmente Coordinador
    if (rolId == _jugadorRoleId) return 'Jugador';
    return 'Rol desconocido';
  }

  Color _getColor() {
    if (rolId == _adminRoleId) return Colors.red;
    if (rolId == _jugadorRoleId) return Colors.green;
    return Colors.grey; // Color por defecto para roles desconocidos
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final label = _getLabel();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}