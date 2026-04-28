class Validators {
  // Validar nombre
  static String? validarNombre(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es requerido';
    }
    if (value.trim().length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }
    if (value.trim().length > 100) {
      return 'El nombre no puede exceder los 100 caracteres';
    }
    if (RegExp(r'[0-9]').hasMatch(value)) {
      return 'El nombre no debe contener números';
    }
    return null;
  }

  // Validar email
  static String? validarEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El email es requerido';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Ingresa un email válido';
    }
    return null;
  }

  // Validar contraseña (requisitos de seguridad)
  static String? validarPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'La contraseña debe tener al menos una mayúscula';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'La contraseña debe tener al menos una minúscula';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'La contraseña debe tener al menos un número';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'La contraseña debe tener al menos un carácter especial';
    }
    return null;
  }

  // Confirmar contraseña
  static String? confirmarPassword(String? value, String? password) {
    if (value != password) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }
}