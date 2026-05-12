import 'package:appitz/services/partido_validator.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/temporadas_model.dart';
import '../models/partido_model.dart';
import '../models/equipos_model.dart';
import '../models/campos_model.dart';
import '../models/categorias_model.dart';
import '../services/partido_service.dart';
import '../services/equipo_service.dart';
import '../services/campo_service.dart';
import '../services/categoria_service.dart';
import '../services/temporada_service.dart';
import '../widgets/show_snackbar.dart';

class PartidoFormScreen extends StatefulWidget {
  final PartidoModel? partido;

  const PartidoFormScreen({super.key, this.partido});

  @override
  State<PartidoFormScreen> createState() => _PartidoFormScreenState();
}

class _PartidoFormScreenState extends State<PartidoFormScreen> {
  final PartidoService _partidoService = PartidoService();
  final EquipoService _equipoService = EquipoService();
  final CampoService _campoService = CampoService();
  final CategoriaService _categoriaService = CategoriaService();
  final TemporadaService _temporadaService = TemporadaService();

  List<EquipoModel> _todosEquipos = [];
  List<EquipoModel> _equiposFiltrados = [];
  List<CampoFutbolModel> _todosCampos = [];
  List<CampoFutbolModel> _camposFiltrados = [];
  List<CategoriaModel> _categorias = [];

  // Mapa de equipo_id -> lista de categorías (para modo edición)
  Map<String, List<String>> _categoriasPorEquipo = {};

  String? _selectedEquipoLocalId;
  String? _selectedEquipoVisitanteId;
  String? _selectedCampoId;
  String? _selectedCategoriaId;
  DateTime _selectedFecha = DateTime.now();
  TextEditingController _observacionesController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  bool _esTemporadaActiva = false;
  bool get _esEdicion => widget.partido != null;
  bool _observacionesExcedeLimite = false;
  String _observacionesError = '';

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final campos = await _partidoService.obtenerTodos();
      final contexto = await _temporadaService.obtenerContextoTemporada();
      final esActiva = contexto['esActiva'] as bool;
      final temporada = contexto['temporada'] as TemporadaModel;

      setState(() {
        _todosCampos = campos;
        _camposFiltrados = campos;
        _esTemporadaActiva = esActiva;
        _isLoading = false;
      });

      // Si es temporada activa, cargar categorías y equipos con categorías
      if (esActiva) {
        final categorias = await _categoriaService.obtenerPorTemporada(
          temporada.id,
        );
        final equiposConCategoria = await _partidoService
            .obtenerEquiposConCategoriaEnTemporada(temporada.id);

        setState(() {
          _categorias = categorias;
          _todosEquipos = equiposConCategoria
              .map((e) => e['equipo'] as EquipoModel)
              .toList();

          _categoriasPorEquipo = {
            for (var e in equiposConCategoria)
              (e['equipo'] as EquipoModel).id:
                  (e['categoria_ids'] as List<String>? ?? []),
          };

          _equiposFiltrados = _todosEquipos;
        });
      } else {
        // Temporada programada: cargar todos los equipos sin categorías
        final equipos = await _equipoService.obtenerEquipos();
        setState(() {
          _todosEquipos = equipos;
          _equiposFiltrados = equipos;
        });
      }

      if (_esEdicion) {
        _selectedEquipoLocalId = widget.partido!.equipoLocalId;
        _selectedEquipoVisitanteId = widget.partido!.equipoVisitanteId;
        _selectedCampoId = widget.partido!.campoId;
        _selectedCategoriaId = widget.partido!.categoriaId;
        _selectedFecha = widget.partido!.fechaHora;
        _observacionesController.text = widget.partido!.observaciones ?? '';

        await _filtrarPorCampo();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _filtrarPorCampo() async {
    if (_selectedCampoId == null) return;

    final campo = _todosCampos.firstWhere((c) => c.id == _selectedCampoId);
    final cantidadCampo = campo.cantidad;

    // Filtrar equipos por cantidad compatible
    final equiposCompatibles = _todosEquipos.where((equipo) {
      if (cantidadCampo == '11v11') return true;
      return equipo.cantidad == cantidadCampo;
    }).toList();

    // Si hay categoría seleccionada, filtrar equipos por esa categoría también
    List<EquipoModel> equiposFinal = equiposCompatibles;
    if (_esTemporadaActiva && _selectedCategoriaId != null) {
      equiposFinal = equiposCompatibles.where((equipo) {
        final categoriasEquipo =
            _categoriasPorEquipo[equipo.id] ?? []; // ← Manejar null
        return categoriasEquipo.contains(_selectedCategoriaId);
      }).toList();
    }

    setState(() {
      _equiposFiltrados = equiposFinal;

      // Limpiar selecciones si ya no son compatibles
      if (_selectedEquipoLocalId != null) {
        final localAunCompatible = equiposFinal.any(
          (e) => e.id == _selectedEquipoLocalId,
        );
        if (!localAunCompatible) _selectedEquipoLocalId = null;
      }
      if (_selectedEquipoVisitanteId != null) {
        final visitanteAunCompatible = equiposFinal.any(
          (e) => e.id == _selectedEquipoVisitanteId,
        );
        if (!visitanteAunCompatible) _selectedEquipoVisitanteId = null;
      }
    });
  }

  void _onCategoriaSeleccionada(String? categoriaId) {
    setState(() {
      _selectedCategoriaId = categoriaId;
      _selectedEquipoLocalId = null;
      _selectedEquipoVisitanteId = null;
    });
    _filtrarPorCampo();
  }

  void _validarObservaciones(String value) {
    setState(() {
      if (value.length > PartidoValidator.maxObservacionesLength) {
        _observacionesExcedeLimite = true;
        _observacionesError =
            'Máximo ${PartidoValidator.maxObservacionesLength} caracteres. ';
      } else {
        _observacionesExcedeLimite = false;
        _observacionesError = '';
      }
    });
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedFecha,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.black,
              surface: AppTheme.backgroundColorAlt,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedFecha),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppTheme.primaryColor,
                onPrimary: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        setState(() {
          _selectedFecha = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _guardar() async {
    if (_selectedCampoId == null) {
      showSnackBar(context, 'Selecciona el campo', color: Colors.red);
      return;
    }
    if (_selectedEquipoLocalId == null) {
      showSnackBar(context, 'Selecciona el equipo local', color: Colors.red);
      return;
    }
    if (_selectedEquipoVisitanteId == null) {
      showSnackBar(
        context,
        'Selecciona el equipo visitante',
        color: Colors.red,
      );
      return;
    }
    if (_selectedEquipoLocalId == _selectedEquipoVisitanteId) {
      showSnackBar(
        context,
        'Los equipos deben ser diferentes',
        color: Colors.red,
      );
      return;
    }
    if (_observacionesController.text.length >
        PartidoValidator.maxObservacionesLength) {
      showSnackBar(
        context,
        'Las observaciones exceden el límite de ${PartidoValidator.maxObservacionesLength} caracteres',
        color: Colors.red,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (_esEdicion) {
        await _partidoService.actualizarPartido(
          id: widget.partido!.id,
          campoId: _selectedCampoId,
          equipoLocalId: _selectedEquipoLocalId,
          equipoVisitanteId: _selectedEquipoVisitanteId,
          fechaHora: _selectedFecha,
          categoriaId: _selectedCategoriaId,
          observaciones: _observacionesController.text.trim().isEmpty
              ? null
              : _observacionesController.text.trim(),
        );
        showSnackBar(context, 'Partido actualizado', color: Colors.green);
      } else {
        await _partidoService.crearPartido(
          campoId: _selectedCampoId!,
          equipoLocalId: _selectedEquipoLocalId!,
          equipoVisitanteId: _selectedEquipoVisitanteId!,
          fechaHora: _selectedFecha,
          categoriaId: _selectedCategoriaId,
          observaciones: _observacionesController.text.trim().isEmpty
              ? null
              : _observacionesController.text.trim(),
        );
        showSnackBar(context, 'Partido creado', color: Colors.green);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error: ${e.toString()}', color: Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColorAlt,
      appBar: AppBar(
        title: Text(
          _esEdicion ? 'Editar Partido' : 'Nuevo Partido',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.backgroundColorAlt,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: (_isSaving || _observacionesExcedeLimite) ? null : _guardar,
            child: Text(
              'Guardar',
              style: TextStyle(
                color: (_isSaving || _observacionesExcedeLimite) ? Colors.grey : AppTheme.primaryColor,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dropdown: Campo
                  _buildDropdown(
                    label: 'Campo *',
                    value: _selectedCampoId,
                    items: _todosCampos.map((c) {
                      return DropdownMenuItem(
                        value: c.id,
                        child: Text('${c.nombre} (${c.cantidad})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCampoId = value;
                      });
                      _filtrarPorCampo();
                    },
                  ),
                  const SizedBox(height: 16),

                  // Dropdown: Categoría (solo en temporada activa)
                  if (_esTemporadaActiva && _categorias.isNotEmpty) ...[
                    _buildDropdown(
                      label: 'Categoría *',
                      value: _selectedCategoriaId,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Selecciona una categoría'),
                        ),
                        ..._categorias.map((c) {
                          return DropdownMenuItem(
                            value: c.id,
                            child: Text(c.nombre),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) =>
                          _onCategoriaSeleccionada(value as String?),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Dropdown: Equipo Local
                  _buildDropdown(
                    label: 'Equipo Local *',
                    value: _selectedEquipoLocalId,
                    items: _equiposFiltrados.map((e) {
                      String label = e.nombre;
                      if (_esTemporadaActiva && _selectedCategoriaId != null) {
                        // En temporada activa, el equipo ya está filtrado por categoría
                        label = e.nombre;
                      }
                      return DropdownMenuItem(
                        value: e.id,
                        child: Text('$label (${e.cantidad})'),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() {
                      _selectedEquipoLocalId = value;
                      _selectedEquipoVisitanteId = null;
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Dropdown: Equipo Visitante
                  _buildDropdown(
                    label: 'Equipo Visitante *',
                    value: _selectedEquipoVisitanteId,
                    items: _equiposFiltrados
                        .where((e) => e.id != _selectedEquipoLocalId)
                        .map((e) {
                          String label = e.nombre;
                          if (_esTemporadaActiva &&
                              _selectedCategoriaId != null) {
                            label = e.nombre;
                          }
                          return DropdownMenuItem(
                            value: e.id,
                            child: Text('$label (${e.cantidad})'),
                          );
                        })
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedEquipoVisitanteId = value),
                  ),
                  const SizedBox(height: 16),

                  // Fecha y Hora
                  GestureDetector(
                    onTap: _seleccionarFecha,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _formatearFecha(_selectedFecha),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Observaciones
                  TextFormField(
                    controller: _observacionesController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Observaciones',
                      labelStyle: const TextStyle(
                        color: AppTheme.mutedForegroundColor,
                      ),
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
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 1.5,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required dynamic value,
    required List<DropdownMenuItem> items,
    required Function(dynamic) onChanged,
  }) {
    return DropdownButtonFormField(
      value: value,
      isExpanded: true,
      style: const TextStyle(color: Colors.white),
      dropdownColor: AppTheme.cardColor,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.mutedForegroundColor),
        filled: true,
        fillColor: AppTheme.secondaryColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year} - ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _cargarDatosIniciales,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text(
              'Reintentar',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
