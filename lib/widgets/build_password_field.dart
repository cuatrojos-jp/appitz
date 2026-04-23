import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BuildPasswordField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool show;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const BuildPasswordField({
    super.key,
    required this.label,
    required this.controller,
    required this.show,
    required this.onToggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !show,
          style: const TextStyle(color: Colors.white),
          validator: 
            validator ?? 
            (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: const TextStyle(color: AppTheme.mutedForegroundColor),
            prefixIcon: const Icon(
              Icons.lock_outline_rounded, color: 
              AppTheme.mutedForegroundColor, size: 20
              ),
            suffixIcon: IconButton(
              icon: Icon(
                show 
                  ? Icons.visibility_off_outlined 
                  : Icons.visibility_outlined,
                color: AppTheme.mutedForegroundColor,
                size: 20,
              ),
              onPressed: onToggle,
            ),
            filled: true,
            fillColor: AppTheme.secondaryColor,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppTheme.borderColor
                ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppTheme.primaryColor, 
                width: 2
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Colors.redAccent, 
                width: 1.5
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Colors.redAccent, 
                width: 1.5
                ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, 
              vertical: 14
            ),
          ),
        ),
      ],
    );
  }
}