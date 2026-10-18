// The University of Texas at El Paso: Bryan Perez
// ATS Multi-Stage Section Scanning Animation Widget

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AtsSectionScanner extends StatefulWidget {
  final VoidCallback? onCancel;

  const AtsSectionScanner({
    super.key,
    this.onCancel,
  });

  @override
  State<AtsSectionScanner> createState() => _AtsSectionScannerState();
}

class _AtsSectionScannerState extends State<AtsSectionScanner>
    with TickerProviderStateMixin {
  late final AnimationController _radarController;
  late final AnimationController _pulseController;
  Timer? _stepTimer;

  int _currentStep = 0;
  double _progress = 0.08;

  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'Document & ATS Parser',
      'subtitle': 'Extracting layout, headers & text tokens',
      'icon': Icons.description_outlined,
    },
    {
      'title': 'Contact Info & Profiles',
      'subtitle': 'Checking email, phone, LinkedIn & GitHub ATS tags',
      'icon': Icons.badge_outlined,
    },
    {
      'title': 'Work Experience & Impact',
      'subtitle': 'Evaluating action verbs, quantifiable metrics (%, \$)',
      'icon': Icons.work_outline,
    },
    {
      'title': 'Skills & Job Match',
      'subtitle': 'Cross-referencing keywords with Target Job Description',
      'icon': Icons.psychology_outlined,
    },
    {
      'title': 'Education & Credentials',
      'subtitle': 'Validating degrees, institutions & certifications',
      'icon': Icons.school_outlined,
    },
    {
      'title': 'ATS Scorecard Synthesis',
      'subtitle': 'Scoring sections and generating recruiter suggestions',
      'icon': Icons.analytics_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Progress simulation through the sections while AI computes
    _stepTimer = Timer.periodic(const Duration(milliseconds: 1400), (timer) {
      if (!mounted) return;
      setState(() {
        if (_currentStep < _steps.length - 1) {
          _currentStep++;
          _progress = (_currentStep + 1) / _steps.length * 0.92;
        } else {
          // Cap at 95% until actual AI network call returns
          _progress = 0.95;
        }
      });
    });
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _radarController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeStep = _steps[_currentStep];

    return Container(
      color: Colors.black.withValues(alpha: 0.88),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Radar scanner visual
              SizedBox(
                height: 140,
                width: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer pulsating ring
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          height: 120 + (_pulseController.value * 18),
                          width: 120 + (_pulseController.value * 18),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFC084FC).withValues(
                                alpha: 0.35 - (_pulseController.value * 0.2),
                              ),
                              width: 2,
                            ),
                          ),
                        );
                      },
                    ),

                    // Rotating radar beam
                    RotationTransition(
                      turns: _radarController,
                      child: Container(
                        height: 110,
                        width: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            center: Alignment.center,
                            colors: [
                              Colors.transparent,
                              const Color(0xFF9333EA).withValues(alpha: 0.15),
                              const Color(0xFFC084FC).withValues(alpha: 0.75),
                            ],
                            stops: const [0.0, 0.75, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Central icon
                    Container(
                      height: 70,
                      width: 70,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF240838),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF9333EA),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        activeStep['icon'] as IconData,
                        color: const Color(0xFFF3E8FF),
                        size: 34,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Title & Percentage
              Text(
                'ATS SECTION SCANNER',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFFC084FC),
                  fontSize: 12,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                activeStep['title'] as String,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                activeStep['subtitle'] as String,
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFFE9D5FF),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: double.infinity,
                  height: 8,
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: const Color(0xFF3B104E),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFC084FC),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Section checklist
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E0A3C).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF4A154B)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  children: List.generate(_steps.length, (idx) {
                    final item = _steps[idx];
                    final isDone = idx < _currentStep;
                    final isCurrent = idx == _currentStep;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          if (isDone)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF4ADE80),
                              size: 18,
                            )
                          else if (isCurrent)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFC084FC),
                                ),
                              ),
                            )
                          else
                            const Icon(
                              Icons.radio_button_unchecked,
                              color: Color(0xFF6B4687),
                              size: 18,
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item['title'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isCurrent
                                    ? FontWeight.w700
                                    : (isDone ? FontWeight.w500 : FontWeight.w400),
                                color: isCurrent
                                    ? const Color(0xFFD8B4FE)
                                    : (isDone
                                        ? const Color(0xFFF3E8FF)
                                        : const Color(0xFF8B6B9E)),
                              ),
                            ),
                          ),
                          if (isDone)
                            const Text(
                              'VERIFIED',
                              style: TextStyle(
                                color: Color(0xFF4ADE80),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ),
              ),

              if (widget.onCancel != null) ...[
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.close, color: Colors.white60, size: 16),
                  label: const Text(
                    'Cancel Scan',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
