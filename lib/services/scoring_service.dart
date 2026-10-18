// The University of Texas at El Paso: Bryan Perez

import 'dart:developer' as developer;
import '../models/resume.dart';
import '../models/section_score.dart';
import '../models/major.dart';
import '../services/section_detector_service.dart';
import '../services/major_detector.dart';
import '../services/ollama_service.dart';
import '../utils/scoring_rules.dart';

/// A service that orchestrates resume analysis:
/// 1. Attempts genuine AI evaluation via local [OllamaService].
/// 2. If Ollama is offline, gracefully falls back to rule-based scoring:
///    - Splits text into sections via [SectionDetectorService].
///    - Detects the applicant’s [Major] via [MajorDetector].
///    - Computes per‐section scores based on [ScoringRules].
///    - Aggregates into a final 0–100 score and produces feedback.
class ScoringService {
  static const int _maxTextLength = 100 * 1024; // 100 KB

  static const List<String> _expectedSections = [
    'contact',
    'summary',
    'experience',
    'education',
    'skills',
    'projects',
    'certifications',
  ];

  /// Runs the full analysis pipeline on [input] and returns a new [Resume]
  /// enriched with score, major, section breakdown, and feedback.
  ///
  /// Throws [ArgumentError] if the input is empty or too large.
  static Future<Resume> analyze(
    Resume input, {
    String? jobDescription,
    bool enableLogging = false,
  }) async {
    final rawText = input.fullText;
    if (rawText.isEmpty) {
      throw ArgumentError('Resume text cannot be empty.');
    }
    if (rawText.length > _maxTextLength) {
      throw ArgumentError(
        'Resume text exceeds maximum of $_maxTextLength characters.',
      );
    }

    // 1) Try Genuine AI Analysis via local Ollama
    final bool aiRunning = await OllamaService.isOllamaRunning();
    if (aiRunning) {
      try {
        if (enableLogging) {
          developer.log('Ollama is reachable. Running deep AI ATS resume analysis...');
        }
        return await OllamaService.analyzeResume(
          input,
          jobDescription: jobDescription,
          enableLogging: enableLogging,
        );
      } catch (e, stack) {
        if (enableLogging) {
          developer.log('Ollama analysis failed, falling back to rule engine: $e\n$stack');
        }
      }
    }

    // 2) Fallback to rule-based analysis
    return _analyzeRuleBased(
      input,
      jobDescription: jobDescription,
      enableLogging: enableLogging,
      wasAiOffline: !aiRunning,
    );
  }

  static Resume _analyzeRuleBased(
    Resume input, {
    String? jobDescription,
    bool enableLogging = false,
    bool wasAiOffline = false,
  }) {
    final rawText = input.fullText;

    // 1) Section detection
    final detected = SectionDetectorService.detectSections(
      rawText,
      enableLogging: enableLogging,
    );

    // 2) Ensure all sections present
    final sections = <String, String>{};
    for (var name in _expectedSections) {
      sections[name] = detected[name] ?? '';
      if (enableLogging && sections[name]!.isEmpty) {
        developer.log('Section missing: $name');
      }
    }

    // 3) Major detection (prefer education section)
    final eduText = sections['education']!.isNotEmpty
        ? sections['education']!
        : rawText;
    final Major? major = MajorDetector.detectMajor(
      eduText,
      enableLogging: enableLogging,
    );
    if (enableLogging) {
      developer.log('Detected major: ${major?.name ?? "none"}');
    }

    // 4) Choose skill list
    final List<String> skillsList = major != null &&
        ScoringRules.majorRelevantSkills.containsKey(major)
        ? ScoringRules.majorRelevantSkills[major]!
        : ScoringRules.generalRelevantSkills;

    // 5) Per‐section scoring
    final breakdown = <SectionScore>[
      _analyzeContact(sections['contact']!, enableLogging),
      _analyzeSummary(sections['summary']!, enableLogging),
      _analyzeExperience(sections['experience']!, enableLogging),
      _analyzeEducation(sections['education']!, enableLogging),
      _analyzeSkills(
        sections['skills']!,
        skillsList,
        major,
        enableLogging,
      ),
      _analyzeProjects(sections['projects']!, enableLogging),
      _analyzeCertifications(sections['certifications']!, enableLogging),
    ];

    // 6) Aggregate & normalize to 0–100
    final rawSum = breakdown.fold<int>(0, (sum, s) => sum + s.achievedScore);
    final normalized =
    (rawSum * 100 ~/ ScoringRules.totalMaxScore).clamp(0, 100);
    if (enableLogging) {
      developer.log('Raw sum=$rawSum, normalized=$normalized');
    }

    // 7) Compile feedback
    final feedback = <String>[];
    for (var sec in breakdown) {
      for (var msg in sec.feedback) {
        feedback.add('${sec.sectionName}: $msg');
      }
    }
    feedback.sort((a, b) {
      final aSec = a.split(':').first.toLowerCase();
      final bSec = b.split(':').first.toLowerCase();
      return (ScoringRules.sectionPriorities[aSec] ?? 0)
          .compareTo(ScoringRules.sectionPriorities[bSec] ?? 0);
    });

    if (major != null) {
      feedback.add(
        'General: Tailor your resume to highlight ${major.name}-specific achievements.',
      );
    }

    if (wasAiOffline) {
      feedback.insert(
        0,
        '⚠️ Ollama is offline. Evaluated using offline rule engine. Start Ollama for deep AI analysis.',
      );
    }

    // 8) Return enriched resume
    return input.copyWith(
      score: normalized,
      atsScore: normalized,
      major: major,
      jobDescription: jobDescription,
      feedback: feedback,
      sectionBreakdown: breakdown,
    );
  }

  // ────────────────────────────────────────────────────────────────────────────

  static SectionScore _analyzeContact(String content, bool log) {
    var pts = 0;
    final fb = <String>[];
    final found = <String>[];

    if (ScoringRules.emailRegex.hasMatch(content)) {
      pts += ScoringRules.contactEmailScore;
      found.add('email');
    } else {
      fb.add('Include a professional email address.');
    }

    if (ScoringRules.phoneRegex.hasMatch(content)) {
      pts += ScoringRules.contactPhoneScore;
      found.add('phone');
    } else {
      fb.add('Add a contact phone number.');
    }

    for (var m in ScoringRules.portfolioRegex.allMatches(content)) {
      final url = m.group(0)!.toLowerCase();
      if (url.contains('linkedin.com')) {
        pts += ScoringRules.contactLinkedInScore;
        found.add('LinkedIn');
      } else if (url.contains('github.com')) {
        pts += ScoringRules.contactGitHubScore;
        found.add('GitHub');
      } else {
        pts += ScoringRules.contactPortfolioScore;
        found.add('portfolio');
      }
    }

    if (!found.contains('LinkedIn')) {
      fb.add('Consider adding a LinkedIn URL.');
    }
    if (!found.contains('GitHub')) {
      fb.add('Consider adding a GitHub URL.');
    }
    if (!found.contains('portfolio')) {
      fb.add('Consider adding a portfolio link.');
    }

    if (log) {
      developer.log('Contact: pts=$pts, found=$found, fb=$fb');
    }

    return SectionScore(
      sectionName: 'Contact',
      maxScore: ScoringRules.contactMax,
      achievedScore: pts.clamp(0, ScoringRules.contactMax),
      feedback: fb,
      rawContent: content,
    );
  }

  static SectionScore _analyzeSummary(String content, bool log) {
    final fb = <String>[];
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      fb.add('Include a summary that highlights your goals.');
    }
    final wc = trimmed.split(RegExp(r'\s+')).length;
    final pts = wc >= ScoringRules.summaryWordThreshold
        ? ScoringRules.summaryMax
        : ScoringRules.summaryPartialScore;
    if (wc < ScoringRules.summaryWordThreshold) {
      fb.add('Aim for at least ${ScoringRules.summaryWordThreshold} words.');
    }
    if (log) {
      developer.log('Summary: wc=$wc, pts=$pts, fb=$fb');
    }
    return SectionScore(
      sectionName: 'Summary',
      maxScore: ScoringRules.summaryMax,
      achievedScore: pts,
      feedback: fb,
      rawContent: content,
    );
  }

  static SectionScore _analyzeExperience(String content, bool log) {
    final fb = <String>[];
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      fb.add('Add a detailed work experience section.');
    }
    var pts =
    trimmed.isNotEmpty ? ScoringRules.experiencePartialScore : 0;

    final verbs = ScoringRules.actionVerbs
        .where((v) => trimmed.toLowerCase().contains(v));
    final vp = (verbs.length * ScoringRules.experienceVerbScore).clamp(
        0,
        ScoringRules.experienceVerbThreshold *
            ScoringRules.experienceVerbScore);
    pts += vp;
    if (verbs.length < ScoringRules.experienceVerbThreshold) {
      fb.add('Use more action verbs (e.g., developed, led).');
    }

    if (ScoringRules.dateRangeRegex.hasMatch(trimmed)) {
      pts += ScoringRules.experienceDateRangeScore;
    } else {
      fb.add('Include clear date ranges (e.g., 2020-2022).');
    }

    if (log) {
      developer.log(
        'Experience: verbs=${verbs.length}, pts=$pts, fb=$fb',
      );
    }

    return SectionScore(
      sectionName: 'Experience',
      maxScore: ScoringRules.experienceMax,
      achievedScore: pts.clamp(0, ScoringRules.experienceMax),
      feedback: fb,
      rawContent: content,
    );
  }

  static SectionScore _analyzeEducation(String content, bool log) {
    final fb = <String>[];
    var pts =
    content.trim().isNotEmpty ? ScoringRules.educationBaseScore : 0;

    final degreeRx = RegExp(
      r'\b(bachelor|master|associate|ph\.?d)\b',
      caseSensitive: false,
    );
    if (degreeRx.hasMatch(content)) {
      pts += ScoringRules.educationDegreeScore;
    } else {
      fb.add('Specify your degree (e.g., Bachelor’s).');
    }

    if (ScoringRules.gradYearRegex.hasMatch(content)) {
      pts += ScoringRules.educationYearScore;
    } else {
      fb.add('Include your graduation year.');
    }

    if (log) {
      developer.log('Education: pts=$pts, fb=$fb');
    }
    return SectionScore(
      sectionName: 'Education',
      maxScore: ScoringRules.educationMax,
      achievedScore: pts.clamp(0, ScoringRules.educationMax),
      feedback: fb,
      rawContent: content,
    );
  }

  static SectionScore _analyzeSkills(
      String content,
      List<String> relevant,
      Major? major,
      bool log,
      ) {
    final fb = <String>[];
    final found = <String>{};
    var pts =
    content.trim().isNotEmpty ? ScoringRules.skillsBaseScore : 0;

    for (var token in content.toLowerCase().split(RegExp(r'[\s,;]+'))) {
      if (ScoringRules.skillToCategory.containsKey(token)) {
        final cat = ScoringRules.skillToCategory[token]!;
        if (relevant.contains(cat)) {
          found.add(cat);
        }
      }
      if (relevant.any((r) => r.toLowerCase() == token)) {
        found.add(token);
      }
    }

    final sp =
    (found.length * ScoringRules.pointsPerSkill).clamp(0, ScoringRules.skillsCap);
    pts += sp;

    if (found.isEmpty) {
      fb.add('List relevant skills (e.g., ${relevant.take(3).join(', ')}).');
    }

    if (log) {
      developer.log('Skills: found=$found, pts=$pts, fb=$fb');
    }
    return SectionScore(
      sectionName: 'Skills',
      maxScore: ScoringRules.skillsMax,
      achievedScore: pts.clamp(0, ScoringRules.skillsMax),
      feedback: fb,
      matchedContent: found.toList(),
      rawContent: content,
    );
  }

  static SectionScore _analyzeProjects(String content, bool log) {
    final fb = <String>[];
    if (content.trim().isEmpty) {
      fb.add('Add at least one project with descriptions.');
      if (log) developer.log('Projects: empty');
      return SectionScore(
        sectionName: 'Projects',
        maxScore: ScoringRules.projectsMax,
        achievedScore: 0,
        feedback: fb,
        rawContent: content,
      );
    }
    if (log) developer.log('Projects: full credit');
    return SectionScore(
      sectionName: 'Projects',
      maxScore: ScoringRules.projectsMax,
      achievedScore: ScoringRules.projectsMax,
      feedback: fb,
      rawContent: content,
    );
  }

  static SectionScore _analyzeCertifications(String content, bool log) {
    final matches = ScoringRules.certificationRegex
        .allMatches(content)
        .map((m) => m.group(0)!.trim())
        .toList();
    final fb = <String>[];
    final pts =
    matches.isNotEmpty ? ScoringRules.certificationsMax : 0;
    if (matches.isEmpty) {
      fb.add('Include any professional certifications.');
    }
    if (log) {
      developer.log('Certifications: matches=$matches, pts=$pts');
    }
    return SectionScore(
      sectionName: 'Certifications',
      maxScore: ScoringRules.certificationsMax,
      achievedScore: pts,
      feedback: fb,
      matchedContent: matches,
      rawContent: content,
    );
  }
}




