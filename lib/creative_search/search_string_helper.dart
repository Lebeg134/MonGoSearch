import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'precedence_graph.dart';

class SearchStringHelper {
  static final Logger _log = Logger('SearchStringHelper');

  void configureLogging({Level level = Level.INFO}) {
    Logger.root.level = level;
    Logger.root.onRecord.listen((rec) {
      debugPrint(
          '${rec.level.name}: ${rec.time}: ${rec.loggerName}: ${rec.message}');
    });
  }

  
  static bool checkValidity(String input) {
    String string = input.replaceAll(" ", "");
    return SearchStringHelper.getBalance(string) == 0 &&
        !string.contains(bracketPatterns);
  }

  static String simplifyResult(String input) {
    _log.fine("Simplify: " + input);
    Set<String> ands = input.split(andSepPattern).toSet();
    ands.remove("");
    String output = "";
    for (String and in ands) {
      Set<String> ors = and.split(orSepPattern).toSet();
      ors.remove("");
      for (String or in ors) {
        output += or;
        if (or != ors.last) {
          output += orChar;
        }
      }
      if (and != ands.last) {
        output += andChar;
      }
    }
    _log.fine("To: " + output);
    return output;
  }

  static int getBalance(String string) {
    int balance = 0;
    for (String char in string.characters) {
      if (char == '(') balance++;
      if (char == ')') balance--;
      if (balance < 0) break;
    }
    return balance;
  }

  static String _output = "";
  static String _modifier = "";
  static Set<Set<String>> _allTags = {};

  /// Strip comments from the input. A comment begins when one or more
  /// whitespace characters are followed by [marker] (default '#'). Everything
  /// from the first whitespace before the marker to the end of the line is
  /// removed. Operates line-by-line.
  static String stripComments(String input, {String marker = '#'}) {
    final lines = input.split(RegExp(r'\r?\n'));
    final out = <String>[];
    final pattern = RegExp(r'\s+' + RegExp.escape(marker));
    for (final line in lines) {
      final m = pattern.firstMatch(line);
      if (m != null) {
        out.add(line.substring(0, m.start));
      } else {
        out.add(line);
      }
    }
    return out.join('\n');
  }

  /// Invert a single token/leaf according to simple heuristics.
  /// Numeric single values become ranges below them (e.g. 4 -> 0-3),
  /// 0 becomes 1+, ranges starting at 0 become negated (e.g. 0-1 -> !0-1),
  /// everything else is negated with a leading '!'.
  static String invertToken(String token) {
    final t = token.trim();
    if (t.isEmpty) return t;
    final single = RegExp(r"^(\d+)\$");
    final range = RegExp(r"^(\d+)-(\d+)");
    final singleMatch = single.firstMatch(t);
    if (singleMatch != null) {
      final n = int.parse(singleMatch.group(1)!);
      if (n == 0) return "1+";
      return "0-${n - 1}";
    }
    final rangeMatch = range.firstMatch(t);
    if (rangeMatch != null) {
      final a = int.parse(rangeMatch.group(1)!);
      // If range starts at 0, express inversion as a negated range (!0-b)
      if (a == 0) return "!${rangeMatch.group(0)}";
      return "0-${a - 1}";
    }
    return "!" + t;
  }

  /// You can only run 1 of this at a time!
  /// It uses static members to save on memory!
  static String getRecursiveMethod(Set<Set<String>> allTags, String modifier) {
    _output = "";
    _modifier = modifier;
    _allTags = allTags;
    _generateRecursive("", allTags.length - 1);
    return _output;
  }

  static void _generateRecursive(String current, int level) {
    if (level < 0) {
      _output += andChar + _modifier + current;
      _log.finer("leaf " + current);
      return;
    }
    _allTags.elementAt(level).forEach((element) {
      _generateRecursive(current + orChar + element, level - 1);
    });
  }
  // Many thanks to my Friend Martin who helped me with this recursive solution!
}
