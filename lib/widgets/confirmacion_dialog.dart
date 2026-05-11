// lib/widgets/confirmacion_dialog.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

Future<Map<String, dynamic>?> mostrarDialogoConfirmacion({
  required BuildContext context,
  required String titulo,
  required String contenido,
  bool requiereRazon = false,
  String hintRazon = 'Escribe la razón...',
  String botonConfirmacion = 'Confirmar',
  Color colorConfirmacion = Colors.redAccent,
}) async {
  // Variable para almacenar la razón
  String razon = '';

  // ✅ Usar GlobalKey para el Form - NO TextEditingController, NO FocusNode
  final formKey = GlobalKey<FormState>();

  final resultado = await showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(titulo, style: const TextStyle(color: Colors.white)),
        // ✅ Usar SingleChildScrollView para evitar overflow
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contenido, style: const TextStyle(color: Colors.white70)),
                if (requiereRazon) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: razon,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: hintRazon,
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: AppTheme.secondaryColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.borderColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.borderColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      errorStyle: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                    validator: (value) {
                      if (requiereRazon &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Por favor escribe una razón';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      razon = value?.trim() ?? '';
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // ✅ Simplemente cerrar, sin limpiar nada
              Navigator.pop(ctx, null);
            },
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colorConfirmacion),
            onPressed: () {
              // ✅ Validar y guardar el formulario
              if (formKey.currentState?.validate() ?? false) {
                formKey.currentState?.save();

                // ✅ Cerrar con resultado
                Navigator.pop(ctx, {
                  'confirmado': true,
                  if (requiereRazon) 'razon': razon,
                });
              }
            },
            child: Text(
              botonConfirmacion,
              style: const TextStyle(color: Colors.black),
            ),
          ),
        ],
      );
    },
  );

  return resultado;
}
