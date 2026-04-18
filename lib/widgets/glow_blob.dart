import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Widget reutilizable para el efecto de glow de fondo
class GlowBlob extends StatelessWidget {
  const GlowBlob({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
      ),
      child: BackdropFilter(
        filter: ColorFilter.mode(
          AppTheme.primaryColor.withValues(alpha: 0.03),
          BlendMode.screen,
        ),
        child: const SizedBox.shrink(),
      ),
    );
  }
}