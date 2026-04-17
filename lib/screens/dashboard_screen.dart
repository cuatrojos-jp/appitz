import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/dashboard_header.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Panel de Control",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.titleTextColor,
          ),
        ),
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Volver al login
              Navigator.pushReplacementNamed(context, '/login');
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}