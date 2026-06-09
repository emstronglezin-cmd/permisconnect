import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _passwordVisible = false;
  bool _isLoading = false;
  String? _selectedFormula;

  final List<Map<String, dynamic>> _formulas = [
    {'id': 'basic', 'name': 'Formule Basique', 'price': '85 000 F CFA', 'hours': '20h'},
    {'id': 'standard', 'name': 'Formule Standard', 'price': '120 000 F CFA', 'hours': '30h'},
    {'id': 'premium', 'name': 'Formule Premium', 'price': '180 000 F CFA', 'hours': '45h'},
  ];

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A2E)),
          onPressed: () => context.go('/login'),
        ),
        title: const Text(
          'Créer un compte',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicateur de progression
            Row(
              children: List.generate(3, (i) => Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: i == 0 ? const Color(0xFF1E65C5) : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              )),
            ),
            const SizedBox(height: 28),

            const Text(
              'Vos informations',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Renseignez vos coordonnées pour créer votre compte.',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
            const SizedBox(height: 28),

            Row(
              children: [
                Expanded(child: _buildInput(_firstNameCtrl, 'Prénom', Icons.person_outline)),
                const SizedBox(width: 12),
                Expanded(child: _buildInput(_lastNameCtrl, 'Nom', Icons.person_outline)),
              ],
            ),
            const SizedBox(height: 14),
            _buildInput(_emailCtrl, 'Email', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 14),
            _buildInput(_phoneCtrl, 'Téléphone', Icons.phone_outlined, keyboardType: TextInputType.phone),
            const SizedBox(height: 14),
            _buildInput(_passwordCtrl, 'Mot de passe', Icons.lock_outline,
              isPassword: true,
              isVisible: _passwordVisible,
              onToggle: () => setState(() => _passwordVisible = !_passwordVisible),
            ),
            const SizedBox(height: 28),

            const Text(
              'Choisissez votre formule',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 14),

            ...List.generate(_formulas.length, (i) {
              final formula = _formulas[i];
              final isSelected = _selectedFormula == formula['id'];
              return GestureDetector(
                onTap: () => setState(() => _selectedFormula = formula['id']),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF1E65C5).withValues(alpha: 0.06) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF1E65C5) : const Color(0xFFE5E7EB),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? const Color(0xFF1E65C5) : const Color(0xFFD1D5DB),
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Center(
                                child: Container(
                                  width: 10, height: 10,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF1E65C5),
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(formula['name']!,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? const Color(0xFF1E65C5) : const Color(0xFF1A1A2E),
                              ),
                            ),
                            Text('${formula['hours']} de conduite',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      ),
                      Text(formula['price']!,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF7F27),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7F27),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 3,
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Créer mon compte',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onToggle,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: isPassword && !isVisible,
        keyboardType: keyboardType,
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 18),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: const Color(0xFF6B7280), size: 18),
                  onPressed: onToggle,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  void _register() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isLoading = false);
      context.go('/student/home');
    }
  }
}
