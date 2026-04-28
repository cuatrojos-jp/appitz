import 'package:appitz/screens/jugador_list_screen.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/dashboard_header.dart';
import 'login_screen.dart';
import 'lista_usuarios.dart';

class DashboardScreen extends StatelessWidget {
  final String rolId;
  const DashboardScreen({super.key, required this.rolId});

  @override
  Widget build(BuildContext context) {
    final esAdmin = rolId == 'a0d38955-fa67-4751-a36b-777fcf4d8ed9';
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
              // Volver al login
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
            // Header
            const DashboardHeader(),
            const SizedBox(height: 24),

            // Grid de tarjetas
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
                  ),
                  DashboardCard(
                    title: "Partidos",
                    icon: Icons.calendar_today,
                    color: Colors.purple,
                  ),
                  DashboardCard(
                    title: "Estadísticas",
                    icon: Icons.bar_chart,
                    color: Colors.red,
                  ),
                  DashboardCard(
                    title: "Configuración",
                    icon: Icons.settings,
                    color: Colors.grey,
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
