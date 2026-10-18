// The University of Texas at El Paso: Bryan Perez

import 'dart:developer' as developer;
import '../utils/section_rules.dart';

/// Splits resume text (with optional `==SECTION==` markers) into named blocks,
/// and infers any unmarked content via regex heuristics. Always returns a map
/// containing every key from [SectionRules.canonicalSections].
class SectionDetectorService {
  /// Ensures we don’t process extremely large blobs.
  static const int _maxTextLength = SectionRules.maxTextLength;

  /// Main entry point: returns a map sectionName → sectionText.
  static Map<String, String> detectSections(
      String text, {
        bool enableLogging = false,
      }) {
    if (text.length > _maxTextLength) {
      throw ArgumentError('Input exceeds $_maxTextLength characters');
    }
    // Prepare the output with empty strings for every section
    final out = <String, String>{};
    for (final sec in SectionRules.canonicalSections) {
      out[sec] = '';
    }

    // Helper to flush buffer into the current section
    void flush(String current, StringBuffer buf) {
      final content = buf.toString().trim();
      if (content.isNotEmpty) {
        out[current] = ('${out[current]!}\n$content').trim();
        if (enableLogging) {
          developer.log('Flushed to [$current]: ${content.length} chars');
        }
      }
      buf.clear();
    }

    final matches = SectionRules.sectionMarker.allMatches(text).toList();
    final buf = StringBuffer();
    var current = 'contact';

    // Process explicitly marked sections
    for (var i = 0; i < matches.length; i++) {
      // Flush previous buffer
      flush(current, buf);

      final header = matches[i].group(1)!.toLowerCase().trim();
      current = SectionRules.aliasToSection[header] ?? 'miscellaneous';
      if (enableLogging) {
        developer.log('Explicit marker: switching to "$current"');
      }

      // Determine the span of this section’s body
      final start = matches[i].end;
      final end = (i + 1 < matches.length) ? matches[i + 1].start : text.length;
      buf.write(text.substring(start, end));
    }
    // After markers, anything not consumed above
    if (matches.isEmpty) {
      buf.write(text);
    }
    // Now fallback‐infer on a line‐by‐line basis for unmarked text
    final lines = buf.toString().split('\n');
    buf.clear();
    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;

      // If line itself is a marker, flush & switch
      final m = SectionRules.sectionMarker.firstMatch(raw);
      if (m != null) {
        flush(current, buf);
        final hdr = m.group(1)!.toLowerCase().trim();
        current = SectionRules.aliasToSection[hdr] ?? 'miscellaneous';
        if (enableLogging) {
          developer.log('Fallback marker detected: "$current"');
        }
        continue;
      }

      // Heuristic switches
      if (SectionRules.educationPattern.hasMatch(line)) {
        flush(current, buf);
        current = 'education';
      } else if (SectionRules.contactPattern.hasMatch(line)) {
        flush(current, buf);
        current = 'contact';
      } else if (SectionRules.summaryPattern.hasMatch(line)) {
        flush(current, buf);
        current = 'summary';
      } else if (SectionRules.datePattern.hasMatch(line)) {
        flush(current, buf);
        current = 'experience';
      } else if (SectionRules.bulletPattern.hasMatch(line) ||
          SectionRules.skillsPattern.hasMatch(line)) {
        flush(current, buf);
        current = 'skills';
      }

      // Append to current buffer
      buf.writeln(raw);
    }
    // Flush the very last buffer
    flush(current, buf);

    return out;
  }
}
