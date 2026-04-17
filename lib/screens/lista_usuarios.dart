import 'package:flutter/material.dart';
import '../models/Usuario.dart';
import '../theme/app_theme.dart';
import '../screens/usuario_from_screen.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/rol_badge.dart';
import '../widgets/avatar_utils.dart';
import '../widgets/activo_badge.dart';

class UsuariosListScreen extends StatefulWidget {
  final List<Usuario> usuarios;
  final Future<void> Function(Usuario u) onGuardar;
  final Future<void> Function(String id, bool activo) onToggleBaja;

  const UsuariosListScreen({
    super.key,
    required this.usuarios,
    required this.onGuardar,
    required this.onToggleBaja,
  });

  @override
  State<UsuariosListScreen> createState() => _UsuariosListScreenState();
}

class _UsuariosListScreenState extends State<UsuariosListScreen> {
  final _searchCtrl = TextEditingController();
  RolUsuario? _rolFiltro;
  late List<Usuario> _lista;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _lista = List.from(widget.usuarios);
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.toLowerCase()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Usuario> get _filtrados => _lista.where((u) {
    final matchQ = _query.isEmpty ||
        (u.nombre?.toLowerCase().contains(_query) ?? false) ||
        u.email.toLowerCase().contains(_query);
    final matchR = _rolFiltro == null || u.rol == _rolFiltro;
    return matchQ && matchR;
  }).toList();

  Future<void> _abrirForm({Usuario? usuario}) async {
    final result = await Navigator.push<Usuario>(
      context,
      MaterialPageRoute(
        builder: (_) => UsuarioFormScreen(
          usuario: usuario,
          onGuardar: (u) async {
            await widget.onGuardar(u);
            setState(() {
              final idx = _lista.indexWhere((e) => e.id == u.id);
              if (idx >= 0) _lista[idx] = u; else _lista.insert(0, u);
            });
          },
        ),
      ),
    );
    if (result != null) setState(() {});
  }

  Future<void> _toggleBaja(Usuario u) async {
    final accion = u.activo ? 'dar de baja' : 'reactivar';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('¿${u.activo ? 'Dar de baja' : 'Reactivar'} usuario?'),
        content: Text('${u.nombre ?? u.email}\n\nEsta acción ${u.activo ? 'impedirá que inicie sesión' : 'permitirá que vuelva a acceder'}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: u.activo ? AppColors.danger : AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(u.activo ? 'Dar de baja' : 'Reactivar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.onToggleBaja(u.id, !u.activo);
      setState(() {
        final idx = _lista.indexWhere((e) => e.id == u.id);
        if (idx >= 0) _lista[idx] = _lista[idx].copyWith(activo: !u.activo);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Usuario ${!u.activo ? 'activado' : 'dado de baja'}'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Usuarios'),
      actions: [
        IconButton(
          icon: const Icon(Icons.person_add_outlined),
          tooltip: 'Nuevo usuario',
          onPressed: () => _abrirForm(),
        ),
      ],
    ),
    body: Column(children: [
 // ── Buscador ─────────────────────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: TextField(
          controller: _searchCtrl,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Buscar por nombre o correo…',
            prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textTertiary),
            suffixIcon: _query.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () => _searchCtrl.clear())
              : null,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: AppColors.primary, width: 1.2)),
          ),
        ),
      ),

      // ── Filtro por rol ────────────────────────────────────────
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          Row(children: [
  _RolPill(label: 'Todos',       selected: _rolFiltro == null,                   onTap: () => setState(() => _rolFiltro = null)),
  _RolPill(label: 'Jugador',     selected: _rolFiltro == RolUsuario.jugador,     onTap: () => setState(() => _rolFiltro = RolUsuario.jugador)),
  _RolPill(label: 'Coordinador', selected: _rolFiltro == RolUsuario.coordinador, onTap: () => setState(() => _rolFiltro = RolUsuario.coordinador)),
  _RolPill(label: 'Admin',       selected: _rolFiltro == RolUsuario.admin,       onTap: () => setState(() => _rolFiltro = RolUsuario.admin)),
]),
        ]),
      ),
      const Divider(),

      // ── Lista ─────────────────────────────────────────────────
      Expanded(
        child: _filtrados.isEmpty
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.search_off, size: 40, color: AppColors.textTertiary),
                const SizedBox(height: 8),
                Text(
                  _query.isNotEmpty ? 'Sin resultados para "$_query"' : 'Sin usuarios',
                  style: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
                ),
              ]),
            )
          : ListView.separated(
              itemCount: _filtrados.length,
              separatorBuilder: (_, __) => const Divider(indent: 72, endIndent: 0, height: 0),
              itemBuilder: (_, i) {
                final u = _filtrados[i];
                return _UsuarioRow(
                  usuario: u,
                  onEdit: () => _abrirForm(usuario: u),
                  onBaja: () => _toggleBaja(u),
                );
              },
            ),
      ),
    ]),
  );
}

// ── _UsuarioRow ───────────────────────────────────────────────

class _UsuarioRow extends StatelessWidget {
  final Usuario usuario;
  final VoidCallback onEdit;
  final VoidCallback onBaja;

  const _UsuarioRow({required this.usuario, required this.onEdit, required this.onBaja});

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
    leading: AvatarWidget(
      iniciales: usuario.iniciales,
      bg: avatarBgForRol(usuario.rol),
      fg: avatarFgForRol(usuario.rol),
    ),
    title: Text(
      usuario.nombre ?? usuario.email,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: usuario.activo ? AppColors.textPrimary : AppColors.textSecondary,
      ),
    ),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(usuario.email, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
        const SizedBox(height: 4),
        Wrap(spacing: 4, children: [
          RolBadge(rol: usuario.rol),
          ActivoBadge(activo: usuario.activo),
        ]),
      ],
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18),
          color: AppColors.textSecondary,
          tooltip: 'Editar',
          onPressed: onEdit,
        ),
        IconButton(
          icon: Icon(usuario.activo ? Icons.person_off_outlined : Icons.person_outline, size: 18),
          color: usuario.activo ? AppColors.textSecondary : AppColors.primary,
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

  const _RolPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: 0.5),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: selected ? Colors.white : AppColors.textSecondary)),
    ),
  );
}
