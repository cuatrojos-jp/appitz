import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Logo y título de la pantalla de registro
class RegisterLogo extends StatelessWidget {
  const RegisterLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primaryColor, Color(0xFF34D399)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.shield_rounded,
                color: AppTheme.backgroundColorAlt,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'APPITZ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Gestiona tu equipo como un profesional',
          style: TextStyle(
            color: AppTheme.mutedForegroundColor,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}