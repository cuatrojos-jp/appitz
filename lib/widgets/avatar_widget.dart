import 'package:flutter/material.dart';

class AvatarWidget extends StatelessWidget {
  final String iniciales;
  final Color bg;
  final Color fg;

  const AvatarWidget({
    super.key,
    required this.iniciales,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: bg,
      foregroundColor: fg,
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