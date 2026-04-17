import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onBack;
 
  const RegisterScreen({super.key, required this.onBack});
 
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}
 
class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  bool _showPassword = false;
  bool _showConfirmPassword = false;
 
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _teamNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
 
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
 
  // ── Colores del tema (equivalente a las CSS vars del original) ──
  static const Color _background = Color(0xFF0F0F11);
  static const Color _card = Color(0xFF1A1A1E);
  static const Color _primary = Color(0xFF6EE7B7); // verde-menta
  static const Color _border = Color(0xFF2A2A30);
  static const Color _secondary = Color(0xFF222228);
  static const Color _mutedFg = Color(0xFF6B7280);
 
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
    _fullNameController.dispose();
    _teamNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
 
  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      debugPrint('Registro: ${_fullNameController.text}');
      // Aquí iría la lógica de registro
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Stack(
        children: [
          // ── Glow de fondo ──────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).size.height * 0.15,
            left: MediaQuery.of(context).size.width * 0.05,
            child: _glowBlob(),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.1,
            right: MediaQuery.of(context).size.width * 0.05,
            child: _glowBlob(),
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
                        horizontal: 24, vertical: 40),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildLogo(),
                          const SizedBox(height: 32),
                          _buildCard(),
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
 
  // ── Logo ──────────────────────────────────────────────────────────────
  Widget _buildLogo() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_primary, Color(0xFF34D399)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.shield_rounded,
                  color: _background, size: 28),
            ),
            const SizedBox(width: 12),
            const Text(
              'APPITZ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Gestiona tu equipo como un profesional',
          style: TextStyle(color: _mutedFg, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
 
  // ── Card con el formulario ────────────────────────────────────────────
  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Crear Cuenta',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Completa tus datos para comenzar',
              style: TextStyle(color: _mutedFg, fontSize: 13),
            ),
            const SizedBox(height: 24),
 
            // Nombre Completo
            _buildField(
              label: 'Nombre Completo',
              controller: _fullNameController,
              hint: 'Juan Pérez',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 16),
 
            // Nombre del Equipo
            _buildField(
              label: 'Nombre del Equipo',
              controller: _teamNameController,
              hint: 'FC Thunder',
              icon: Icons.shield_outlined,
            ),
            const SizedBox(height: 16),
 
            // Email
            _buildField(
              label: 'Email',
              controller: _emailController,
              hint: 'tu@email.com',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
 
            // Contraseña
            _buildPasswordField(
              label: 'Contraseña',
              controller: _passwordController,
              show: _showPassword,
              onToggle: () =>
                  setState(() => _showPassword = !_showPassword),
            ),
            const SizedBox(height: 16),
 
            // Confirmar Contraseña
            _buildPasswordField(
              label: 'Confirmar Contraseña',
              controller: _confirmPasswordController,
              show: _showConfirmPassword,
              onToggle: () => setState(
                  () => _showConfirmPassword = !_showConfirmPassword),
              validator: (v) {
                if (v != _passwordController.text) {
                  return 'Las contraseñas no coinciden';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
 
            // Botón de envío
            _buildSubmitButton(),
            const SizedBox(height: 24),
 
            // Divider
            Row(
              children: const [
                Expanded(child: Divider(color: _border)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child:
                      Text('o', style: TextStyle(color: _mutedFg, fontSize: 13)),
                ),
                Expanded(child: Divider(color: _border)),
              ],
            ),
            const SizedBox(height: 20),
 
            // Volver al login
            GestureDetector(
              onTap: widget.onBack,
              child: Center(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(color: _mutedFg, fontSize: 14),
                    children: [
                      TextSpan(text: '¿Ya tienes cuenta? '),
                      TextSpan(
                        text: 'Inicia sesión',
                        style: TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
 
  // ── Campo de texto genérico ───────────────────────────────────────────
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          validator: validator ??
              (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _mutedFg),
            prefixIcon: Icon(icon, color: _mutedFg, size: 20),
            filled: true,
            fillColor: _secondary,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
 
  // ── Campo de contraseña ───────────────────────────────────────────────
  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool show,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !show,
          style: const TextStyle(color: Colors.white),
          validator: validator ??
              (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: const TextStyle(color: _mutedFg),
            prefixIcon:
                const Icon(Icons.lock_outline_rounded, color: _mutedFg, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                show
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: _mutedFg,
                size: 20,
              ),
              onPressed: onToggle,
            ),
            filled: true,
            fillColor: _secondary,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
 
  // ── Botón principal ───────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: _background,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 8,
          shadowColor: _primary.withOpacity(0.4),
        ),
        child: const Text(
          'Crear Cuenta',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
 
  // ── Footer ────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: const Text(
        'Al crear una cuenta, aceptas nuestros términos y condiciones',
        style: TextStyle(color: _mutedFg, fontSize: 11),
        textAlign: TextAlign.center,
      ),
    );
  }
 
  // ── fondo ─────────────────────────────────────────────────────
  Widget _glowBlob() {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _primary.withOpacity(0.05),
      ),
      child: BackdropFilter(
        filter: ColorFilter.mode(
          _primary.withOpacity(0.03),
          BlendMode.screen,
        ),
        child: const SizedBox.shrink(),
      ),
    );
  }
}