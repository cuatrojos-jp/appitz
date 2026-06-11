// lib/screens/perfil_jugador_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/estadisticas_jugadores_model.dart';
import '../models/jugador_model.dart';
import '../services/auth_service.dart';
import '../services/estadisticas_jugador_service.dart';
import '../services/jugador_service.dart';
import '../theme/app_theme.dart';
import 'estadisticas_historicas_jugador_screen.dart';

class PerfilJugadorScreen extends StatefulWidget {
  final String? jugadorId;

  const PerfilJugadorScreen({super.key, this.jugadorId});

  @override
  State<PerfilJugadorScreen> createState() => _PerfilJugadorScreenState();
}

class _PerfilJugadorScreenState extends State<PerfilJugadorScreen>
    with SingleTickerProviderStateMixin {
  // ── Servicios ──────────────────────────────────────────────────────────────
  final _supabase = Supabase.instance.client;
  late final JugadorService _jugadorService;
  late final EstadisticasJugadorService _statsService;
  late final AuthService _authService;

  // ── Estado ─────────────────────────────────────────────────────────────────
  JugadorModel? _jugador;
  List<EstadisticasJugadorModel> _estadisticas = [];
  bool _cargando = true;
  bool _modoEdicion = false;
  bool _guardando = false;
  bool _perfilPublico = false;
  bool _esAdmin = false;
  bool _esMiPerfil = false;
  bool _puedeVerEstadisticas = true;
  File? _imagenSeleccionada;

  // ── Controladores de edición ───────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _descripcionCtrl;
  DateTime? _fechaNacimiento;

  // ── Animación ──────────────────────────────────────────────────────────────
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _jugadorService = JugadorService();
    _statsService = EstadisticasJugadorService();
    _authService = AuthService();

    _nombreCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _descripcionCtrl = TextEditingController();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _cargarDatos();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  // ── Carga de datos ─────────────────────────────────────────────────────────
  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final usuarioActualId = await _authService.getUsuarioId();
      if (usuarioActualId == null) return;

      final rolId = await _authService.getRolId(usuarioActualId);
      if (mounted) {
        setState(() => _esAdmin = rolId == 'a0d38955-fa67-4751-a36b-777fcf4d8ed9');
      }

      final jugadorResp = widget.jugadorId != null
          ? await _supabase
              .from('jugadores')
              .select()
              .eq('id', widget.jugadorId as Object)
              .maybeSingle()
          : await _supabase
              .from('jugadores')
              .select()
              .eq('usuario_id', usuarioActualId)
              .maybeSingle();

      if (jugadorResp == null) {
        if (!mounted) return;
        setState(() {
          _jugador = null;
          _estadisticas = [];
          _cargando = false;
        });
        _mostrarError('Aún no tienes un perfil de jugador asociado.');
        return;
      }

      final jugador = JugadorModel.fromJson(jugadorResp);
      _esMiPerfil = jugador.usuarioId == usuarioActualId;
      _puedeVerEstadisticas = _esAdmin || _esMiPerfil || jugador.estadisticasPublicas;

      final stats = _puedeVerEstadisticas
          ? (widget.jugadorId != null
              ? await _statsService.getEstadisticasPorJugador(jugador.id!)
              : await _statsService.getEstadisticasPropias())
          : <EstadisticasJugadorModel>[];

      setState(() {
        _jugador = jugador;
        _estadisticas = stats;
        _sincronizarControladores(jugador);
        _cargando = false;
      });

      _fadeCtrl.forward();
    } catch (e) {
      setState(() => _cargando = false);
      _mostrarError('Error al cargar el perfil');
    }
  }

  void _sincronizarControladores(JugadorModel j) {
    _nombreCtrl.text = j.nombreCompleto;
    _emailCtrl.text = j.emailContacto ?? '';
    _descripcionCtrl.text = j.descripcion ?? '';
    _fechaNacimiento = j.fechaNacimiento;
    _perfilPublico = j.estadisticasPublicas;
  }

  // ── Foto ───────────────────────────────────────────────────────────────────
  Future<void> _seleccionarFoto(ImageSource fuente) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: fuente,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _imagenSeleccionada = File(picked.path));
  }

  void _mostrarOpcionesFoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _opcionFoto(
              icon: Icons.photo_library_rounded,
              label: 'Elegir de galería',
              onTap: () {
                Navigator.pop(context);
                _seleccionarFoto(ImageSource.gallery);
              },
            ),
            _opcionFoto(
              icon: Icons.camera_alt_rounded,
              label: 'Tomar foto',
              onTap: () {
                Navigator.pop(context);
                _seleccionarFoto(ImageSource.camera);
              },
            ),
            if (_jugador?.fotoUrl != null || _imagenSeleccionada != null)
              _opcionFoto(
                icon: Icons.delete_outline_rounded,
                label: 'Eliminar foto',
                color: AppTheme.errorColor,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _imagenSeleccionada = null);
                  if (_jugador != null) {
                    _jugador = JugadorModel(
                      id: _jugador!.id,
                      usuarioId: _jugador!.usuarioId,
                      nombreCompleto: _jugador!.nombreCompleto,
                      emailContacto: _jugador!.emailContacto,
                      fechaNacimiento: _jugador!.fechaNacimiento,
                      fotoUrl: null,
                      activo: _jugador!.activo,
                      estadisticasPublicas: _jugador!.estadisticasPublicas,
                      descripcion: _jugador!.descripcion,
                    );
                  }
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _opcionFoto({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = AppTheme.primaryColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }

  // ── Guardar ────────────────────────────────────────────────────────────────
  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_jugador == null) return;

    setState(() => _guardando = true);
    try {
      String? nuevaFotoUrl = _jugador!.fotoUrl;

      // 1. Subir foto si se seleccionó una nueva
      if (_imagenSeleccionada != null) {
        final bytes = await _imagenSeleccionada!.readAsBytes();
        final path = '${_jugador!.id}/perfil.webp';
        await _supabase.storage
            .from('avatares-jugadores')
            .uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(
                contentType: 'image/webp',
                upsert: true,
              ),
            );
        nuevaFotoUrl = _supabase.storage
            .from('avatares-jugadores')
            .getPublicUrl(path);
      }

      // 2. Actualizar registro
      final actualizado = await _jugadorService.actualizarJugador(
        _jugador!.copyWith(
          nombreCompleto: _nombreCtrl.text.trim(),
          emailContacto: _emailCtrl.text.trim().isEmpty
              ? null
              : _emailCtrl.text.trim(),
          descripcion: _descripcionCtrl.text.trim().isEmpty
              ? null
              : _descripcionCtrl.text.trim(),
          fechaNacimiento: _fechaNacimiento,
          fotoUrl: nuevaFotoUrl,
          estadisticasPublicas: _perfilPublico,
        ),
      );

      setState(() {
        _jugador = actualizado;
        _imagenSeleccionada = null;
        _modoEdicion = false;
        _guardando = false;
      });

      _mostrarExito('Perfil actualizado');
    } catch (e, st) {
      debugPrint('ERROR GUARDAR: $e');
      debugPrint('$st');
      setState(() => _guardando = false);
      _mostrarError('Error al guardar los cambios: $e');
    }
  }

  void _cancelarEdicion() {
    if (_jugador != null) _sincronizarControladores(_jugador!);
    setState(() {
      _modoEdicion = false;
      _imagenSeleccionada = null;
    });
  }

  // ── Date picker ────────────────────────────────────────────────────────────
  Future<void> _seleccionarFecha() async {
    final hoy = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(hoy.year - 20),
      firstDate: DateTime(1940),
      lastDate: hoy,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primaryColor,
            surface: AppTheme.cardColor,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _fechaNacimiento = picked);
  }

  // ── Doble confirmación privacidad ──────────────────────────────────────────
  Future<bool> _confirmarCambioPrivacidad(bool nuevoValor) async {
    final primera = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderColor),
        ),
        title: Text(
          nuevoValor ? 'Hacer perfil público' : 'Hacer perfil privado',
          style: const TextStyle(color: Colors.white, fontSize: 17),
        ),
        content: Text(
          nuevoValor
              ? 'Tu perfil y estadísticas serán visibles para otros jugadores.'
              : 'Tu perfil y estadísticas dejarán de ser visibles para otros jugadores.',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
            child: const Text(
              'Continuar',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (primera != true) return false;

    final segunda = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderColor),
        ),
        title: const Text(
          '¿Estás seguro?',
          style: TextStyle(color: Colors.white, fontSize: 17),
        ),
        content: Text(
          nuevoValor
              ? 'Confirma que deseas que tu perfil sea visible públicamente.'
              : 'Confirma que deseas ocultar tu perfil a otros jugadores.',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
            child: Text(
              nuevoValor ? 'Sí, hacer público' : 'Sí, hacer privado',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    return segunda == true;
  }

  // ── Helpers UI ─────────────────────────────────────────────────────────────
  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarExito(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColorAlt,
      appBar: _buildAppBar(),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _jugador == null
          ? const Center(
              child: Text(
                'No se encontró el perfil',
                style: TextStyle(color: Colors.white54),
              ),
            )
          : FadeTransition(
              opacity: _fadeAnim,
              child: _modoEdicion ? _buildFormulario() : _buildVista(),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.backgroundColorAlt,
      elevation: 0,
      title: Text(
        _modoEdicion
            ? 'Editar perfil'
            : (_esMiPerfil ? 'Mi perfil' : _jugador?.nombreCompleto ?? 'Perfil del jugador'),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      actions: [
        if (!_modoEdicion && _jugador != null && (_esAdmin || _esMiPerfil)) ...[
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor),
            onPressed: () => setState(() => _modoEdicion = true),
          ),
        ],
        if (_modoEdicion) ...[
          TextButton(
            onPressed: _cancelarEdicion,
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: _guardando ? null : _guardar,
            child: _guardando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryColor,
                    ),
                  )
                : const Text(
                    'Guardar',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ],
    );
  }

  // ── Vista de solo lectura ──────────────────────────────────────────────────
  Widget _buildVista() {
    final j = _jugador!;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),

          // Foto
          _buildAvatar(editable: false),
          const SizedBox(height: 16),

          // Nombre
          Text(
            j.nombreCompleto,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),

          // Email
          if (j.emailContacto != null && j.emailContacto!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.mail_outline_rounded,
                  size: 14,
                  color: AppTheme.mutedForegroundColor,
                ),
                const SizedBox(width: 6),
                Text(
                  j.emailContacto!,
                  style: const TextStyle(
                    color: AppTheme.mutedForegroundColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],

          // Fecha de nacimiento
          if (j.fechaNacimiento != null) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cake_outlined,
                  size: 14,
                  color: AppTheme.mutedForegroundColor,
                ),
                const SizedBox(width: 6),
                Text(
                  DateFormat('dd MMM yyyy', 'es').format(j.fechaNacimiento!),
                  style: const TextStyle(
                    color: AppTheme.mutedForegroundColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],

          // Descripción
          if (j.descripcion != null && j.descripcion!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Text(
                j.descripcion!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
            ),
          ],

          const SizedBox(height: 28),

          if (_puedeVerEstadisticas) ...[
            // Estadísticas
            _buildEstadisticas(),
          ] else ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Text(
                'Este perfil mantiene sus estadísticas en privado.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildEstadisticas() {
    int totalGoles = 0;
    int totalAsistencias = 0;
    int totalPenales = 0;
    String temporadaNombre = '';

    if (_estadisticas.isNotEmpty) {
      for (final s in _estadisticas) {
        totalGoles += s.goles;
        totalAsistencias += s.asistencias;
        totalPenales += s.penales;
      }
      if (_estadisticas.length == 1) {
        temporadaNombre = _estadisticas.first.temporadaNombre;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Estadísticas',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (temporadaNombre.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  temporadaNombre,
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statCard(
                label: 'Goles',
                valor: totalGoles,
                icon: Icons.sports_soccer_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                label: 'Asistencias',
                valor: totalAsistencias,
                icon: Icons.assistant_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                label: 'Penales',
                valor: totalPenales,
                icon: Icons.sports_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_puedeVerEstadisticas)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EstadisticasHistoricasJugadorScreen(
                    jugadorId: _jugador?.id,
                  ),
                ),
              ),
            icon: const Icon(
              Icons.history_rounded,
              size: 16,
              color: AppTheme.primaryColor,
            ),
            label: const Text(
              'Ver estadísticas anteriores',
              style: TextStyle(color: AppTheme.primaryColor, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.borderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String label,
    required int valor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 22),
          const SizedBox(height: 8),
          Text(
            '$valor',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.mutedForegroundColor,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ── Formulario de edición ──────────────────────────────────────────────────
  Widget _buildFormulario() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),

            // Foto editable
            _buildAvatar(editable: true),
            const SizedBox(height: 24),

            // Nombre completo
            _campo(
              controller: _nombreCtrl,
              label: 'Nombre completo',
              icon: Icons.person_outline_rounded,
              maxLength: 100,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'El nombre es obligatorio'
                  : null,
            ),
            const SizedBox(height: 14),

            // Email de contacto
            _campo(
              controller: _emailCtrl,
              label: 'Correo de contacto',
              icon: Icons.mail_outline_rounded,
              teclado: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                return regex.hasMatch(v.trim()) ? null : 'Correo no válido';
              },
            ),
            const SizedBox(height: 14),

            // Fecha de nacimiento
            GestureDetector(
              onTap: _seleccionarFecha,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.cake_outlined,
                      color: AppTheme.mutedForegroundColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _fechaNacimiento != null
                          ? DateFormat(
                              'dd MMM yyyy',
                              'es',
                            ).format(_fechaNacimiento!)
                          : 'Fecha de nacimiento',
                      style: TextStyle(
                        color: _fechaNacimiento != null
                            ? Colors.white
                            : AppTheme.mutedForegroundColor,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.mutedForegroundColor,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Descripción
            TextFormField(
              controller: _descripcionCtrl,
              maxLines: 4,
              maxLength: 500,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: _inputDecoration(
                label: 'Descripción',
                icon: Icons.notes_rounded,
              ),
            ),
            const SizedBox(height: 14),

            // Privacidad del perfil
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.visibility_outlined,
                    color: AppTheme.mutedForegroundColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Perfil público',
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _perfilPublico
                              ? 'Visible para otros jugadores'
                              : 'Solo visible para ti',
                          style: const TextStyle(
                            color: AppTheme.mutedForegroundColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _perfilPublico,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (value) async {
                      final confirmado = await _confirmarCambioPrivacidad(
                        value,
                      );
                      if (!confirmado) return;
                      setState(() => _perfilPublico = value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int? maxLength,
    TextInputType teclado = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: teclado,
      maxLength: maxLength,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      validator: validator,
      decoration: _inputDecoration(label: label, icon: icon),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: AppTheme.mutedForegroundColor,
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, color: AppTheme.mutedForegroundColor, size: 20),
      filled: true,
      fillColor: AppTheme.secondaryColor,
      counterStyle: const TextStyle(
        color: AppTheme.mutedForegroundColor,
        fontSize: 11,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.errorColor, width: 1.5),
      ),
    );
  }

  // ── Avatar (compartido entre vista y edición) ──────────────────────────────
  Widget _buildAvatar({required bool editable}) {
    final double radius = 54;

    Widget imagen;
    if (_imagenSeleccionada != null) {
      imagen = CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(_imagenSeleccionada!),
      );
    } else if (_jugador?.fotoUrl != null && _jugador!.fotoUrl!.isNotEmpty) {
      imagen = CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(_jugador!.fotoUrl!),
        backgroundColor: AppTheme.cardColor,
      );
    } else {
      imagen = CircleAvatar(
        radius: radius,
        backgroundColor: AppTheme.cardColor,
        child: Icon(
          Icons.person_rounded,
          size: radius,
          color: AppTheme.mutedForegroundColor,
        ),
      );
    }

    if (!editable) return imagen;

    return GestureDetector(
      onTap: _mostrarOpcionesFoto,
      child: Stack(
        children: [
          imagen,
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.backgroundColorAlt,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 14,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
