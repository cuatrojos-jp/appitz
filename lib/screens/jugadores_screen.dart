import 'package:flutter/material.dart';
import '../services/jugador_service.dart';
import '../widgets/jugador_form_widget.dart';
import '../models/jugador_model.dart';
import '../theme/app_theme.dart';

// Pantalla para crear/editar un jugador
class JugadoresScreen extends StatefulWidget {
  const JugadoresScreen({super.key});

  @override
  State<JugadoresScreen> createState() => _JugadoresScreenState();
}

class _JugadoresScreenState extends State<JugadoresScreen> {

  // Controladores para los campos del formulario
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _fechaNacimientoController = TextEditingController();

  // Estado del formulario
  bool _estadisticasPublicas = false;
  bool _isLoading = false;

  // Servicio para comunicarse con Supabase
  final JugadorService _jugadorService = JugadorService();

  // Guardar el jugador en Supabase
  Future<void> _guardarJugador() async {
    
    // Validaciones
    if (_nombreController.text.trim().isEmpty) {
      _mostrarError('El nombre es obligatorio');
      return;
    }

    setState(() => _isLoading = true);

    try {

      // Parsear fecha si existe
      DateTime? fechaNacimiento;
      if (_fechaNacimientoController.text.isNotEmpty) {
        final partes = _fechaNacimientoController.text.split('/');
        if (partes.length == 3) {
          fechaNacimiento = DateTime(
            int.parse(partes[2]),
            int.parse(partes[1]),
            int.parse(partes[0]),
          );
        }
      }

      final nuevoJugador = JugadorModel(
        nombreCompleto: _nombreController.text.trim(),
        fechaNacimiento: fechaNacimiento,
        estadisticasPublicas: _estadisticasPublicas,
      );

      await _jugadorService.crearJugador(nuevoJugador);

      if (mounted) {
        // Volver a la pantalla anterior
        Navigator.pop(context, true); // true indica que se creó
      }
    } catch (e) {
      if (mounted) {
        _mostrarError('Error al guardar: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _fechaNacimientoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Agregar Jugador"),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Botón guardar en la barra superior
          TextButton(
            onPressed: _isLoading ? null : _guardarJugador,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    "Guardar",
                    style: TextStyle(
                      color: AppTheme.titleTextColor,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: JugadorFormWidget(
          nombreController: _nombreController,
          fechaNacimientoController: _fechaNacimientoController,
          estadisticasPublicas: _estadisticasPublicas,
          onEstadisticasPublicasChanged: (value) {
            setState(() => _estadisticasPublicas = value);
          },
        ),
      ),
    );
  }
}
