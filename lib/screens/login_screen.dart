import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void handleLogin(BuildContext context) {
    final email = emailController.text;
    final password = passwordController.text;

    print("email: $email");
    print("password: $password");

    // Navegar a la pantalla del dashboard con una transición de deslizamiento
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const DashboardScreen(),

        // Transición de deslizamiento desde la derecha
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0); // Desde derecha
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Login Title
            Text(
              "Bienvenido a Appitz",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.titleTextColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // Caja de texto del correo
            TextField(
              controller: emailController,
              cursorColor: AppTheme.cursorColor,
              style: TextStyle(
                color: AppTheme.minorTextColor,
              ), // Color de texto mientras se escribe

              decoration: InputDecoration(
                labelText: "Correo electrónico",
                labelStyle: TextStyle(
                  color: AppTheme.unfocusedLabelColor,
                ), // Color del label cuando no está enfocado

                floatingLabelStyle: TextStyle(
                  color: AppTheme.focusedLabelColor,
                ), // Color del label cuando está enfocado/hovering
                // Borde sin enfocar
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTheme.unfocusedBorderColor,
                    width: 1,
                  ),
                ),

                // Borde al enfocar
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTheme.focusedBorderColor,
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Caja de texto de la contraseña
            TextField(
              controller: passwordController,
              cursorColor: AppTheme.cursorColor,
              obscureText: true,

              style: TextStyle(
                color: AppTheme.minorTextColor,
              ), // Color de texto mientras se escribe

              decoration: InputDecoration(
                labelText: "Contraseña",
                labelStyle: TextStyle(
                  color: AppTheme.unfocusedLabelColor,
                ), // Color del label cuando no está enfocado

                floatingLabelStyle: TextStyle(
                  color: AppTheme.focusedLabelColor,
                ), // Color del label cuando está enfocado/hovering
                // Borde sin enfocar
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTheme.unfocusedBorderColor,
                    width: 1,
                  ),
                ),

                // Borde al enfocar
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTheme.focusedBorderColor,
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Botón de inicio de sesión
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.buttonColor,
                  foregroundColor: AppTheme.buttonTextColor,
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () => handleLogin(context),
                child: Text("Iniciar sesión"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
