import 'package:appitz/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import '../widgets/glow_blob.dart';
import 'register_screen.dart';
import '../widgets/register_logo.dart';
import '../widgets/login_form.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToDashboard(BuildContext context, String rolId) {  // ← Agregar parámetro rolId
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DashboardScreen(rolId: rolId),
      ),
    );
  }

  void _navigateToRegister(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RegisterScreen(onBack: () => Navigator.pop(context)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColorAlt,
      body: Stack(
        children: [
          // ── Glow de fondo ──────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).size.height * 0.15,
            left: MediaQuery.of(context).size.width * 0.05,
            child: GlowBlob(),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.1,
            right: MediaQuery.of(context).size.width * 0.05,
            child: GlowBlob(),
          ),

          // ── Contenido ──────────────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 40,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const RegisterLogo(),
                          const SizedBox(height: 32),
                          LoginForm(
                            onSuccess: (rolId) => _navigateToDashboard(context, rolId),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: const [
                              Expanded(
                                child: Divider(color: AppTheme.borderColor),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'o',
                                  style: TextStyle(
                                    color: AppTheme.mutedForegroundColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(color: AppTheme.borderColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          GestureDetector(
                            onTap: () => _navigateToRegister(context),
                            child: Center(
                              child: RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    color: AppTheme.mutedForegroundColor,
                                    fontSize: 14,
                                  ),
                                  children: [
                                    TextSpan(text: '¿No tienes cuenta? '),
                                    TextSpan(
                                      text: 'Regístrate',
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          _buildFooter(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: const Text(
        'Al iniciar sesión, aceptas nuestros términos y condiciones',
        style: TextStyle(color: AppTheme.mutedForegroundColor, fontSize: 11),
        textAlign: TextAlign.center,
      ),
    );
  }
}
