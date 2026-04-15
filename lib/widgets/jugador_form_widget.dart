import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'custom_text_field.dart';

// Formatter personalizado para formato de fecha DD/MM/YYYY
class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    String formatted = '';
    
    if (text.length >= 1) {
      formatted += text.substring(0, text.length >= 2 ? 2 : text.length);
    }
    
    if (text.length >= 3) {
      formatted += '/' + text.substring(2, text.length >= 4 ? 4 : text.length);
    }
    
    if (text.length >= 5) {
      final yearPart = text.substring(4, text.length >= 8 ? 8 : text.length);
      if (yearPart.isNotEmpty) {
        formatted += '/' + yearPart;
      }
    }
    
    int cursorPosition = formatted.length;
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}

class JugadorFormWidget extends StatefulWidget {
  final TextEditingController nombreController;
  final TextEditingController fechaNacimientoController;
  final bool estadisticasPublicas;
  final ValueChanged<bool> onEstadisticasPublicasChanged;

  const JugadorFormWidget({
    super.key,
    required this.nombreController,
    required this.fechaNacimientoController,
    required this.estadisticasPublicas,
    required this.onEstadisticasPublicasChanged,
  });

  @override
  State<JugadorFormWidget> createState() => _JugadorFormWidgetState();
}

class _JugadorFormWidgetState extends State<JugadorFormWidget> {
  final FocusNode _fechaFocusNode = FocusNode();  // ← FocusNode para detectar foco

  @override
  void initState() {
    super.initState();
    // Escuchar cuando el campo pierde el foco
    _fechaFocusNode.addListener(() {
      if (!_fechaFocusNode.hasFocus) {
        _validarFecha();
      }
    });
  }

  void _validarFecha() {
    final text = widget.fechaNacimientoController.text;
    if (text.isEmpty) return;
    
    final partes = text.split('/');
    if (partes.length == 3) {
      final dia = int.tryParse(partes[0]);
      final mes = int.tryParse(partes[1]);
      final anio = int.tryParse(partes[2]);
      
      if (dia != null && (dia < 1 || dia > 31)) {
        _mostrarError('Día inválido (1-31)');
        widget.fechaNacimientoController.clear();
      }
      else if (mes != null && (mes < 1 || mes > 12)) {
        _mostrarError('Mes inválido (1-12)');
        widget.fechaNacimientoController.clear();
      }
      else if (anio != null && (anio < 1950 || anio > DateTime.now().year)) {
        _mostrarError('Año inválido (1950-${DateTime.now().year})');
        widget.fechaNacimientoController.clear();
      }
    }
  }
  
  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _fechaFocusNode.dispose();  // ← Limpiar FocusNode
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTextField(
          controller: widget.nombreController,
          label: "Nombre completo",
          keyboardType: TextInputType.name,
        ),
        const SizedBox(height: 16),

        // Campo: Fecha de nacimiento con FocusNode
        TextField(
          controller: widget.fechaNacimientoController,
          focusNode: _fechaFocusNode,  // ← Asignar FocusNode
          cursorColor: AppTheme.cursorColor,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppTheme.minorTextColor),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
            DateInputFormatter(),
          ],
          decoration: InputDecoration(
            labelText: "Fecha de nacimiento",
            labelStyle: const TextStyle(color: AppTheme.unfocusedLabelColor),
            floatingLabelStyle: const TextStyle(color: AppTheme.focusedLabelColor),
            hintText: "DD/MM/YYYY",
            hintStyle: const TextStyle(color: Colors.grey),
            border: OutlineInputBorder(
              borderSide: const BorderSide(color: AppTheme.unfocusedBorderColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AppTheme.focusedBorderColor, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Estadísticas públicas",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            Switch(
              value: widget.estadisticasPublicas,
              onChanged: widget.onEstadisticasPublicasChanged,
              activeThumbColor: AppTheme.focusedLabelColor,
            ),
          ],
        ),
      ],
    );
  }
}