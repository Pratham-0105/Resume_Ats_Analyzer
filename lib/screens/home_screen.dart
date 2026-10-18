// The University of Texas at El Paso: Bryan Perez
// Modern Executive Home Screen with Glassmorphism & Micro-Interactions

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'upload_screen.dart';
import '../widgets/animated_gradient_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  double _buttonScale = 1.0;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => setState(() => _buttonScale = 0.96);
  void _onTapUp(TapUpDetails _) {
    setState(() => _buttonScale = 1.0);
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UploadScreen()),
    );
  }

  void _onTapCancel() => setState(() => _buttonScale = 1.0);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Stack(
        children: [
          const AnimatedGradientBackground(),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: w * 0.05,
                            vertical: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Bar
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF7C3AED),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.auto_awesome,
                                          color: Color(0xFFF3E8FF),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Smart Resume AI',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: const Color(0xFF2E1065),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(
                                          Icons.circle,
                                          color: Color(0xFF9333EA),
                                          size: 8,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'CLOUD AI READY',
                                          style: TextStyle(
                                            color: Color(0xFF6B21A8),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 28),

                              // Hero Title Card
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF240838), Color(0xFF3B104E), Color(0xFF2A0845)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF3B104E).withValues(alpha: 0.35),
                                      blurRadius: 22,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFC084FC).withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(0xFFC084FC).withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: const Text(
                                        'ATS 2.0 PROTOCOL',
                                        style: TextStyle(
                                          color: Color(0xFFF3E8FF),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      'Beat the ATS.\nLand Your Dream Role.',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        height: 1.2,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Evaluate your resume against real job descriptions. Get instant keyword matching, section points, and recruiter-approved improvements.',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.78),
                                        fontSize: 14,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Quick tags
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _heroFeaturePill(Icons.cloud_done_outlined, 'Render Cloud AI'),
                                        _heroFeaturePill(Icons.speed_rounded, 'Llama 3.2 AI'),
                                        _heroFeaturePill(Icons.grading_rounded, 'ATS Out of 100'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Feature Highlights
                              Text(
                                'Core Features',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF2E1065),
                                ),
                              ),
                              const SizedBox(height: 12),

                              _featureCard(
                                icon: Icons.document_scanner_outlined,
                                iconColor: const Color(0xFF7C3AED),
                                title: 'Multi-Stage Section Radar',
                                desc: 'Scans Contact, Experience, Skills & Education with live visual feedback.',
                              ),
                              const SizedBox(height: 10),
                              _featureCard(
                                icon: Icons.work_history_outlined,
                                iconColor: const Color(0xFF9333EA),
                                title: 'Job Description Matching',
                                desc: 'Find matched vs. missing keywords tailored to your specific target job.',
                              ),
                              const SizedBox(height: 10),
                              _featureCard(
                                icon: Icons.insights_rounded,
                                iconColor: const Color(0xFFC026D3),
                                title: 'Quantifiable Metric Audit',
                                desc: 'Grades action verbs, measurable impact (%, \$), and structural hierarchy.',
                              ),

                              const SizedBox(height: 20),

                              // Methodology Accordion
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.75),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.8),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF7C3AED).withValues(alpha: 0.05),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Theme(
                                      data: Theme.of(context).copyWith(
                                        dividerColor: Colors.transparent,
                                      ),
                                      child: ExpansionTile(
                                        tilePadding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 4,
                                        ),
                                        title: Text(
                                          'How Scoring Works',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: const Color(0xFF2E1065),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                                        children: [
                                          _methodologyRow('Work Experience', '30 pts', 'Action verbs & measurable outcomes'),
                                          _methodologyRow('Skills & Tech', '20 pts', 'JD keyword density & grouped skills'),
                                          _methodologyRow('Professional Summary', '15 pts', 'Target role title & value pitch'),
                                          _methodologyRow('Contact & Links', '10 pts', 'LinkedIn, GitHub, ATS contact format'),
                                          _methodologyRow('Education & Major', '10 pts', 'Degree relevance & institutional standing'),
                                          _methodologyRow('Projects & Portfolios', '10 pts', 'Real-world tech stacks & links'),
                                          _methodologyRow('Certifications', '5 pts', 'Industry validated credentials'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 90), // Space for floating button
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Floating Bottom CTA Button
                  Positioned(
                    bottom: 20,
                    left: w * 0.05,
                    right: w * 0.05,
                    child: Transform.scale(
                      scale: _buttonScale,
                      child: GestureDetector(
                        onTapDown: _onTapDown,
                        onTapUp: _onTapUp,
                        onTapCancel: _onTapCancel,
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF9333EA), Color(0xFF7C3AED), Color(0xFF6D28D9)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7C3AED).withValues(alpha: 0.45),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.upload_file_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Upload & Analyze Resume',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroFeaturePill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFC084FC).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFC084FC), size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE9FE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: const Color(0xFF2E1065),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodologyRow(String label, String points, String detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF9333EA).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              points,
              style: const TextStyle(
                color: Color(0xFF7C3AED),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF2E1065),
                  ),
                ),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}