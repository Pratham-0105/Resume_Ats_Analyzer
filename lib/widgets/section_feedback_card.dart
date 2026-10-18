// The University of Texas at El Paso: Bryan Perez
// Modern Section Feedback Card with Dynamic Category Icons & Scoring Pills

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SectionFeedbackCard extends StatelessWidget {
  final String title;
  final int score;
  final int maxScore;
  final List<String> suggestions;
  final List<String>? skills;

  const SectionFeedbackCard({
    super.key,
    required this.title,
    required this.score,
    required this.maxScore,
    required this.suggestions,
    this.skills,
  });

  IconData _getSectionIcon(String sectionTitle) {
    final lower = sectionTitle.toLowerCase();
    if (lower.contains('contact')) return Icons.badge_outlined;
    if (lower.contains('summary')) return Icons.person_outline_rounded;
    if (lower.contains('experience') || lower.contains('work')) {
      return Icons.work_outline_rounded;
    }
    if (lower.contains('skill')) return Icons.psychology_outlined;
    if (lower.contains('education')) return Icons.school_outlined;
    if (lower.contains('project')) return Icons.code_rounded;
    if (lower.contains('cert')) return Icons.verified_outlined;
    return Icons.folder_open_rounded;
  }

  Color _getScoreColor(double ratio) {
    if (ratio >= 0.8) return const Color(0xFF16A34A);
    if (ratio >= 0.6) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  String _getScoreLabel(double ratio) {
    if (ratio >= 0.8) return 'Strong';
    if (ratio >= 0.6) return 'Needs Work';
    return 'Critical Fix';
  }

  @override
  Widget build(BuildContext context) {
    final ratio = maxScore > 0 ? (score / maxScore).clamp(0.0, 1.0) : 0.0;
    final scoreColor = _getScoreColor(ratio);
    final percent = (ratio * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE9FE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getSectionIcon(title),
                    color: scoreColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: const Color(0xFF2E1065),
                        ),
                      ),
                      Text(
                        _getScoreLabel(ratio),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: scoreColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // Score Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: scoreColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    '$score / $maxScore ($percent%)',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: scoreColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Sleek Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                backgroundColor: const Color(0xFFF3E8FF),
                valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              ),
            ),

            const SizedBox(height: 14),

            // Suggestions List
            if (suggestions.isNotEmpty) ...[
              for (var tip in suggestions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4, right: 8),
                        child: Icon(
                          ratio >= 0.8
                              ? Icons.check_circle_outline_rounded
                              : Icons.arrow_right_rounded,
                          size: 16,
                          color: scoreColor,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          tip,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],

            // Matched skills / keyword chips
            if (skills != null && skills!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: skills!.map((label) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF5FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE9D5FF)),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B21A8),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
