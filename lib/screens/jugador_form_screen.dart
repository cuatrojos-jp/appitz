// lib/screens/jugador_form_screen.dart
import 'package:flutter/material.dart';
import '../services/jugador_service.dart';
import '../services/equipo_service.dart';
import '../services/jugador_equipo_service.dart';
import '../models/jugador_model.dart';
import '../models/equipos_model.dart';
import '../theme/app_theme.dart';

class JugadorFormScreen extends StatefulWidget {
  final JugadorModel? jugador;

  const JugadorFormScreen({super.key, this.jugador});

  @override
  State<JugadorFormScreen> createState() => _JugadorFormScreenState();
}

class _JugadorFormScreenState extends State<JugadorFormScreen> {
  // Controladores
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _fechaNacimientoController =
      TextEditingController();

  // Estado del formulario
  bool _estadisticasPublicas = false;
  bool _isLoading = false;
  bool _editando = false;

  // Equipos y selección múltiple
  List<EquipoModel> _todosEquipos = [];
  List<String> _selectedEquipoIds = [];
  bool _isLoadingEquipos = true;

  // Servicios
  final JugadorService _jugadorService = JugadorService();
  final EquipoService _equipoService = EquipoService();
  final JugadorEquipoService _jugadorEquipoService = JugadorEquipoService();

  @override
  void initState() {
    super.initState();
    _editando = widget.jugador != null;

    if (_editando) {
      _nombreController.text = widget.jugador!.nombreCompleto;
      _estadisticasPublicas = widget.jugador!.estadisticasPublicas;
      if (widget.jugador!.fechaNacimiento != null) {
        final fecha = widget.jugador!.fechaNacimiento!;
        _fechaNacimientoController.text =
            '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
      }
    }

    _cargarEquipos();
    if (_editando) {
      _cargarEquiposDelJugador();
    }
  }

  Future<void> _cargarEquipos() async {
    try {
      final equipos = await _equipoService
          .obtenerEquipos(); // todos los equipos
      setState(() {
        _todosEquipos = equipos;
        _isLoadingEquipos = false;
      });
    } catch (e) {
      setState(() => _isLoadingEquipos = false);
      _mostrarError('Error al cargar equipos: $e');
    }
  }

  Future<void> _cargarEquiposDelJugador() async {
    final equipos = await _jugadorEquipoService.obtenerEquiposPorJugador(
      widget.jugador!.id!,
    );
    setState(() {
      _selectedEquipoIds = equipos.map((e) => e.id).toList();
    });
  }

  void _mostrarSelectorEquipos() {
    Set<String> tempSeleccionados = Set.from(_selectedEquipoIds);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          return AlertDialog(
            title: const Text(
              'Seleccionar equipos',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppTheme.cardColor,
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: _todosEquipos.map((equipo) {
                  return CheckboxListTile(
                    title: Text(
                      equipo.nombre,
                      style: const TextStyle(color: Colors.white),
                    ),
                    value: tempSeleccionados.contains(equipo.id),
                    onChanged: (checked) {
                      setStateDialog(() {
                        if (checked == true) {
                          tempSeleccionados.add(equipo.id);
                        } else {
                          tempSeleccionados.remove(equipo.id);
                        }
                      });
                    },
                    activeColor: AppTheme.primaryColor,
                    checkColor: Colors.black,
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedEquipoIds = tempSeleccionados.toList();
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Aceptar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _guardarJugador() async {
    if (_nombreController.text.trim().isEmpty) {
      _mostrarError('El nombre es obligatorio');
      return;
    }

    setState(() => _isLoading = true);

    try {
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

      String jugadorId;

      if (_editando) {
        // Actualizar jugador
        final jugadorActualizado = widget.jugador!.copyWith(
          nombreCompleto: _nombreController.text.trim(),
          fechaNacimiento: fechaNacimiento,
          estadisticasPublicas: _estadisticasPublicas,
        );
        await _jugadorService.actualizarJugador(jugadorActualizado);
        jugadorId = widget.jugador!.id!;
      } else {
        // Crear nuevo jugador
        final nuevoJugador = JugadorModel(
          nombreCompleto: _nombreController.text.trim(),
          fechaNacimiento: fechaNacimiento,
          estadisticasPublicas: _estadisticasPublicas,
        );
        final creado = await _jugadorService.crearJugador(nuevoJugador);
        jugadorId = creado.id!;
      }

      // Actualizar asignaciones de equipos
      await _jugadorEquipoService.asignarEquiposAJugador(
        jugadorId,
        _selectedEquipoIds,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _editando ? '✅ Jugador actualizado' : '✅ Jugador creado',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _mostrarError('Error al guardar: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  Future<void> _seleccionarFecha() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      _fechaNacimientoController.text =
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(_editando ? "Editar Jugador" : "Agregar Jugador"),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // NOMBRE
            const Text(
              "Nombre Completo *",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nombreController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Ej: Juan Pérez"),
              maxLength: 50,
            ),
            const SizedBox(height: 20),

            // FECHA DE NACIMIENTO
            const Text(
              "Fecha de Nacimiento",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _fechaNacimientoController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("DD/MM/AAAA"),
              readOnly: true,
              onTap: _seleccionarFecha,
            ),
            const SizedBox(height: 20),

            // SELECCIÓN MÚLTIPLE DE EQUIPOS
            const Text("Equipos", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            _isLoadingEquipos
                ? const Center(child: CircularProgressIndicator())
                : GestureDetector(
                    onTap: _mostrarSelectorEquipos,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1D23),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedEquipoIds.isEmpty
                                ? "Ningún equipo seleccionado"
                                : "${_selectedEquipoIds.length} equipo(s) seleccionado(s)",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.white70,
                          ),
                        ],
                      ),
                    ),
                  ),
            const SizedBox(height: 20),

            // ESTADÍSTICAS PÚBLICAS
            Row(
              children: [
                Checkbox(
                  value: _estadisticasPublicas,
                  onChanged: (value) {
                    setState(() => _estadisticasPublicas = value ?? false);
                  },
                  activeColor: AppTheme.primaryColor,
                  checkColor: Colors.black,
                ),
                const Text(
                  "Permitir que otros vean sus estadísticas",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF1A1D23),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }
}
