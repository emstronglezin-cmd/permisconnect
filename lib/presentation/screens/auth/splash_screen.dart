import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _navigateAfterDelay();
  }

  void _initAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _logoController,
          curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    _textSlide =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _logoController.forward().then((_) {
      _textController.forward();
    });
  }

  void _navigateAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/login');
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1450A0),
              Color(0xFF1E65C5),
              Color(0xFF3D7DD4),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo animé
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: _buildLogo(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Texte animé
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _textFade,
                      child: SlideTransition(
                        position: _textSlide,
                        child: _buildText(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 60),

                // Indicateur de chargement
                FadeTransition(
                  opacity: _textFade,
                  child: _buildLoadingIndicator(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône voiture avec route
            Stack(
              alignment: Alignment.center,
              children: [
                // Route en forme de C
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                  ),
                ),
                // Coupure du cercle pour faire un C
                Positioned(
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 40,
                    color: const Color(0xFF1E65C5),
                  ),
                ),
                // Voiture orange
                const Icon(
                  Icons.directions_car_rounded,
                  color: Color(0xFFFF7F27),
                  size: 36,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildText() {
    return Column(
      children: [
        const Text(
          'PermisConnect',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Votre Auto-École Digitale',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.85),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 40,
      height: 40,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(
          Colors.white.withValues(alpha: 0.8),
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.2),
      ),
    );
  }
}
