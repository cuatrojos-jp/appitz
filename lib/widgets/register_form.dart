import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/usuario_service.dart';

/// Formulario completo de registro
class RegisterForm extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onBack;

  const RegisterForm({
    super.key,
    required this.onSuccess,
    required this.onBack,
  });

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final UsuarioService _usuarioService = UsuarioService();

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _usuarioService.registrar(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nombreController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro exitoso. Espera aprobación del coordinador.'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border.all(color: AppTheme.borderColor),
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
              style: TextStyle(
                color: AppTheme.mutedForegroundColor,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),

            // Nombre Completo
            _buildField(
              label: 'Nombre Completo',
              controller: _nombreController,
              hint: 'Juan Pérez',
              icon: Icons.person_outline_rounded,
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
              onToggle: () => setState(() => _showPassword = !_showPassword),
            ),
            const SizedBox(height: 16),

            // Confirmar Contraseña
            _buildPasswordField(
              label: 'Confirmar Contraseña',
              controller: _confirmPasswordController,
              show: _showConfirmPassword,
              onToggle: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
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
                Expanded(child: Divider(color: AppTheme.borderColor)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'o',
                    style: TextStyle(color: AppTheme.mutedForegroundColor, fontSize: 13),
                  ),
                ),
                Expanded(child: Divider(color: AppTheme.borderColor)),
              ],
            ),
            const SizedBox(height: 20),

            // Volver al login
            GestureDetector(
              onTap: widget.onBack,
              child: Center(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(color: AppTheme.mutedForegroundColor, fontSize: 14),
                    children: [
                      TextSpan(text: '¿Ya tienes cuenta? '),
                      TextSpan(
                        text: 'Inicia sesión',
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
          ],
        ),
      ),
    );
  }

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
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          validator: validator ?? (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.mutedForegroundColor),
            prefixIcon: Icon(icon, color: AppTheme.mutedForegroundColor, size: 20),
            filled: true,
            fillColor: AppTheme.secondaryColor,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

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
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !show,
          style: const TextStyle(color: Colors.white),
          validator: validator ?? (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: const TextStyle(color: AppTheme.mutedForegroundColor),
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.mutedForegroundColor, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppTheme.mutedForegroundColor,
                size: 20,
              ),
              onPressed: onToggle,
            ),
            filled: true,
            fillColor: AppTheme.secondaryColor,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppTheme.backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 8,
          shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
        ),
        child: const Text(
          'Crear Cuenta',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}