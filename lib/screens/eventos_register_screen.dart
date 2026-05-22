// lib/screens/eventos_register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/partido_model.dart';
import '../services/evento_service.dart';
import '../services/auth_service.dart';
import '../models/evento_model.dart';
import 'package:uuid/uuid.dart';

// ── Tipos de evento (hardcoded para evitar queries extra) ──────────────────
// Sincronizar con UUIDs reales de la tabla tipos_evento
const String _idGol = '00ff0913-83be-451a-b138-4b2465a917c7';
const String _idAutogol = '47a55ba0-17a8-46b6-a2a3-6415204c7474';
const String _idAsistencia = '7945842e-5b3d-4321-9390-952e81991927';
const String _idTarjetaRoja = '820b4a52-0cba-4778-8213-32c75012411d';
const String _idSustitucion = 'eea6f4ae-aeb1-4990-875d-4caf3ec76672';
const String _idTarjetaAmarilla = 'f989dd90-6401-4dc4-ad25-7ed16955ea1e';

// ── Modelo de fila del formulario ──────────────────────────────────────────

class _EventoFila {
  final TextEditingController minutoController;
  String? tipoEventoId;
  String? tipoCodigo;
  String? jugadorId; // jugador principal
  String? jugadorNombre;
  String? jugadorSecundarioId; // asistidor / jugador que entra
  String? jugadorSecundarioNombre;
  String? equipoId; // equipo al que pertenece el evento

  _EventoFila() : minutoController = TextEditingController();

  void dispose() => minutoController.dispose();

  int? get minuto {
    final v = int.tryParse(minutoController.text.trim());
    return v;
  }

  bool get requiereJugadorSecundario =>
      tipoCodigo == 'asistencia' || tipoCodigo == 'sustitucion';

  bool get afectaMarcador =>
      tipoCodigo == 'gol' ||
      tipoCodigo == 'autogol' ||
      tipoCodigo == 'asistencia';
}

// ── Pantalla ───────────────────────────────────────────────────────────────

class EventosRegisterScreen extends StatefulWidget {
  final PartidoModel partido;

  const EventosRegisterScreen({super.key, required this.partido});

  @override
  State<EventosRegisterScreen> createState() => _EventosRegisterScreenState();
}

class _EventosRegisterScreenState extends State<EventosRegisterScreen> {
  final EventoService _eventoService = EventoService();
  final AuthService _authService = AuthService();

  List<_EventoFila> _filas = [];
  List<Map<String, dynamic>> _tiposEvento = [];
  List<Map<String, dynamic>> _jugadoresLocal = [];
  List<Map<String, dynamic>> _jugadoresVisitante = [];
  List<EventoModel> _eventosExistentes = [];
  List<Map<String, dynamic>> get _todosLosJugadores => [
    ..._jugadoresLocal,
    ..._jugadoresVisitante,
  ];

  final uuid = Uuid();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _usuarioId;

  // Minuto máximo según cantidad del campo
  int get _minutoMaximo {
    final cantidad = widget.partido.campoCantidad;
    // fútbol 5, 6, 7 → 60 min; fútbol 11 → 90 min (+ tiempo extra futuro)
    if (cantidad == '11v11') return 90;
    return 60;
  }

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    for (final fila in _filas) {
      fila.dispose();
    }
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);

    _usuarioId = await _authService.getUsuarioId();

    final resultados = await Future.wait([
      _eventoService.obtenerTiposEvento(),
      _eventoService.obtenerJugadoresDelPartido(
        equipoLocalId: widget.partido.equipoLocalId,
        equipoVisitanteId: widget.partido.equipoVisitanteId,
      ),
    ]);

    _tiposEvento = resultados[0] as List<Map<String, dynamic>>;
    final jugadores = resultados[1] as List<Map<String, dynamic>>;

    _jugadoresLocal = jugadores
        .where((j) => j['equipo_id'] == widget.partido.equipoLocalId)
        .toList();
    _jugadoresVisitante = jugadores
        .where((j) => j['equipo_id'] == widget.partido.equipoVisitanteId)
        .toList();

    // Empezar con una fila vacía
    _filas = [_EventoFila()];

    setState(() => _isLoading = false);

    final eventosExistentes = await _eventoService.obtenerEventosPorPartido(
      widget.partido.id,
    );
    setState(() {
      _eventosExistentes = eventosExistentes;
    });
  }

  // ── Agregar / eliminar filas ───────────────────────────────────────────

  void _agregarFila() {
    setState(() => _filas.add(_EventoFila()));
    // Scroll al final después del frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _eliminarFila(int index) {
    setState(() {
      _filas[index].dispose();
      _filas.removeAt(index);
    });
  }

  final ScrollController _scrollController = ScrollController();

  // ── Validaciones ───────────────────────────────────────────────────────

  /// Devuelve el minuto de tarjeta roja de un jugador en las filas actuales,
  /// o null si no tiene.
  int? _minutoTarjetaRoja(String jugadorId) {
    for (final fila in _filas) {
      if (fila.jugadorId == jugadorId &&
          fila.tipoCodigo == 'tarjeta_roja' &&
          fila.minuto != null) {
        return fila.minuto;
      }
    }
    for (final evento in _eventosExistentes) {
      if (evento.jugadorId == jugadorId &&
          evento.tipoCodigo == 'tarjeta_roja' &&
          evento.minuto != null) {
        return evento.minuto;
      }
    }
    return null;
  }

  /// Devuelve el minuto en que un jugador fue sustituido (fue jugador_id en
  /// una sustitución), o null si no fue sustituido.
  int? _minutoSustitucion(String jugadorId) {
    for (final fila in _filas) {
      if (fila.jugadorId == jugadorId &&
          fila.tipoCodigo == 'sustitucion' &&
          fila.minuto != null) {
        return fila.minuto;
      }
    }
    return null;
  }

  /// Cuenta tarjetas amarillas de un jugador entre filas actuales
  /// y eventos ya existentes del partido
  int _contarTarjetasAmarillas(String jugadorId) {
    // Filas del formulario actual
    final enFormulario = _filas
        .where(
          (f) => f.jugadorId == jugadorId && f.tipoCodigo == 'tarjeta_amarilla',
        )
        .length;

    // Eventos ya guardados en BD
    final enBD = _eventosExistentes
        .where(
          (e) => e.jugadorId == jugadorId && e.tipoCodigo == 'tarjeta_amarilla',
        )
        .length;

    return enFormulario + enBD;
  }

  /// Verifica si un jugador puede ser registrado como autor de un evento
  /// en el minuto dado. Devuelve un mensaje de error o null si es válido.
  String? _validarJugadorEnMinuto(String jugadorId, int minuto) {
    final minutoRoja = _minutoTarjetaRoja(jugadorId);
    if (minutoRoja != null && minuto > minutoRoja) {
      return 'Este jugador recibió tarjeta roja en el min $minutoRoja';
    }
    final minutoSust = _minutoSustitucion(jugadorId);
    if (minutoSust != null && minuto > minutoSust) {
      return 'Este jugador fue sustituido en el min $minutoSust';
    }
    return null;
  }

  /// Valida todas las filas antes de guardar.
  /// Devuelve lista de errores o lista vacía si todo está bien.
  List<String> _validarTodo() {
    final errores = <String>[];

    for (int i = 0; i < _filas.length; i++) {
      final fila = _filas[i];
      final num = i + 1;

      if (fila.tipoEventoId == null) {
        errores.add('Fila $num: selecciona el tipo de evento.');
        continue;
      }
      if (fila.tipoCodigo == 'tarjeta_amarilla') {
        final amarillas = _contarTarjetasAmarillas(fila.jugadorId!);
        if (amarillas >= 3) {
          errores.add(
            'Fila $num: ${fila.jugadorNombre} ya tiene 2 tarjetas amarillas. '
            'La siguiente infracción debe ser tarjeta roja.'
          );
        }
      }
      if (fila.minuto == null) {
        errores.add('Fila $num: ingresa el minuto.');
        continue;
      }
      if (fila.minuto! < 0) {
        errores.add('Fila $num: el minuto no puede ser negativo.');
        continue;
      }
      if (fila.minuto! > _minutoMaximo) {
        errores.add(
          'Fila $num: minuto máximo $_minutoMaximo para este partido.',
        );
        continue;
      }
      if (fila.jugadorId == null) {
        errores.add('Fila $num: selecciona el jugador principal.');
        continue;
      }
      if (fila.requiereJugadorSecundario && fila.jugadorSecundarioId == null) {
        errores.add('Fila $num: este evento requiere un segundo jugador.');
        continue;
      }
      if (fila.equipoId == null) {
        errores.add('Fila $num: no se pudo determinar el equipo del jugador.');
        continue;
      }

      // Validar tarjeta roja / sustitución previa
      final errorJugador = _validarJugadorEnMinuto(
        fila.jugadorId!,
        fila.minuto!,
      );
      if (errorJugador != null) {
        errores.add('Fila $num: $errorJugador');
      }
    }

    return errores;
  }

  // Colores, labels e iconos para los tipos de eventos
  Color _colorPorTipo(String codigo) {
    switch (codigo) {
      case 'gol':
        return Colors.green;
      case 'autogol':
        return Colors.red;
      case 'asistencia':
        return Colors.lightGreen;
      case 'tarjeta_amarilla':
        return Colors.amber;
      case 'tarjeta_roja':
        return Colors.red;
      case 'sustitucion':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _labelPorTipo(String codigo) {
    switch (codigo) {
      case 'gol':
        return 'Gol';
      case 'autogol':
        return 'Autogol';
      case 'asistencia':
        return 'Asistencia';
      case 'tarjeta_amarilla':
        return 'Tarjeta amarilla';
      case 'tarjeta_roja':
        return 'Tarjeta roja';
      case 'sustitucion':
        return 'Sustitución';
      default:
        return codigo;
    }
  }

  // ── Construir payload para insert ────────────────────────────────────────

  // Asegúrate de importar el paquete uuid en la parte superior del archivo:
  // import 'package:uuid/uuid.dart';

  List<Map<String, dynamic>> _construirPayload() {
    final registros = <Map<String, dynamic>>[];
    final uuid = Uuid(); // ← Generador de UUIDs

    for (final fila in _filas) {
      final minuto = fila.minuto!;
      final jugadorId = fila.jugadorId!;
      final equipoId = fila.equipoId!;
      final esLocal = equipoId == widget.partido.equipoLocalId;

      // Base del registro (sin el campo valido_para_estadisticas_jugador)
      final base = {
        'partido_id': widget.partido.id,
        'tipo_evento_id': fila.tipoEventoId,
        'jugador_id': jugadorId,
        'jugador_secundario_id': fila.jugadorSecundarioId,
        'minuto': minuto,
        'equipo_id': equipoId,
        'registrado_por': _usuarioId,
        'temporada_id': widget.partido.categoriaId,
      };

      switch (fila.tipoCodigo) {
        case 'gol':
        case 'autogol':
          // Generar un ID de grupo único para el par de eventos (gol o autogol)
          final grupoGolId = uuid.v4();

          // Primer registro: el equipo involucrado (quien anota o comete autogol)
          // Para 'gol' → golLocal = true, para 'autogol' → golLocal = false
          final golLocalPrimero = (fila.tipoCodigo == 'gol');
          registros.add({
            ...base,
            'golLocal': golLocalPrimero,
            'grupo_gol_id': grupoGolId,
          });

          // Segundo registro: equipo contrario (recibe el gol o se beneficia del autogol)
          final equipoContrarioId = esLocal
              ? widget.partido.equipoVisitanteId
              : widget.partido.equipoLocalId;
          registros.add({
            ...base,
            'equipo_id': equipoContrarioId,
            'golLocal': !golLocalPrimero, // valor opuesto al primero
            'grupo_gol_id': grupoGolId,
          });
          break;

        case 'asistencia':
          // La asistencia se duplica (comportamiento original) pero sin grupo_gol_id
          registros.add({...base, 'golLocal': true});
          final equipoContrarioId = esLocal
              ? widget.partido.equipoVisitanteId
              : widget.partido.equipoLocalId;
          registros.add({
            ...base,
            'equipo_id': equipoContrarioId,
            'golLocal': false,
          });
          break;

        default:
          // Tarjetas, sustituciones — registro simple
          registros.add({...base, 'golLocal': null});
          break;
      }
    }

    return registros;
  }

  // ── Guardar ───────────────────────────────────────────────────────────

  Future<void> _guardar() async {
    final errores = _validarTodo();
    if (errores.isNotEmpty) {
      _mostrarErrores(errores);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final payload = _construirPayload();
      await _eventoService.registrarEventos(payload);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _mostrarErrores(List<String> errores) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text(
          'Corrige los siguientes errores',
          style: TextStyle(color: Colors.white, fontSize: 15),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: errores
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: Colors.red)),
                        Expanded(
                          child: Text(
                            e,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Entendido',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers de UI ─────────────────────────────────────────────────────

  List<Map<String, dynamic>> _jugadoresPorEquipo(String? equipoId) {
    if (equipoId == null) return _todosLosJugadores;
    if (equipoId == widget.partido.equipoLocalId) return _jugadoresLocal;
    return _jugadoresVisitante;
  }

  String _nombreEquipo(String? equipoId) {
    if (equipoId == widget.partido.equipoLocalId) {
      return widget.partido.equipoLocalNombre;
    }
    if (equipoId == widget.partido.equipoVisitanteId) {
      return widget.partido.equipoVisitanteNombre;
    }
    return 'Equipo';
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColorAlt,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColorAlt,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registrar eventos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${widget.partido.equipoLocalNombre} vs ${widget.partido.equipoVisitanteNombre}',
              style: const TextStyle(
                color: AppTheme.mutedForegroundColor,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: (_isSaving || _isLoading) ? null : _guardar,
            child: Text(
              _isSaving ? 'Guardando...' : 'Guardar todo',
              style: TextStyle(
                color: (_isSaving || _isLoading)
                    ? Colors.grey
                    : AppTheme.primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Lista de filas
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    itemCount: _filas.length,
                    itemBuilder: (context, index) => _buildFila(index),
                  ),
                ),

                // Botón agregar fila
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppTheme.borderColor),
                    ),
                    color: AppTheme.backgroundColorAlt,
                  ),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    MediaQuery.of(context).padding.bottom + 12,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _agregarFila,
                      icon: const Icon(
                        Icons.add,
                        color: AppTheme.primaryColor,
                        size: 18,
                      ),
                      label: const Text(
                        'Agregar evento',
                        style: TextStyle(color: AppTheme.primaryColor),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFila(int index) {
    final fila = _filas[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header fila: número y botón eliminar
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Evento ${index + 1}',
                  style: const TextStyle(
                    color: AppTheme.mutedForegroundColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Indicador de tipo con color
              if (fila.tipoCodigo != null) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _colorPorTipo(fila.tipoCodigo as String),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
              const Spacer(),
              GestureDetector(
                onTap: () => _eliminarFila(index),
                child: const Icon(
                  Icons.close,
                  color: AppTheme.mutedForegroundColor,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Fila: Minuto + Tipo de evento
          Row(
            children: [
              // Minuto
              SizedBox(
                width: 70,
                child: TextFormField(
                  controller: fila.minutoController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: "Min'",
                    labelStyle: const TextStyle(
                      color: AppTheme.mutedForegroundColor,
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: AppTheme.secondaryColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Tipo de evento
              Expanded(
                child: _buildDropdown(
                  value: fila.tipoEventoId,
                  hint: 'Tipo de evento',
                  items: _tiposEvento.map((t) {
                    return DropdownMenuItem<String>(
                      value: t['id'] as String,
                      child: Text(
                        _labelPorTipo(t['codigo'] as String),
                        style: TextStyle(
                          color: _colorPorTipo(t['codigo'] as String),
                          fontSize: 13,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      fila.tipoEventoId = value;
                      fila.tipoCodigo =
                          _tiposEvento.firstWhere(
                                (t) => t['id'] == value,
                              )['codigo']
                              as String;
                      // Limpiar jugadores al cambiar tipo
                      fila.jugadorId = null;
                      fila.jugadorNombre = null;
                      fila.jugadorSecundarioId = null;
                      fila.jugadorSecundarioNombre = null;
                      fila.equipoId = null;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Jugador principal
          _buildDropdownJugador(
            value: fila.jugadorId,
            hint: fila.tipoCodigo == 'sustitucion'
                ? 'Jugador que sale'
                : 'Jugador',
            jugadores: _todosLosJugadores,
            onChanged: (value) {
              setState(() {
                fila.jugadorId = value;
                final jugador = _todosLosJugadores.firstWhere(
                  (j) => j['id'] == value,
                );
                fila.jugadorNombre = jugador['nombre'] as String;
                fila.equipoId = jugador['equipo_id'] as String;
                // Limpiar secundario al cambiar principal
                fila.jugadorSecundarioId = null;
                fila.jugadorSecundarioNombre = null;
              });
            },
            // Advertencia si el jugador tiene roja o sustitución previa
            advertencia: fila.jugadorId != null && fila.minuto != null
                ? _validarJugadorEnMinuto(fila.jugadorId!, fila.minuto!)
                : null,
          ),

          // Jugador secundario (solo si el tipo lo requiere)
          if (fila.requiereJugadorSecundario) ...[
            const SizedBox(height: 10),
            _buildDropdownJugador(
              value: fila.jugadorSecundarioId,
              hint: fila.tipoCodigo == 'sustitucion'
                  ? 'Jugador que entra'
                  : 'Asistidor',
              // Para sustitución: mismo equipo que el principal
              // Para asistencia: mismo equipo que el principal
              jugadores: fila.equipoId != null
                  ? _jugadoresPorEquipo(
                      fila.equipoId,
                    ).where((j) => j['id'] != fila.jugadorId).toList()
                  : [],
              onChanged: (value) {
                setState(() {
                  fila.jugadorSecundarioId = value;
                  final jugador = _todosLosJugadores.firstWhere(
                    (j) => j['id'] == value,
                  );
                  fila.jugadorSecundarioNombre = jugador['nombre'] as String;
                });
              },
            ),
          ],

          // Etiqueta de equipo detectado automáticamente
          if (fila.equipoId != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.shield,
                  size: 11,
                  color: AppTheme.mutedForegroundColor,
                ),
                const SizedBox(width: 4),
                Text(
                  _nombreEquipo(fila.equipoId),
                  style: const TextStyle(
                    color: AppTheme.mutedForegroundColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Dropdown genérico ─────────────────────────────────────────────────

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      dropdownColor: AppTheme.cardColor,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppTheme.mutedForegroundColor,
          fontSize: 13,
        ),
        filled: true,
        fillColor: AppTheme.secondaryColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppTheme.primaryColor,
            width: 1.5,
          ),
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  // ── Dropdown de jugadores con advertencia ─────────────────────────────

  Widget _buildDropdownJugador({
    required String? value,
    required String hint,
    required List<Map<String, dynamic>> jugadores,
    required ValueChanged<String?> onChanged,
    String? advertencia,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          dropdownColor: AppTheme.cardColor,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppTheme.mutedForegroundColor,
              fontSize: 13,
            ),
            filled: true,
            fillColor: advertencia != null
                ? Colors.red.withValues(alpha: 0.08)
                : AppTheme.secondaryColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: advertencia != null ? Colors.red : AppTheme.borderColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: advertencia != null ? Colors.red : AppTheme.borderColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppTheme.primaryColor,
                width: 1.5,
              ),
            ),
          ),
          items: jugadores.map((j) {
            return DropdownMenuItem<String>(
              value: j['id'] as String,
              child: Text(
                j['nombre'] as String,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
        if (advertencia != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 12,
                color: Colors.red,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  advertencia,
                  style: const TextStyle(color: Colors.red, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
