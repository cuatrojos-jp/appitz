// lib/widgets/avatar_widget.dart
import 'package:flutter/material.dart';

class AvatarWidget extends StatelessWidget {
  final String iniciales;
  final String rolId;

  const AvatarWidget({
    super.key,
    required this.iniciales,
    required this.rolId,
  });

  // UUIDs hardcodeados
  static const String _adminRoleId = 'a0d38955-fa67-4751-a36b-777fcf4d8ed9';
  static const String _jugadorRoleId = 'uuid-jugador';

  Color _getBgColor() {
    if (rolId == _adminRoleId) return const Color(0xFFFFEBEE);
    if (rolId == _jugadorRoleId) return const Color(0xFFE8F5E9);
    return Colors.grey; // Color por defecto para roles desconocidos
  }

  Color _getFgColor() {
    if (rolId == _adminRoleId) return const Color(0xFFC62828);
    if (rolId == _jugadorRoleId) return const Color(0xFF1565C0);
    return Colors.blueGrey; // Color por defecto para roles desconocidos
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: _getBgColor(),
      foregroundColor: _getFgColor(),
      radius: 20,
      child: Text(
        iniciales.length > 2 ? iniciales.substring(0, 2) : iniciales,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}