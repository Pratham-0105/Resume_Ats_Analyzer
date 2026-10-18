// The University of Texas at El Paso: Bryan Perez

import 'package:flutter/foundation.dart';
import '../models/resume.dart';
import '../models/section_score.dart';
import '../models/major.dart';

/// A ChangeNotifier that holds the current Resume under analysis,
/// including its parsed sections, detected major, per-section scores,
/// overall score, and feedback. Widgets can listen to updates
/// to rebuild when the resume state changes.
class ResumeViewModel extends ChangeNotifier {
  Resume _resume = Resume.empty();

  /// The latest resume state.
  Resume get resume => _resume;

  /// Replace the entire resume (e.g., after parsing + scoring).
  void updateResume(Resume newResume) {
    _resume = newResume;
    notifyListeners();
  }

  /// Append additional feedback messages to the existing list.
  void addFeedback(List<String> additional) {
    final merged = [..._resume.feedback, ...additional];
    _resume = _resume.copyWith(feedback: merged);
    notifyListeners();
  }

  /// Overwrite the per-section scores and feedback.
  void setSectionBreakdown(List<SectionScore> sections) {
    _resume = _resume.copyWith(sectionBreakdown: sections);
    notifyListeners();
  }

  /// Update the detected academic major (or clear it by passing null).
  void setMajor(Major? major) {
    _resume = _resume.copyWith(major: major);
    notifyListeners();
  }

  /// Store the raw parsed text blocks for each section.
  void setParsedSections(Map<String, String> blocks) {
    _resume = _resume.copyWith(parsedSections: blocks);
    notifyListeners();
  }

  /// Store the character offsets of each section header.
  void setSectionOffsets(Map<String, int> offsets) {
    _resume = _resume.copyWith(sectionOffsets: offsets);
    notifyListeners();
  }

  String _jobDescription = '';

  /// The target job description to match against.
  String get jobDescription => _jobDescription;

  /// Update the target job description.
  void setJobDescription(String jd) {
    _jobDescription = jd;
    notifyListeners();
  }

  /// Reset everything back to a brand-new, empty resume.
  void clearResume() {
    _resume = Resume.empty();
    _jobDescription = '';
    notifyListeners();
  }
}

