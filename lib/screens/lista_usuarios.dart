import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../screens/usuario_form_screen.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/rol_badge.dart';
import '../widgets/activo_badge.dart';
import '../services/usuario_service.dart';
import '../widgets/show_snackbar.dart';

class UsuariosListScreen extends StatefulWidget {
  const UsuariosListScreen({super.key});

  @override
  State<UsuariosListScreen> createState() => _UsuariosListScreenState();
}

class _UsuariosListScreenState extends State<UsuariosListScreen> {
  final _searchCtrl = TextEditingController();
  String? _rolFiltro;
  late List<UserModel> _lista;
  String _query = '';

  static const String _rolAdminId = 'a0d38955-fa67-4751-a36b-777fcf4d8ed9';
  static const String _rolJugadorId = '6c3d23ab-6228-44b8-8216-6f25ff1b7a4f';

  final UsuarioService _usuarioService = UsuarioService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
    _searchCtrl.addListener(
      () => setState(() => _query = _searchCtrl.text.toLowerCase()),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(fontSize: 14, color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o correo…',
          hintStyle: const TextStyle(color: AppTheme.mutedForegroundColor),
          prefixIcon: const Icon(
            Icons.search,
            size: 18,
            color: AppTheme.mutedForegroundColor,
          ),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () => _searchCtrl.clear(),
                )
              : null,
          filled: true,
          fillColor: AppTheme.secondaryColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(
              color: AppTheme.borderColor,
              width: 0.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: AppTheme.border, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(
              color: AppTheme.primaryColor,
              width: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _RolPill(
            label: 'Todos',
            selected: _rolFiltro == null,
            onTap: () => setState(() => _rolFiltro = null),
          ),
          _RolPill(
            label: 'Jugador',
            selected: _rolFiltro == _rolJugadorId,
            onTap: () => setState(() => _rolFiltro = _rolJugadorId),
          ),
          _RolPill(
            label: 'Coordinador',
            selected: _rolFiltro == _rolAdminId,
            onTap: () => setState(() => _rolFiltro = _rolAdminId),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    if (_filtrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off,
              size: 40,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: 8),
            Text(
              _query.isNotEmpty
                  ? 'Sin resultados para "$_query"'
                  : 'Sin usuarios',
              style: const TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _filtrados.length,
      separatorBuilder: (_, __) =>
          const Divider(indent: 72, endIndent: 0, height: 0),
      itemBuilder: (_, i) {
        final u = _filtrados[i];
        return _UsuarioRow(
          usuario: u,
          onEdit: () => _abrirForm(usuario: u),
          onBaja: () => _toggleBaja(u),
        );
      },
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(_errorMessage!),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _cargarUsuarios,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Future<void> _cargarUsuarios() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final usuarios = await _usuarioService.obtenerTodosLosUsuarios();
      setState(() {
        _lista = usuarios;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<UserModel> get _filtrados => _lista.where((u) {
    final matchQ =
        _query.isEmpty ||
        (u.nombre?.toLowerCase().contains(_query) ?? false) ||
        u.email!.toLowerCase().contains(_query);
    final matchR = _rolFiltro == null || u.rolId == _rolFiltro;
    return matchQ && matchR;
  }).toList();

  Future<void> _abrirForm({UserModel? usuario}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => UsuarioFormScreen(
          usuario: usuario,
          onGuardar: (u) async {},
        ),
      ),
    );

    if (result == true) {
      await _cargarUsuarios();
    }
  }

  Future<void> _toggleBaja(UserModel u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('¿${u.activo ? 'Dar de baja' : 'Reactivar'} usuario?'),
        content: Text(
          '${u.nombre ?? u.email}\n\nEsta acción ${u.activo ? 'impedirá que inicie sesión' : 'permitirá que vuelva a acceder'}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: u.activo ? AppTheme.danger : AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(u.activo ? 'Dar de baja' : 'Reactivar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      if (u.activo) {
        await _usuarioService.desactivarUsuario(u.id);
      } else {
        await _usuarioService.reactivarUsuario(u.id, u.rolId);
      }
      await _cargarUsuarios();

      if (!mounted) return;
      showSnackBar(
        context,
        'Usuario ${!u.activo ? 'activado' : 'dado de baja'}',
        color: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
      );
    } catch (e) {
      if (!mounted) return;
      showSnackBar(
        context,
        'Error: $e',
        color: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.backgroundColorAlt,
    appBar: AppBar(
      backgroundColor: AppTheme.backgroundColorAlt,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Usuarios',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.person_add_outlined),
          tooltip: 'Nuevo usuario',
          onPressed: () => _abrirForm(),
        ),
      ],
    ),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage != null
        ? _buildErrorView()
        : Column(
            children: [
              _buildSearchBar(),
              _buildRoleFilter(),
              Expanded(child: _buildUserList()),
            ],
          ),
  );
}

// ── _UsuarioRow ───────────────────────────────────────────────

class _UsuarioRow extends StatelessWidget {
  final UserModel usuario;
  final VoidCallback onEdit;
  final VoidCallback onBaja;

  const _UsuarioRow({
    required this.usuario,
    required this.onEdit,
    required this.onBaja,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
    leading: AvatarWidget(iniciales: usuario.iniciales, rolId: usuario.rolId),
    title: Text(
      usuario.nombre ?? usuario.email ?? 'Sin nombre',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: usuario.activo ? Colors.white : AppTheme.mutedForegroundColor,
      ),
    ),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          usuario.email ?? 'Sin correo',
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.mutedForegroundColor,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          children: [
            RolBadge(rolId: usuario.rolId),
            ActivoBadge(activo: usuario.activo),
          ],
        ),
      ],
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18),
          color: AppTheme.textSecondary,
          tooltip: 'Editar',
          onPressed: onEdit,
        ),
        IconButton(
          icon: Icon(
            usuario.activo ? Icons.person_off_outlined : Icons.person_outline,
            size: 18,
          ),
          color: usuario.activo
              ? AppTheme.mutedForegroundColor
              : AppTheme.primaryColor,
          tooltip: usuario.activo ? 'Dar de baja' : 'Reactivar',
          onPressed: onBaja,
        ),
      ],
    ),
    onTap: onEdit,
  );
}

class _RolPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RolPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? AppTheme.primaryColor : AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? AppTheme.primaryColor : AppTheme.borderColor,
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: selected ? Colors.white : AppTheme.mutedForegroundColor,
        ),
      ),
    ),
  );
}
