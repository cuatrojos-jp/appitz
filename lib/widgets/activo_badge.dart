import 'package:flutter/material.dart';

class ActivoBadge extends StatelessWidget {
  final bool activo;

  const ActivoBadge({super.key, required this.activo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: activo 
          ? Colors.green.withValues(alpha: 0.1) 
          : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: activo 
            ? Colors.green.withValues(alpha: 0.3) 
            : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        activo ? 'Activo' : 'Inactivo',
        style: TextStyle(
          fontSize: 10,
          color: activo ? Colors.green.shade700 : Colors.grey.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}