import 'package:flutter/material.dart';
import '../models/Usuario.dart';

class RolBadge extends StatelessWidget {
  final RolUsuario rol;

  const RolBadge({super.key, required this.rol});

  @override
  Widget build(BuildContext context) {
    final colors = {
      RolUsuario.admin: Colors.red,
      RolUsuario.coordinador: Colors.blue,
      RolUsuario.jugador: Colors.green,
    };
    
    final labels = {
      RolUsuario.admin: 'Admin',
      RolUsuario.coordinador: 'Coord',
      RolUsuario.jugador: 'Jugador',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors[rol]?.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors[rol]!.withOpacity(0.3)),
      ),
      child: Text(
        labels[rol]!,
        style: TextStyle(
          fontSize: 10,
          color: colors[rol],
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}