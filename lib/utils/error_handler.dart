import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/show_snackbar.dart';

class AuthErrorHandler {
  static final Map<RegExp, String> _errorMessages = {
    RegExp(r'Invalid login credentials', caseSensitive: false): 
      'Correo electrónico o contraseña incorrectos',
    
    RegExp(r'Email not confirmed', caseSensitive: false): 
      'Debes confirmar tu email antes de iniciar sesión. Revisa tu bandeja de entrada.',
    
    RegExp(r'User already registered', caseSensitive: false): 
      'Ya existe una cuenta con este correo electrónico',
    
    RegExp(r'Password should be at least \d+ characters', caseSensitive: false): 
      'La contraseña debe tener al menos 8 caracteres',
    
    RegExp(r'Email address is not verified', caseSensitive: false): 
      'El correo no ha sido verificado. Revisa tu email.',
    
    RegExp(r'Network error', caseSensitive: false): 
      'Error de conexión. Verifica tu internet.',
    
    RegExp(r'Timeout', caseSensitive: false): 
      'El servidor no responde. Intenta más tarde.',
    
    RegExp(r'JWT expired', caseSensitive: false): 
      'Sesión expirada. Inicia sesión nuevamente.',
  };

  static String getErrorMessage(dynamic error) {
    final errorString = error.toString();
    
    for (final entry in _errorMessages.entries) {
      if (entry.key.hasMatch(errorString)) {
        return entry.value;
      }
    }
    
    // Mensaje por defecto
    return 'Ocurrió un error inesperado. Intenta más tarde.';
  }
  
  static void showErrorSnackBar(BuildContext context, dynamic error) {
    final message = getErrorMessage(error);
    showSnackBar(context, message, color: AppTheme.errorColor);
  }
}