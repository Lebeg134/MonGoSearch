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
}