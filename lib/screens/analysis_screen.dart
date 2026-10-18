// The University of Texas at El Paso: Bryan Perez
// Ultra-Modern ATS Analysis Report Dashboard with Interactive Scorecards & Keyword Cloud

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/resume_provider.dart';
import '../widgets/section_feedback_card.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with TickerProviderStateMixin {
  late final AnimationController _revealController;
  String _sectionFilter = 'All'; // 'All', 'Action Required', 'Strong'

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..forward();
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF10B981); // Emerald
    if (score >= 60) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFFEF4444); // Red
  }

  String _getAtsStatus(int score) {
    if (score >= 80) return 'HIGH ATS PASS RATE';
    if (score >= 60) return 'MODERATE ATS MATCH';
    return 'HIGH RISK OF ATS FILTER';
  }

    void _copyActionPlan(List<String> tips) {
    HapticFeedback.lightImpact();
    final text = tips.map((t) => '• $t').join('\n');
    Clipboard.setData(ClipboardData(text: 'ATS Recommendations:\n$text'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Action plan copied to clipboard!'),
        backgroundColor: Color(0xFF2E1065),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ResumeViewModel>();
    final resume = viewModel.resume;

    if (resume.fullText.trim().isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAF5FF),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
        ),
      );
    }

    final sections = resume.sectionBreakdown;
    final atsColor = _getScoreColor(resume.atsScore);

    // Filtered sections
    final filteredSections = sections.where((s) {
      if (_sectionFilter == 'Action Required') {
        final ratio = s.maxScore > 0 ? s.achievedScore / s.maxScore : 0.0;
        return ratio < 0.8;
      }
      if (_sectionFilter == 'Strong') {
        final ratio = s.maxScore > 0 ? s.achievedScore / s.maxScore : 0.0;
        return ratio >= 0.8;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF5FF),
      appBar: AppBar(
        title: Text(
          'ATS Scorecard',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: const Color(0xFF2E1065),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2E1065),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF7C3AED)),
            tooltip: 'Copy Action Plan',
            onPressed: () => _copyActionPlan(resume.feedback),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _revealController,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Aesthetic Hero Scorecard
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E0B36), Color(0xFF38104D), Color(0xFF250B3E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF38104D).withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFFC084FC).withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: atsColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: atsColor.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield_outlined, color: atsColor, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                _getAtsStatus(resume.atsScore),
                                style: TextStyle(
                                  color: atsColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (resume.major != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC084FC).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFC084FC).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              resume.major!.name.toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFFF3E8FF),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Big Circular Dial & Dual Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Radial Score Circle
                        SizedBox(
                          width: 110,
                          height: 110,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: (resume.atsScore / 100).clamp(0.0, 1.0),
                                strokeWidth: 10,
                                strokeCap: StrokeCap.round,
                                backgroundColor: Colors.white12,
                                valueColor: AlwaysStoppedAnimation<Color>(atsColor),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${resume.atsScore}',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                      height: 1.0,
                                    ),
                                  ),
                                  const Text(
                                    '/ 100',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 24),

                        // Secondary Stats Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _statTile(
                                label: 'ATS Compatibility',
                                value: '${resume.atsScore}%',
                                color: atsColor,
                              ),
                              const SizedBox(height: 10),
                              _statTile(
                                label: 'Resume Quality',
                                value: '${resume.score}%',
                                color: _getScoreColor(resume.score),
                              ),
                              const SizedBox(height: 10),
                              _statTile(
                                label: 'Sections Analyzed',
                                value: '${sections.length} Passed',
                                color: const Color(0xFFC084FC),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (resume.roleFitSummary != null &&
                        resume.roleFitSummary!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC084FC).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFC084FC).withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.psychology_outlined,
                              color: Color(0xFFC084FC),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                resume.roleFitSummary!,
                                style: const TextStyle(
                                  color: Color(0xFFF3E8FF),
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. ATS Keyword Match Audit
              if (resume.matchedKeywords.isNotEmpty ||
                  resume.missingKeywords.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFEDE9FE)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.tune_rounded, color: Color(0xFF9333EA), size: 18),
                              SizedBox(width: 8),
                              Text(
                                'ATS Keyword Audit',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E1065),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF5FF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE9D5FF)),
                            ),
                            child: Text(
                              '${resume.matchedKeywords.length} Found • ${resume.missingKeywords.length} Missing',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (resume.matchedKeywords.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: const [
                            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 15),
                            SizedBox(width: 6),
                            Text(
                              'Detected In Resume',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: resume.matchedKeywords.map((k) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1FAE5),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFA7F3D0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check, size: 12, color: Color(0xFF065F46)),
                                  const SizedBox(width: 4),
                                  Text(
                                    k,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF065F46),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      if (resume.missingKeywords.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: const [
                            Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 15),
                            SizedBox(width: 6),
                            Text(
                              'Missing Important Keywords (Add These!)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: resume.missingKeywords.map((k) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add, size: 12, color: Color(0xFF92400E)),
                                  const SizedBox(width: 4),
                                  Text(
                                    k,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // 3. Section Breakdown Header with Filter Tabs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Section Breakdown',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2E1065),
                    ),
                  ),
                  Row(
                    children: ['All', 'Action Required', 'Strong'].map((filter) {
                      final selected = _sectionFilter == filter;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _sectionFilter = filter);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFF7C3AED) : const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected ? const Color(0xFF6D28D9) : const Color(0xFFE9D5FF),
                            ),
                          ),
                          child: Text(
                            filter,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : const Color(0xFF6B21A8),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Section Cards
              if (filteredSections.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEDE9FE)),
                  ),
                  child: const Center(
                    child: Text(
                      'No sections in this filter category.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                )
              else ...[
                for (var s in filteredSections)
                  SectionFeedbackCard(
                    title: s.sectionName,
                    score: s.achievedScore,
                    maxScore: s.maxScore,
                    suggestions: s.feedback,
                    skills: s.matchedContent,
                  ),
              ],

              const SizedBox(height: 20),

              // 4. Executive Recruiter Action Plan
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEDE9FE)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.tips_and_updates_outlined,
                                color: Color(0xFF9333EA), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Priority Action Plan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E1065),
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () => _copyActionPlan(resume.feedback),
                          icon: const Icon(Icons.copy, size: 14, color: Color(0xFF7C3AED)),
                          label: const Text('Copy', style: TextStyle(fontSize: 12, color: Color(0xFF7C3AED))),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (resume.feedback.isEmpty)
                      const Text(
                        'No specific suggestions generated.',
                        style: TextStyle(color: Colors.grey),
                      )
                    else ...[
                      for (int i = 0; i < resume.feedback.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 2, right: 10),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF7C3AED),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  resume.feedback[i],
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.45,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statTile({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
