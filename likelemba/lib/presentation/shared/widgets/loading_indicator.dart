// lib/presentation/shared/widgets/loading_indicator.dart

import 'dart:ui';
import 'package:flutter/material.dart';

/// 🌊 Indicateur de chargement "Liquid Glass" avec effet de respiration.
class GlassLoadingIndicator extends StatefulWidget {
  final double size;
  final String? message;

  const GlassLoadingIndicator({
    super.key,
    this.size = 60,
    this.message,
  });

  @override
  State<GlassLoadingIndicator> createState() => _GlassLoadingIndicatorState();
}

class _GlassLoadingIndicatorState extends State<GlassLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _blurAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _blurAnimation = Tween<double>(begin: 5, end: 20).animate(_controller);
    _opacityAnimation = Tween<double>(begin: 0.05, end: 0.2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(widget.size / 2),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: _blurAnimation.value,
                    sigmaY: _blurAnimation.value,
                  ),
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(_opacityAnimation.value),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.water_drop,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.message!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}