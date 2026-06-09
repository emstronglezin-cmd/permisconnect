import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _cardSlide;
  late Animation<double> _cardFade;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _cardSlide =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _cardFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1450A0), Color(0xFF1E65C5), Color(0xFF3D7DD4)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header avec logo
              Expanded(
                flex: 2,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.directions_car_rounded,
                          color: Color(0xFFFF7F27),
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'PermisConnect',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Card de connexion
              Expanded(
                flex: 5,
                child: FadeTransition(
                  opacity: _cardFade,
                  child: SlideTransition(
                    position: _cardSlide,
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(36),
                          topRight: Radius.circular(36),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bienvenue!',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Connectez-vous pour continuer.',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Bouton Google
                            _buildSocialButton(
                              icon: Icons.g_mobiledata_rounded,
                              iconColor: const Color(0xFFEA4335),
                              label: 'Continuer avec Google',
                              backgroundColor: const Color(0xFFFFF3F3),
                              borderColor: const Color(0xFFFFCDD2),
                              onTap: () => _loginWithGoogle(),
                            ),
                            const SizedBox(height: 12),

                            // Bouton Téléphone
                            _buildSocialButton(
                              icon: Icons.phone_rounded,
                              iconColor: Colors.white,
                              label: 'Continuer avec Téléphone',
                              backgroundColor: const Color(0xFFFF7F27),
                              borderColor: const Color(0xFFFF7F27),
                              textColor: Colors.white,
                              onTap: () => _loginWithPhone(),
                            ),

                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                    child: Divider(color: Colors.grey[200])),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'ou',
                                    style: TextStyle(
                                      color: Color(0xFF9CA3AF),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Expanded(
                                    child: Divider(color: Colors.grey[200])),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Champ email
                            _buildTextField(
                              controller: _emailController,
                              hint: 'Adresse email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 14),

                            // Champ mot de passe
                            _buildTextField(
                              controller: _passwordController,
                              hint: 'Mot de passe',
                              icon: Icons.lock_outline_rounded,
                              isPassword: true,
                              isPasswordVisible: _isPasswordVisible,
                              onTogglePassword: () => setState(
                                  () => _isPasswordVisible =
                                      !_isPasswordVisible),
                            ),
                            const SizedBox(height: 10),

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                child: const Text(
                                  'Mot de passe oublié ?',
                                  style: TextStyle(
                                    color: Color(0xFF1E65C5),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Bouton connexion
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _loginWithEmail,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E65C5),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 4,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Se connecter',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Lien inscription
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Pas encore de compte? ",
                                  style: TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 14,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => context.go('/register'),
                                  child: const Text(
                                    "S'inscrire",
                                    style: TextStyle(
                                      color: Color(0xFF1E65C5),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Accès démo admin
                            Center(
                              child: TextButton(
                                onPressed: () => context.go('/admin/home'),
                                child: const Text(
                                  'Accès Administration →',
                                  style: TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color backgroundColor,
    required Color borderColor,
    Color textColor = const Color(0xFF1A1A2E),
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onTogglePassword,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !isPasswordVisible,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: Color(0xFF1A1A2E),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFF9CA3AF),
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF6B7280),
                    size: 20,
                  ),
                  onPressed: onTogglePassword,
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  void _loginWithEmail() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isLoading = false);
      context.go('/student/home');
    }
  }

  void _loginWithGoogle() {
    context.go('/student/home');
  }

  void _loginWithPhone() {
    context.go('/student/home');
  }
}
