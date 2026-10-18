// The University of Texas at El Paso: Bryan Perez

import 'package:flutter/material.dart';

/// A full-screen, looping animated gradient background.
///
/// This widget animates a [LinearGradient] between two alignments
/// to create a subtle, flowing background effect.
///
/// The following parameters can be customized:
/// - [colors]: list of gradient colors (must contain at least two).
/// - [stops]: optional list of stops for the gradient colors.
/// - [beginAlignment]: where the gradient begins.
/// - [endAlignment]: where the gradient ends.
/// - [duration]: how long one back‑and‑forth cycle takes.
/// - [curve]: animation curve for the transition.
class AnimatedGradientBackground extends StatefulWidget {
  /// The colors to use in the gradient. Must have >= 2 entries.
  final List<Color> colors;

  /// Optional stops for each color in [colors].
  final List<double>? stops;

  /// Alignment at which the gradient begins.
  final Alignment beginAlignment;

  /// Alignment at which the gradient ends.
  final Alignment endAlignment;

  /// Duration for one forward (then reverse) cycle.
  final Duration duration;

  /// Curve applied to the alignment transition.
  final Curve curve;

  /// Creates an animated gradient background.
  ///
  /// By default, it animates between top-left and bottom-right
  /// over 6 seconds using a light-blue palette.
  const AnimatedGradientBackground({
    super.key,
    this.colors = const [
      Color(0xFFFAF5FF), // Soft Lilac Snow
      Color(0xFFF3E8FF), // Pastel Lavender
      Color(0xFFEDE9FE), // Soft Amethyst Mist
      Color(0xFFE9D5FF), // Dreamy Violet Glow
      Color(0xFFDDD6FE), // Silk Orchid
    ],
    this.stops,
    this.beginAlignment = Alignment.topLeft,
    this.endAlignment = Alignment.bottomRight,
    this.duration = const Duration(seconds: 9),
    this.curve = Curves.easeInOut,
  });

  @override
  AnimatedGradientBackgroundState createState() =>
      AnimatedGradientBackgroundState();
}

/// State for [AnimatedGradientBackground].
///
/// Manages an [AnimationController] and an [AlignmentTween]
/// to drive the gradient’s [begin] and [end] points.
class AnimatedGradientBackgroundState
    extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Alignment> _alignmentAnimation;

  @override
  void initState() {
    super.initState();

    // Validate that at least two colors are provided for the gradient.
    assert(widget.colors.length >= 2, 'Provide at least two colors for the gradient');

    // 1) Initialize the controller for a repeating forward/reverse cycle.
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    // 2) Tween from beginAlignment to endAlignment, applying the curve.
    _alignmentAnimation = AlignmentTween(
      begin: widget.beginAlignment,
      end: widget.endAlignment,
    ).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
  }

  @override
  void dispose() {
    // Dispose of the controller to free system resources.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild the Container whenever the alignment changes.
    return AnimatedBuilder(
      animation: _alignmentAnimation,
      builder: (context, child) {
        return Container(
          // Gradient that flows back and forth.
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: _alignmentAnimation.value,
              end: Alignment(
                -_alignmentAnimation.value.x,
                -_alignmentAnimation.value.y,
              ),
              colors: widget.colors,
              stops: widget.stops,
            ),
          ),
        );
      },
    );
  }
}