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
