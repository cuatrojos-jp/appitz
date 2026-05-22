// lib/screens/jugador_form_screen.dart
import 'package:flutter/material.dart';
import '../services/jugador_service.dart';
import '../services/equipo_service.dart';
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
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _fechaNacimientoController = TextEditingController();

  bool _estadisticasPublicas = false;
  bool _isLoading = false;
  String? _selectedEquipoId;
  List<EquipoModel> _equipos = [];
  bool _isLoadingEquipos = true;

  final JugadorService _jugadorService = JugadorService();
  final EquipoService _equipoService = EquipoService();

  bool get editando => widget.jugador != null;

  @override
  void initState() {
    super.initState();
    _cargarEquipos();
    
    if (editando) {
      _nombreController.text = widget.jugador!.nombreCompleto;
      _estadisticasPublicas = widget.jugador!.estadisticasPublicas;
      _selectedEquipoId = widget.jugador!.equipoId;
      
      if (widget.jugador!.fechaNacimiento != null) {
        final fecha = widget.jugador!.fechaNacimiento!;
        _fechaNacimientoController.text = '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
      }
    }
  }

  Future<void> _cargarEquipos() async {
    try {
      final equipos = await _equipoService.obtenerEquiposHabilitados();
      setState(() {
        _equipos = equipos;
        _isLoadingEquipos = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingEquipos = false;
      });
      _mostrarError('Error al cargar equipos: $e');
    }
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

      if (editando) {
        // ACTUALIZAR JUGADOR
        final jugadorActualizado = widget.jugador!.copyWith(
          nombreCompleto: _nombreController.text.trim(),
          fechaNacimiento: fechaNacimiento,
          estadisticasPublicas: _estadisticasPublicas,
          equipoId: _selectedEquipoId,
        );
        await _jugadorService.actualizarJugador(jugadorActualizado);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Jugador actualizado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // CREAR JUGADOR
        final nuevoJugador = JugadorModel(
          nombreCompleto: _nombreController.text.trim(),
          fechaNacimiento: fechaNacimiento,
          estadisticasPublicas: _estadisticasPublicas,
          equipoId: _selectedEquipoId,
        );
        await _jugadorService.crearJugador(nuevoJugador);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Jugador creado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) Navigator.pop(context, true);
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
        title: Text(editando ? "Editar Jugador" : "Agregar Jugador"),
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
            // NOMBRE DEL JUGADOR
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
              onTap: () async {
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
              },
            ),
            const SizedBox(height: 20),

            // SELECCIONAR EQUIPO
            const Text(
              "Equipo",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            _isLoadingEquipos
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1D23),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedEquipoId,
                      isExpanded: true,
                      style: const TextStyle(color: Colors.white),
                      dropdownColor: const Color(0xFF1A1D23),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      hint: const Text(
                        "Seleccionar equipo",
                        style: TextStyle(color: Colors.white38),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text("Sin equipo", style: TextStyle(color: Colors.white70)),
                        ),
                        ..._equipos.map((equipo) {
                          return DropdownMenuItem<String>(
                            value: equipo.id,
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: _hexToColor(equipo.colorPrincipal),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    equipo.nombre,
                                    style: const TextStyle(color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedEquipoId = value;
                        });
                      },
                    ),
                  ),
            const SizedBox(height: 20),

            // ESTADÍSTICAS PÚBLICAS
            Row(
              children: [
                Checkbox(
                  value: _estadisticasPublicas,
                  onChanged: (value) {
                    setState(() {
                      _estadisticasPublicas = value ?? false;
                    });
                  },
                  activeColor: AppTheme.focusedLabelColor,
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

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}