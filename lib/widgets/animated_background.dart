import 'dart:math' as math;

import 'package:flutter/material.dart';

/// AnimatedBackground with a lightweight moving glow layer.
class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final bool isOverlay;

  const AnimatedBackground({
    super.key,
    required this.child,
    this.isOverlay = true,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 18),
      vsync: this,
    )..repeat(reverse: true);
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
        final t = Curves.easeInOut.transform(_controller.value);

        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF050B16),
                Color(0xFF0D1B2A),
                Color(0xFF111C33),
                Color(0xFF070D1A),
              ],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildOrb(
                alignment: Alignment(-0.95 + t * 0.08, -0.82),
                size: 240,
                colors: const [Color(0xFF6C63FF), Color(0xFF00D4FF)],
                phase: 0.0,
              ),
              _buildOrb(
                alignment: Alignment(0.98 - t * 0.10, -0.68 + t * 0.04),
                size: 180,
                colors: const [Color(0xFFFFB830), Color(0xFFFF6A88)],
                phase: math.pi / 2,
              ),
              _buildOrb(
                alignment: Alignment(-0.10 + t * 0.03, 0.98),
                size: 220,
                colors: const [Color(0xFF00D4FF), Color(0xFF00E096)],
                phase: math.pi,
              ),
              if (widget.isOverlay)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.0, -0.25),
                          radius: 1.15,
                          colors: [
                            Colors.white.withValues(alpha: 0.04),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned.fill(child: child ?? const SizedBox.shrink()),
            ],
          ),
        );
      },
      child: widget.child,
    );
  }

  Widget _buildOrb({
    required Alignment alignment,
    required double size,
    required List<Color> colors,
    required double phase,
  }) {
    final t = _controller.value;
    final floatX = (t * 2 - 1) * 8;
    final floatY = ((1 - t) * 2 - 1) * 10;

    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: Offset(floatX, floatY),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                colors.first.withValues(alpha: 0.18),
                colors.last.withValues(alpha: 0.06),
                Colors.transparent,
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: colors.first.withValues(alpha: 0.22),
                blurRadius: 58,
                spreadRadius: 6,
              ),
              BoxShadow(
                color: colors.last.withValues(alpha: 0.12),
                blurRadius: 72,
                spreadRadius: 8,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Frosted glass container widget for glassmorphism effect
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double opacity;
  final Color? borderColor;
  final Color? glowColor;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.margin,
    this.opacity = 0.08,
    this.borderColor,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: glowColor != null
            ? [
                BoxShadow(
                  color: glowColor!.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: -4,
                ),
              ]
            : [
                const BoxShadow(
                  color: Color(0x20000000),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
      ),
    );
  }
}
