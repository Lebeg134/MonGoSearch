import 'package:flutter/material.dart';
import 'precedence_graph.dart';

class SearchStringHelper{
  static String simplifyResult(String input){
    Set<String> ands = input.split(andSepPattern).toSet();
    String output = "";
    for (String and in ands){
      Set<String> ors = and.split(orSepPattern).toSet();
      for (String or in ors){
        output+=or;
        if (or != ors.last){
          output+=orChar;
        }
      }
      if (and != ands.last){
        output+=andChar;
      }
    }
    return output;
  }
  static int getBalance(String string){
    int balance = 0;
    for (String char in string.characters){
      if (char == '(')  balance++;
      if (char == ')')  balance--;
      if (balance < 0) break;
    }
    return balance;
  }

  static String _output = "";
  static String _modifier = "";
  static Set<Set<String>> _allTags = {};
  static bool _debug = false;
  /// You can only run 1 of this at a time!
  /// It uses static members to save on memory!
  static String getRecursiveMethod( Set<Set<String>> allTags, String modifier){
    _output = "";
    _modifier = modifier;
    _allTags = allTags;
    _debug = (DebugData.getDebugLevel() > 0);
    _generateRecursive("", allTags.length-1);
    return _output;
  }
  static void _generateRecursive(String current, int level){
    if (level < 0){
      _output += andChar+_modifier+current;
      if (_debug) print("leaf "+current);
      return;
    }
    _allTags.elementAt(level).forEach((element) {
      _generateRecursive(current+orChar+element, level-1);
    });
  }
  // Many thanks to my Friend Martin who helped me with this recursive solution!
}