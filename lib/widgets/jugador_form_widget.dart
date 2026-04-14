import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'custom_text_field.dart';

// Widget reutilizable del formulario de jugador
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
  // Selector de fecha
  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      widget.fechaNacimientoController.text =
          '${picked.day}/${picked.month}/${picked.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Campo: Nombre completo
        CustomTextField(
          controller: widget.nombreController,
          label: "Nombre completo",
          keyboardType: TextInputType.name,
        ),
        const SizedBox(height: 16),

        // Campo: Fecha de nacimiento (con selector)
        GestureDetector(
          onTap: () => _seleccionarFecha(context),
          child: AbsorbPointer(
            // Impide edición manual, fuerza usar selector
            child: CustomTextField(
              controller: widget.fechaNacimientoController,
              label: "Fecha de nacimiento",
              keyboardType: TextInputType.none,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Switch: Estadísticas públicas
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Estadísticas públicas",
              style: TextStyle(color: Colors.white),
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
