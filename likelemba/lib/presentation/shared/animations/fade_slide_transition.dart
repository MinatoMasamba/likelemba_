// lib/presentation/shared/animations/fade_slide_transition.dart

import 'package:flutter/material.dart';

/// 🎬 Moteur d'animation atomique pour l'effet de cascade (Staggered Animation).
///
/// Ce widget enveloppe n'importe quel enfant et lui applique une animation d'entrée
/// combinant fondu (opacité) et glissement (translation). Il est conçu pour être
/// utilisé en série avec des délais croissants afin de créer une chorégraphie fluide.
class FadeSlideTransition extends StatefulWidget {
  /// L'enfant à animer.
  final Widget child;

  /// Délai avant le début de l'animation (en millisecondes).
  final int delayMs;

  /// Direction du glissement.
  final SlideDirection direction;

  /// Durée de l'animation (en millisecondes).
  final int durationMs;

  /// Courbe d'animation (par défaut, la courbe de résilience "Liquid Glass").
  final Curve curve;

  /// Fraction de décalage initial (entre 0.0 et 1.0) représentant la distance
  /// parcourue depuis la direction d'origine.
  final double offsetFraction;

  const FadeSlideTransition({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.direction = SlideDirection.up,
    this.durationMs = 400,
    this.curve = Curves.easeOutCubic,
    this.offsetFraction = 0.15,
  });

  @override
  State<FadeSlideTransition> createState() => _FadeSlideTransitionState();
}

class _FadeSlideTransitionState extends State<FadeSlideTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    );

    // ✅ Correction : S'assurer que le ratio begin ne dépasse pas 1.0
    // Si delayMs >= durationMs, on utilise begin = 0.999 (presque la fin)
    // mais en pratique, on veut juste que l'animation démarre après le délai.
    final double beginRatio = (widget.delayMs / widget.durationMs).clamp(0.0, 0.999);
    
    final curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        beginRatio,
        1.0,
        curve: widget.curve,
      ),
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation);
    _offset = Tween<Offset>(
      begin: _getBeginOffset(),
      end: Offset.zero,
    ).animate(curvedAnimation);

    // Lancer l'animation après le build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  Offset _getBeginOffset() {
    final distance = widget.offsetFraction;
    switch (widget.direction) {
      case SlideDirection.up:
        return Offset(0, distance);
      case SlideDirection.down:
        return Offset(0, -distance);
      case SlideDirection.left:
        return Offset(distance, 0);
      case SlideDirection.right:
        return Offset(-distance, 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si le délai est supérieur à la durée, on retourne directement l'enfant
    // avec opacité 1.0 et offset zéro (pas d'animation visible)
    if (widget.delayMs >= widget.durationMs) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: _offset.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Direction du glissement pour l'animation d'entrée.
enum SlideDirection { up, down, left, right }

/// 🌊 Widget utilitaire pour créer automatiquement une cascade d'animations
/// sur une liste d'enfants. Chaque enfant reçoit un délai incrémentiel.
class StaggeredList extends StatelessWidget {
  final List<Widget> children;
  final int baseDelayMs;
  final int delayIncrementMs;
  final SlideDirection direction;
  final int durationMs;
  final Curve curve;
  final double offsetFraction;

  const StaggeredList({
    super.key,
    required this.children,
    this.baseDelayMs = 0,
    this.delayIncrementMs = 80,
    this.direction = SlideDirection.up,
    this.durationMs = 400,
    this.curve = Curves.easeOutCubic,
    this.offsetFraction = 0.15,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        return FadeSlideTransition(
          delayMs: baseDelayMs + (index * delayIncrementMs),
          direction: direction,
          durationMs: durationMs,
          curve: curve,
          offsetFraction: offsetFraction,
          child: child,
        );
      }).toList(),
    );
  }
}