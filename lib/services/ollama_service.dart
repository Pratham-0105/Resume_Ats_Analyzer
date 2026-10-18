// The University of Texas at El Paso: Bryan Perez
// Enhanced with local Ollama AI Integration & Advanced ATS Scoring

import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/major.dart';
import '../models/resume.dart';
import '../models/section_score.dart';

/// Service that connects to a local Ollama instance to provide genuine,
/// in-depth, ATS-standard resume evaluation matched against job descriptions.
class OllamaService {
  /// Default endpoint. Points to the live Render cloud backend for universal mobile access.
  static String get defaultBaseUrl =>
      'https://smart-resume-backend-jt2d.onrender.com';

  /// Current base URL for Ollama / Cloud ATS backend. Can be updated dynamically from the UI.
  static String baseUrl = defaultBaseUrl;

  /// Default model to use.
  static String model = 'llama3.2';

  static const bool kIsWeb = bool.fromEnvironment('dart.library.js_util');

  /// Updates the base URL (cleans protocol and trailing slashes).
  static void setBaseUrl(String url) {
    var clean = url.trim();
    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      clean = 'http://$clean';
    }
    if (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }
    baseUrl = clean;
  }

  /// Checks if the Ollama / Cloud server is up and responsive.
  static Future<bool> isOllamaRunning({Duration timeout = const Duration(seconds: 8)}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/tags');
      final res = await http.get(uri).timeout(timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Retrieves list of installed models from Ollama.
  static Future<List<String>> getAvailableModels() async {
    try {
      final uri = Uri.parse('$baseUrl/api/tags');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final models = (data['models'] as List?)
            ?.map((m) => m['name'] as String? ?? '')
            .where((name) => name.isNotEmpty)
            .toList() ?? [];
        return models;
      }
    } catch (e) {
      developer.log('Error fetching Ollama models: $e');
    }
    return [];
  }

  /// Performs deep AI resume analysis using Ollama against optional [jobDescription].
  static Future<Resume> analyzeResume(
    Resume input, {
    String? jobDescription,
    bool enableLogging = false,
  }) async {
    final rawText = input.fullText.trim();
    if (rawText.isEmpty) {
      throw ArgumentError('Resume text is empty.');
    }

    final prompt = _buildAtsAnalysisPrompt(rawText, jobDescription: jobDescription);

    final payload = {
      'model': model,
      'prompt': prompt,
      'stream': false,
      'format': 'json',
      'options': {
        'temperature': 0.15, // Low temperature for deterministic, calibrated ATS scoring
      }
    };

    if (enableLogging) {
      developer.log('Sending resume to Ollama ($baseUrl, model: $model, hasJD: ${jobDescription != null})...');
    }

    final uri = Uri.parse('$baseUrl/api/generate');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 120));

    if (response.statusCode != 200) {
      throw HttpException(
        'Ollama returned error ${response.statusCode}: ${response.body}',
      );
    }

    final Map<String, dynamic> responseBody = jsonDecode(response.body);
    final String responseText = responseBody['response'] ?? '';

    if (enableLogging) {
      developer.log('Ollama raw AI response received.');
    }

    final Map<String, dynamic> aiJson = jsonDecode(responseText);

    return _parseAiResponseToResume(input, aiJson, jobDescription, enableLogging);
  }

  static String _buildAtsAnalysisPrompt(String resumeText, {String? jobDescription}) {
    final jdSection = (jobDescription != null && jobDescription.trim().isNotEmpty)
        ? '''
TARGET JOB DESCRIPTION:
"""
${jobDescription.trim()}
"""
Compare the candidate's resume directly against the requirements, keywords, technologies, and seniority level in the Target Job Description above.
'''
        : '''
(No specific Job Description provided. Evaluate against modern industry ATS benchmarks for the candidate's field).
''';

    return '''
You are an expert ATS (Applicant Tracking System) Scanner and Senior Corporate Recruiter.
Analyze this resume with rigor according to professional ATS scanning standards.

$jdSection

RESUME TEXT:
"""
$resumeText
"""

ATS EVALUATION CRITERIA:
1. Overall Quality Score (0-100): General caliber, readability, and career trajectory.
2. ATS Match Score (0-100): ATS keyword density, formatting compatibility, and job match percentage.
3. Detected Major/Field: e.g. "Computer Science", "Information Technology", "Mechanical Engineering", "Finance", "Healthcare", "Marketing", etc.
4. Matched Keywords: Hard/soft skills, tools, and methodologies from the resume that match industry/JD expectations.
5. Missing Keywords: High-value keywords or tools expected for this role/field that are noticeably absent.
6. Role Fit Summary: 1-2 sharp sentences summarizing the candidate's suitability and biggest edge or gap.
7. Detailed Section Scores:
   Evaluate each section thoroughly with an achievedScore out of maxScore (normalized points), specific critique, and matched keywords:
   - "Contact Information" (maxScore: 10): Name clarity, phone, email, LinkedIn URL, GitHub/Portfolio, location.
   - "Professional Summary" (maxScore: 15): Clear elevator pitch, target role title, key years of experience, core value proposition.
   - "Work Experience" (maxScore: 30): Quantified achievements (%, numbers, \$), action verbs (Architected, Spearheaded, Optimized), bullet structure (Action + Context + Result).
   - "Skills & Technologies" (maxScore: 20): Relevant languages, frameworks, cloud/tools, grouped logically.
   - "Education & Academic" (maxScore: 10): Degree, institution, year, relevant coursework/honors.
   - "Projects" (maxScore: 10): Complexity, impact, live link or tech stack utilized.
   - "Certifications" (maxScore: 5): Recognized credentials (e.g. AWS, Cisco, PMP, Scrum) or relevant licenses.
8. Actionable ATS Suggestions: Top 4 high-priority, concrete recommendations to increase ATS pass rate and recruiter callback rate.

Provide your evaluation strictly as a valid JSON object following this EXACT schema:
{
  "overallScore": <integer 0-100>,
  "atsScore": <integer 0-100>,
  "detectedMajor": "<string>",
  "roleFitSummary": "<string>",
  "matchedKeywords": ["<keyword1>", "<keyword2>", "<keyword3>", "<keyword4>", "<keyword5>"],
  "missingKeywords": ["<missing1>", "<missing2>", "<missing3>"],
  "sections": [
    {
      "sectionName": "Contact Information",
      "achievedScore": <integer 0-10>,
      "maxScore": 10,
      "feedback": ["<specific observation/tip>"],
      "matchedContent": ["<items found>"]
    },
    {
      "sectionName": "Professional Summary",
      "achievedScore": <integer 0-15>,
      "maxScore": 15,
      "feedback": ["<critique and improvements>"],
      "matchedContent": []
    },
    {
      "sectionName": "Work Experience",
      "achievedScore": <integer 0-30>,
      "maxScore": 30,
      "feedback": ["<specific feedback on metrics and action verbs>"],
      "matchedContent": ["<strong verbs and metrics found>"]
    },
    {
      "sectionName": "Skills & Technologies",
      "achievedScore": <integer 0-20>,
      "maxScore": 20,
      "feedback": ["<feedback on skill density & missing skills>"],
      "matchedContent": ["<detected skills>"]
    },
    {
      "sectionName": "Education",
      "achievedScore": <integer 0-10>,
      "maxScore": 10,
      "feedback": ["<feedback on education presentation>"],
      "matchedContent": ["<degree found>"]
    },
    {
      "sectionName": "Projects",
      "achievedScore": <integer 0-10>,
      "maxScore": 10,
      "feedback": ["<feedback on project complexity>"],
      "matchedContent": ["<projects found>"]
    },
    {
      "sectionName": "Certifications",
      "achievedScore": <integer 0-5>,
      "maxScore": 5,
      "feedback": ["<feedback on certifications>"],
      "matchedContent": ["<credentials found>"]
    }
  ],
  "finalSuggestions": [
    "<High-impact ATS improvement suggestion 1>",
    "<High-impact suggestion 2>",
    "<High-impact suggestion 3>",
    "<High-impact suggestion 4>"
  ]
}

Return ONLY the raw JSON object. Do not wrap in markdown quotes or extra conversational text.
''';
  }

  static Resume _parseAiResponseToResume(
    Resume original,
    Map<String, dynamic> aiJson,
    String? jobDescription,
    bool enableLogging,
  ) {
    // 1. Scores
    final int overallScore = ((aiJson['overallScore'] as num?)?.toInt() ?? 50).clamp(0, 100);
    final int atsScore = ((aiJson['atsScore'] as num?)?.toInt() ?? overallScore).clamp(0, 100);

    // 2. Detected Major
    final String majorName = aiJson['detectedMajor']?.toString() ?? 'General';
    Major? detectedMajor;
    for (final m in Major.values) {
      if (m.name.toLowerCase() == majorName.toLowerCase() ||
          majorName.toLowerCase().contains(m.name.toLowerCase())) {
        detectedMajor = m;
        break;
      }
    }
    detectedMajor ??= Major.computerScience;

    // 3. Keywords & Summary
    final List<String> matchedKeywords = (aiJson['matchedKeywords'] as List?)
            ?.map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];

    final List<String> missingKeywords = (aiJson['missingKeywords'] as List?)
            ?.map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];

    final String? roleFitSummary = aiJson['roleFitSummary']?.toString();

    // 4. Section breakdown
    final List<SectionScore> sections = [];
    final rawSections = aiJson['sections'] as List? ?? [];

    for (final sec in rawSections) {
      if (sec is! Map) continue;
      final String name = sec['sectionName']?.toString() ?? 'Section';
      final int max = ((sec['maxScore'] as num?)?.toInt() ?? 10).clamp(1, 100);
      final int achieved = ((sec['achievedScore'] as num?)?.toInt() ?? 0).clamp(0, max);
      final List<String> feedback = (sec['feedback'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          [];
      final List<String> matched = (sec['matchedContent'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          [];

      try {
        sections.add(
          SectionScore(
            sectionName: name,
            maxScore: max,
            achievedScore: achieved,
            feedback: feedback.isEmpty ? ['Meets ATS baseline.'] : feedback,
            matchedContent: matched,
            rawContent: '',
            enableLogging: enableLogging,
          ),
        );
      } catch (e) {
        if (enableLogging) developer.log('Error creating SectionScore for $name: $e');
      }
    }

    // 5. Final suggestions
    final List<String> suggestions = (aiJson['finalSuggestions'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];

    if (jobDescription != null && jobDescription.trim().isNotEmpty) {
      suggestions.insert(
        0,
        '🎯 Tailored ATS Analysis matched against your Target Job Description.',
      );
    } else {
      suggestions.insert(
        0,
        '🤖 Evaluated with Local Ollama AI ($model) using ATS Industry Standards.',
      );
    }

    return original.copyWith(
      score: overallScore,
      atsScore: atsScore,
      major: detectedMajor,
      jobDescription: jobDescription,
      matchedKeywords: matchedKeywords,
      missingKeywords: missingKeywords,
      roleFitSummary: roleFitSummary,
      feedback: suggestions,
      sectionBreakdown: sections,
      enableLogging: enableLogging,
    );
  }
}
