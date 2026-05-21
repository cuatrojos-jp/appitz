// lib/screens/dashboard_screen.dart
import 'package:appitz/screens/jugador_list_screen.dart';
import 'package:appitz/screens/bandeja_screen.dart';
import '../services/bandeja_service.dart';
import '../services/auth_service.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/dashboard_header.dart';
import 'login_screen.dart';
import 'lista_usuarios.dart';
import 'temporada_screen.dart';
import 'categorias_list_screen.dart';
import 'campos_list_screen.dart';
import 'partidos_list_screen.dart';
import 'equipo_list_screen.dart';
import 'configuracion_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String rolId;
  const DashboardScreen({super.key, required this.rolId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  final BandejaService _bandejaService = BandejaService();
  final GlobalKey<BandejaScreenState> _bandejaKey = GlobalKey();

  int _selectedIndex = 0;
  bool _tieneNoLeidas = false;

  @override
  void initState() {
    super.initState();
    _verificarNoLeidas();
  }

  Future<void> _verificarNoLeidas() async {
    final usuarioId = await _authService.getUsuarioId();
    if (usuarioId == null) return;

    final count = await _bandejaService.contarNoLeidas(usuarioId);
    if (mounted) {
      setState(() => _tieneNoLeidas = count > 0);
    }
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      _navigateTo(context, ConfiguracionScreen());
      return;
    }
    setState(() => _selectedIndex = index);

    // Al abrir bandeja, refrescar el indicador al volver
    if (index == 1) {
      _bandejaKey.currentState?.cargarNotificaciones();
      Future.delayed(const Duration(milliseconds: 300), _verificarNoLeidas);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esAdmin = widget.rolId == 'a0d38955-fa67-4751-a36b-777fcf4d8ed9';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboard(esAdmin),
          BandejaScreen(
            key: _bandejaKey,
            onNotificacionLeida: _verificarNoLeidas
            ),
          const ConfiguracionScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.borderColor, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: AppTheme.backgroundColorAlt,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: AppTheme.mutedForegroundColor,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_outlined),
                  // if (_tieneNoLeidas)
                  //   Positioned(
                  //     top: -2,
                  //     right: -2,
                  //     child: Container(
                  //       width: 8,
                  //       height: 8,
                  //       decoration: const BoxDecoration(
                  //         color: AppTheme.primaryColor,
                  //         shape: BoxShape.circle,
                  //       ),
                  //     ),
                  //   ),
                ],
              ),
              activeIcon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications),
                  // if (_tieneNoLeidas)
                  //   Positioned(
                  //     top: -2,
                  //     right: -2,
                  //     child: Container(
                  //       width: 8,
                  //       height: 8,
                  //       decoration: const BoxDecoration(
                  //         color: AppTheme.primaryColor,
                  //         shape: BoxShape.circle,
                  //       ),
                  //     ),
                  //   ),
                ],
              ),
              label: 'Bandeja',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Configuración',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(bool esAdmin) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Panel de Control",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.titleTextColor,
          ),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _navigateTo(context, const LoginScreen());
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DashboardHeader(),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  DashboardCard(
                    title: "Equipos",
                    icon: Icons.shield,
                    color: Colors.blue,
                    onTap: () => _navigateTo(context, const EquipoListScreen()),
                  ),
                  DashboardCard(
                    title: "Jugadores",
                    icon: Icons.people,
                    color: Colors.green,
                    onTap: () =>
                        _navigateTo(context, const JugadoresListScreen()),
                  ),
                  DashboardCard(
                    title: "Campos",
                    icon: Icons.sports_soccer,
                    color: Colors.orange,
                    onTap: () => _navigateTo(context, const CamposListScreen()),
                  ),
                  DashboardCard(
                    title: "Partidos",
                    icon: Icons.calendar_today,
                    color: Colors.purple,
                    onTap: () => _navigateTo(context, PartidosListScreen()),
                  ),
                  DashboardCard(
                    title: "Estadísticas",
                    icon: Icons.bar_chart,
                    color: Colors.red,
                  ),
                  DashboardCard(
                    title: "Categorías",
                    icon: Icons.category,
                    color: const Color.fromARGB(255, 190, 106, 134),
                    onTap: () => _navigateTo(context, CategoriasListScreen()),
                  ),
                  DashboardCard(
                    title: "Temporadas",
                    icon: Icons.event,
                    color: Colors.brown,
                    onTap: () => _navigateTo(context, TemporadaScreen()),
                  ),
                  if (esAdmin) ...[
                    DashboardCard(
                      title: "Usuarios",
                      icon: Icons.person,
                      color: Colors.teal,
                      onTap: () =>
                          _navigateTo(context, const UsuariosListScreen()),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }
}
