import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Widget para los campos de texto de Login

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isPassword;
  final TextInputType keyboardType;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      cursorColor: AppTheme.cursorColor,
      keyboardType: keyboardType,
      textInputAction: isPassword
      ? TextInputAction.done
      : TextInputAction.next,
      style: const TextStyle(
        color: AppTheme.minorTextColor,
        ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppTheme.unfocusedLabelColor,
          ),
        floatingLabelStyle: const TextStyle(
          color: AppTheme.focusedLabelColor,
          ),
        border: OutlineInputBorder(
          borderSide: const BorderSide(
            color: AppTheme.unfocusedBorderColor,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: AppTheme.focusedBorderColor,
            width: 2,
          ),
        ),
      ),
    );
  }
}
