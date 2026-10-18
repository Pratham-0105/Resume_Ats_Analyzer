// The University of Texas at El Paso: Bryan Perez

import 'dart:developer' as developer;

/// Model representing the evaluation result of a specific section in the resume.
/// Used by `ScoringService` to store per-section scores, feedback, and related data
/// within `Resume.sectionBreakdown`.
class SectionScore {
  /// Name of the resume section (e.g., "Contact Info", "Work Experience", "Skills").
  /// Note: These are display-friendly names, which may differ from the internal keys
  /// used in `ScoringRules` (e.g., 'contact', 'experience', 'skills') for feedback sorting.
  final String sectionName;

  /// Maximum possible points for this section, as defined in `ScoringRules`.
  final int maxScore;

  /// Actual score assigned during evaluation, clamped between 0 and `maxScore`.
  final int achievedScore;

  /// List of feedback tips or suggestions related to this section.
  final List<String> feedback;

  /// List of matched keywords, skills, or items in the section (e.g., action verbs for
  /// experience, skills for skills section). Empty if no matches are found or if the section
  /// does not support keyword matching (e.g., contact, summary).
  final List<String> matchedContent;

  /// Raw block of text extracted from the resume for this section.
  final String rawContent;

  /// Creates a new `SectionScore` instance with the provided fields.
  ///
  /// [sectionName] The display name of the section (e.g., "Work Experience").
  /// [maxScore] The maximum possible score for this section (must be positive).
  /// [achievedScore] The score achieved for this section (must be between 0 and `maxScore`).
  /// [feedback] A list of feedback messages for this section.
  /// [matchedContent] A list of matched keywords or items (defaults to empty list if null).
  /// [rawContent] The raw text content of this section (defaults to empty string if null).
  /// [enableLogging] If true, logs validation errors for debugging (default: false).
  ///
  /// Throws:
  /// - [ArgumentError] If [sectionName] is empty, [maxScore] is not positive, or
  ///   [achievedScore] is negative or exceeds [maxScore].
  SectionScore({
    required this.sectionName,
    required this.maxScore,
    required this.achievedScore,
    required List<String> feedback,
    List<String>? matchedContent,
    String? rawContent,
    bool enableLogging = false,
  })  : feedback = List.unmodifiable(feedback),
        matchedContent = List.unmodifiable(matchedContent ?? []),
        rawContent = rawContent ?? '' {
    // Validate inputs
    if (sectionName.isEmpty) {
      if (enableLogging) {
        developer.log('Validation Error: sectionName cannot be empty');
      }
      throw ArgumentError('sectionName cannot be empty');
    }
    if (maxScore <= 0) {
      if (enableLogging) {
        developer.log('Validation Error: maxScore must be positive, got $maxScore');
      }
      throw ArgumentError('maxScore must be positive');
    }
    if (achievedScore < 0) {
      if (enableLogging) {
        developer.log('Validation Error: achievedScore cannot be negative, got $achievedScore');
      }
      throw ArgumentError('achievedScore cannot be negative');
    }
    if (achievedScore > maxScore) {
      if (enableLogging) {
        developer.log('Validation Error: achievedScore ($achievedScore) cannot exceed maxScore ($maxScore)');
      }
      throw ArgumentError('achievedScore cannot exceed maxScore');
    }
  }

  /// Returns true if the section achieved the maximum possible score.
  bool get isPerfectScore => achievedScore >= maxScore;

  /// Returns true if the section scored zero points.
  bool get isEmpty => achievedScore == 0;

  /// Returns the normalized score as a percentage (0–100), using integer division
  /// to align with `ScoringService`'s normalization logic.
  /// Returns 0 if `maxScore` is zero to avoid division by zero.
  int get normalized => maxScore > 0 ? (achievedScore * 100) ~/ maxScore : 0;

  @override
  String toString() => '$sectionName: $achievedScore/$maxScore';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SectionScore &&
              runtimeType == other.runtimeType &&
              sectionName == other.sectionName &&
              maxScore == other.maxScore &&
              achievedScore == other.achievedScore &&
              feedback == other.feedback &&
              matchedContent == other.matchedContent &&
              rawContent == other.rawContent;

  @override
  int get hashCode =>
      sectionName.hashCode ^
      maxScore.hashCode ^
      achievedScore.hashCode ^
      feedback.hashCode ^
      matchedContent.hashCode ^
      rawContent.hashCode;
}

