// lib/presentation/features/onboarding/presentation_likelemba.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likelemba/core/app_colors.dart';
import 'package:likelemba/presentation/features/auth/screens/login_screen.dart';
import '../../../core/theme/liquid_glass_theme.dart';
import '../../shared/animations/fade_slide_transition.dart';
import '../../shared/widgets/liquid_glass_card.dart';
import '../../shared/widgets/glass_button.dart';


/// 🌊 Page de présentation "World Class" du Likelemba Sécurisé.
///
/// Met en scène une chorégraphie d'animations en plusieurs phases pour immerger
/// l'utilisateur dans l'univers de confiance et de transparence financière.
class PresentationLikelemba extends ConsumerStatefulWidget {
  const PresentationLikelemba({super.key});

  @override
  ConsumerState<PresentationLikelemba> createState() =>
      _PresentationLikelembaState();
}

class _PresentationLikelembaState extends ConsumerState<PresentationLikelemba>
    with SingleTickerProviderStateMixin {
  late AnimationController _masterController;
  late Animation<double> _backgroundBlur;
  late Animation<double> _glassOpacity;

  // Contrôleurs pour les phases
  bool _phase1Complete = false;
  bool _phase2Complete = false;
  bool _phase3Complete = false;

  @override
  void initState() {
    super.initState();
    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Phase 1 : Fond et logo (0.0 -> 0.35)
    _backgroundBlur = Tween<double>(begin: 0.0, end: 20.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    _glassOpacity = Tween<double>(begin: 0.0, end: 0.12).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    // Déclenchement des phases via listener
    _masterController.addListener(() {
      final value = _masterController.value;
      if (value >= 0.35 && !_phase1Complete) {
        setState(() => _phase1Complete = true);
      }
      if (value >= 0.65 && !_phase2Complete) {
        setState(() => _phase2Complete = true);
      }
      if (value >= 0.85 && !_phase3Complete) {
        setState(() => _phase3Complete = true);
      }
    });

    // Démarrer l'animation après le premier frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _masterController.forward();
    });
  }

  @override
  void dispose() {
    _masterController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Effet d'étirement du verre
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _masterController,
      builder: (context, child) {
        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              // 🌌 Fond animé avec effet de liquide
              _buildLiquidBackground(),
              // 🧊 Contenu principal
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),
                      // Phase 1 : Logo et nom
                      _buildPhase1Content(),
                      const Spacer(),
                      // Phase 2 : Slogan
                      _buildPhase2Content(),
                      const SizedBox(height: 48),
                      // Phase 3 : Bouton d'action
                      _buildPhase3Content(),
                      const Spacer(flex: 2),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiquidBackground() {
    return AnimatedBuilder(
      animation: _masterController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 1.5,
              colors: [
                AppColors.accentTeal.withOpacity(0.3 * _masterController.value),
                AppColors.primaryDeepBlue.withOpacity(0.8),
                Colors.black,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Bulles organiques animées
              Positioned(
                top: -100,
                right: -50,
                child: _AnimatedBlurBubble(
                  size: 300,
                  color: AppColors.accentTeal,
                  delay: 0.0,
                ),
              ),
              Positioned(
                bottom: -150,
                left: -80,
                child: _AnimatedBlurBubble(
                  size: 400,
                  color: AppColors.solidarityGold,
                  delay: 0.2,
                ),
              ),
              Positioned(
                top: 200,
                left: -100,
                child: _AnimatedBlurBubble(
                  size: 250,
                  color: AppColors.reserveFundCyan,
                  delay: 0.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhase1Content() {
    return Column(
      children: [
        // Logo avec animation de zoom arrière
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.5, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: child,
            );
          },
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryButtonGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentTeal.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.water_drop,
              size: 60,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Titre avec effet de remplissage (simulé via opacité progressive)
        FadeSlideTransition(
          delayMs: 400,
          direction: SlideDirection.up,
          child: const Text(
            'Likelemba',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 2,
              shadows: [
                Shadow(
                  offset: Offset(0, 4),
                  blurRadius: 20,
                  color: Color(0x40000000),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhase2Content() {
    if (!_phase2Complete) {
      return const SizedBox.shrink();
    }
    return StaggeredList(
      baseDelayMs: 0,
      delayIncrementMs: 100,
      direction: SlideDirection.up,
      children: [
        const Text(
          'La solidarité',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'renforcée par',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: AppColors.primaryButtonGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'la science',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhase3Content() {
    if (!_phase3Complete) {
      return const SizedBox.shrink();
    }
    return FadeSlideTransition(
      delayMs: 200,
      direction: SlideDirection.up,
      curve: Curves.easeInOutCubic,
      child: GlassButton(
        label: 'Commencer',
        icon: Icons.arrow_forward,
        impact: HapticImpact.heavy,
        onPressed: _navigateToLogin,
      ),
    );
  }
}

/// Bulle floue animée pour l'arrière-plan liquide.
class _AnimatedBlurBubble extends StatefulWidget {
  final double size;
  final Color color;
  final double delay;

  const _AnimatedBlurBubble({
    required this.size,
    required this.color,
    required this.delay,
  });

  @override
  State<_AnimatedBlurBubble> createState() => _AnimatedBlurBubbleState();
}

class _AnimatedBlurBubbleState extends State<_AnimatedBlurBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _position;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);

    _position = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.1, -0.05),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _position.value * widget.size,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withOpacity(0.15),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.3),
                  blurRadius: 80,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}