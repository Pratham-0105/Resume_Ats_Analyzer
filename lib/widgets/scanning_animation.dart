// The University of Texas at El Paso: Bryan Perez

import 'dart:ui';
import 'package:flutter/material.dart';

/// A full‐screen overlay widget that simulates the “light bar” effect
/// of a photocopier or scanner, sweeping a bright beam down the page.
///
/// Features:
/// 1. Honors the platform’s “reduce motion” setting.
/// 2. Sweeps a gradient “beam” from top to bottom repeatedly.
/// 3. Adds a soft Gaussian blur behind the beam for realism.
/// 4. Optional horizontal shimmer and background dimming.
/// 5. Customizable duration, thickness, and color.
class ScanningAnimation extends StatefulWidget {
  /// Duration for one sweep from top to bottom.
  final Duration duration;

  /// Height of the light beam in logical pixels.
  final double beamHeight;

  /// Color of the central beam.
  final Color beamColor;

  /// Whether to apply a horizontal shimmer (flicker) to the beam.
  final bool enableShimmer;

  /// If true, dims the rest of the screen behind the beam.
  final bool dimBackground;

  const ScanningAnimation({
    super.key,
    this.duration = const Duration(seconds: 3),
    this.beamHeight = 30.0,
    this.beamColor = Colors.white,
    this.enableShimmer = true,
    this.dimBackground = true,
  });

  @override
  State<ScanningAnimation> createState() => _ScanningAnimationState();
}

class _ScanningAnimationState extends State<ScanningAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _position;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();

    _position = CurvedAnimation(parent: _controller, curve: Curves.linear);

    _shimmer = widget.enableShimmer
        ? Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    )
        : AlwaysStoppedAnimation<double>(1.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Respect reduce-motion settings
    if (MediaQuery.of(context).disableAnimations) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final maxHeight = constraints.maxHeight;
        final beamH = widget.beamHeight;
        final centerColor = widget.beamColor;
        final edgeColor = centerColor.withAlpha(150);

        return AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            final dy = _position.value * (maxHeight - beamH);
            final shimmer = _shimmer.value;

            return Stack(
              children: [
                // Optional dimming of background
                if (widget.dimBackground)
                  Positioned.fill(
                    child: Container(color: Colors.black.withValues(alpha: 0.2)),
                  ),

                // Soft blur behind the beam
                Positioned(
                  top: dy - beamH,
                  left: 0,
                  right: 0,
                  height: beamH * 3,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(color: Colors.transparent),
                  ),
                ),

                // The moving beam
                Positioned(
                  top: dy,
                  left: 0,
                  right: 0,
                  height: beamH,
                  child: Opacity(
                    opacity: shimmer,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            centerColor.withValues(alpha: 0.0),
                            edgeColor.withValues(alpha: 0.5),
                            centerColor.withValues(alpha: 0.9),
                            edgeColor.withValues(alpha: 0.5),
                            centerColor.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: centerColor.withValues(alpha: 0.6 * shimmer),
                            blurRadius: 24,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
