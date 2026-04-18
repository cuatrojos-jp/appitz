import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  Future<void> handleLogin(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError(context, 'Por favor ingresa email y contraseña');
      return;
    }

    try {
      await _authService.login(email, password);
      
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => 
                const DashboardScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;
              var tween = Tween(begin: begin, end: end)
                  .chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              return SlideTransition(position: offsetAnimation, child: child);
            },
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, e.toString());
      }
    }
  }

  void _navigateToRegister(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterScreen(
          onBack: () => Navigator.pop(context),
        )
      )
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
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

            // Email TextField
            CustomTextField(
              controller: emailController,
              label: "Correo electrónico",
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),

            // Password TextField
            CustomTextField(
              controller: passwordController,
              label: "Contraseña",
              isPassword: true,
            ),
            const SizedBox(height: 30),

            // Login Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.buttonColor,
                  foregroundColor: AppTheme.buttonTextColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () => handleLogin(context),
                child: const Text("Iniciar sesión"),
              ),
            ),

            const SizedBox(height: 15),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "¿No tienes una cuenta? ",
                  style: TextStyle(color: AppTheme.minorTextColor),
                ),
                GestureDetector(
                  onTap: () => _navigateToRegister(context),
                  child: const Text(
                    "Regístrate",
                    style: TextStyle(
                      color: AppTheme.titleTextColor,
                      fontWeight: FontWeight.bold,
                    )
                  )
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}