// The University of Texas at El Paso: Bryan Perez

import 'dart:io';
import '../models/section_score.dart';
import '../models/major.dart';

/// Represents a fully parsed and scored resume.
class Resume {
  static const int _maxTextLength = 100 * 1024; // 100 KB

  final String fileName;
  final String fullText;
  final File? file;
  final Major? major;
  final int score;
  final int atsScore;
  final String? jobDescription;
  final List<String> matchedKeywords;
  final List<String> missingKeywords;
  final String? roleFitSummary;
  final List<String> feedback;
  final List<SectionScore> sectionBreakdown;
  final Map<String, String> parsedSections;
  final Map<String, int> sectionOffsets;

  /// Main constructor, validates [fileName] and [fullText].
  Resume({
    required this.fileName,
    required this.fullText,
    this.file,
    this.major,
    this.score = 0,
    int? atsScore,
    this.jobDescription,
    List<String>? matchedKeywords,
    List<String>? missingKeywords,
    this.roleFitSummary,
    List<String>? feedback,
    List<SectionScore>? sectionBreakdown,
    Map<String, String>? parsedSections,
    Map<String, int>? sectionOffsets,
    bool enableLogging = false,
  })  : atsScore = atsScore ?? score,
        matchedKeywords = matchedKeywords ?? [],
        missingKeywords = missingKeywords ?? [],
        feedback = feedback ?? [],
        sectionBreakdown = sectionBreakdown ?? [],
        parsedSections = parsedSections ?? {},
        sectionOffsets = sectionOffsets ?? {} {
    if (fileName.isEmpty) {
      if (enableLogging) {
        // ignore: avoid_print
        print('Validation Error: fileName cannot be empty');
      }
      throw ArgumentError('fileName cannot be empty');
    }
    if (fullText.isEmpty) {
      if (enableLogging) {
        // ignore: avoid_print
        print('Validation Error: fullText cannot be empty');
      }
      throw ArgumentError('fullText cannot be empty');
    }
    if (fullText.length > _maxTextLength) {
      if (enableLogging) {
        // ignore: avoid_print
        print('Validation Error: fullText exceeds $_maxTextLength characters');
      }
      throw ArgumentError('fullText exceeds maximum length ($_maxTextLength)');
    }
  }

  /// An “empty” placeholder resume. Uses a single space so it passes validation.
  factory Resume.empty() => Resume(
    fileName: 'empty_resume',
    fullText: ' ',
  );

  /// Creates a copy with updated fields. Runs the same validations.
  Resume copyWith({
    String? fileName,
    String? fullText,
    File? file,
    Major? major,
    int? score,
    int? atsScore,
    String? jobDescription,
    List<String>? matchedKeywords,
    List<String>? missingKeywords,
    String? roleFitSummary,
    List<String>? feedback,
    List<SectionScore>? sectionBreakdown,
    Map<String, String>? parsedSections,
    Map<String, int>? sectionOffsets,
    bool enableLogging = false,
  }) {
    return Resume(
      fileName: fileName ?? this.fileName,
      fullText: fullText ?? this.fullText,
      file: file ?? this.file,
      major: major ?? this.major,
      score: score ?? this.score,
      atsScore: atsScore ?? this.atsScore,
      jobDescription: jobDescription ?? this.jobDescription,
      matchedKeywords: matchedKeywords != null
          ? List.from(matchedKeywords)
          : List.from(this.matchedKeywords),
      missingKeywords: missingKeywords != null
          ? List.from(missingKeywords)
          : List.from(this.missingKeywords),
      roleFitSummary: roleFitSummary ?? this.roleFitSummary,
      feedback: feedback != null ? List.from(feedback) : List.from(this.feedback),
      sectionBreakdown: sectionBreakdown != null
          ? List.from(sectionBreakdown)
          : List.from(this.sectionBreakdown),
      parsedSections: parsedSections != null
          ? Map.from(parsedSections)
          : Map.from(this.parsedSections),
      sectionOffsets: sectionOffsets != null
          ? Map.from(sectionOffsets)
          : Map.from(this.sectionOffsets),
      enableLogging: enableLogging,
    );
  }

  @override
  String toString() =>
      'Resume(fileName: $fileName, score: $score, major: $major)';
}


