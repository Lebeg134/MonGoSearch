import 'package:flutter/material.dart';
import 'precedence_graph.dart';
import 'search_string_helper.dart';

class PGraphGenerator{
  static bool checkValidity(String input){
    String string = input.replaceAll(" ", "");
    return SearchStringHelper.getBalance(string)==0 && !string.contains(bracketPatterns);
  }
  static PrecedenceNode generateFromString(Characters characters){
    if (debugLevel > 0) print("generating from: "+characters.string);
    if (characters.isEmpty) return simpleGenerate(""); //ends of recursion
    if (!characters.contains("(")) return simpleGenerate(characters.string);
    int? openLB;
    int? closeRB;
    int depth= 0;
    for (int i = 0 ; i<characters.length ; i++){
      if ( characters.elementAt(i) == '('){
        openLB??=i;
        depth++;
      }
      if( characters.elementAt(i) == ')'){
        depth--;
      }
      if (openLB != null && depth == 0){
        closeRB??= i;
      }
    }

    openLB??= characters.length-1;
    closeRB??= characters.length-1;
    if (debugLevel > 0) print("generating root:");
    PrecedenceNode root = simpleGenerate(characters.getRange(0, openLB).string);
    if (debugLevel > 0) print("generating middle: openLB: {$openLB} closeRB:{$closeRB}");
    PrecedenceNode middle = generateFromString(characters.getRange(openLB+1, closeRB));
    Operands opType;
    if (openLB <= 0){
      root.children.first.register(middle);
    }
    else{
      opType = opFromString(characters.elementAt(openLB-1));
      registerToAndRoot(root, middle, opType);
    }
    if (closeRB != characters.length-1){
      if (debugLevel > 0) print("generating tail:");
      opType = opFromString(characters.elementAt(closeRB+1));
      PrecedenceNode tail = generateFromString(characters.getRange(closeRB+1, characters.length));
      registerToAndRoot(root, tail, opType);
    }
    return root;
  }
  static void registerToAndRoot(PrecedenceNode root, PrecedenceNode node, Operands opType){
    if (opType == Operands.and || root.children.isEmpty){ // Check this if something is incorrect
      root.register(OperandNode.empty(Operands.or));
    }
    root.children.last.register(node);
  }
  static PrecedenceNode simpleGenerate(String string){
    if (string.characters.isEmpty){
      PrecedenceNode? root = OperandNode.empty(Operands.and);
      root.register(OperandNode.empty(Operands.or));
      return root;
    }
    if (debugLevel > 0) print("simple from: "+string);
    PrecedenceNode root = OperandNode.empty(Operands.and);
    for (String ands in string.split(andSepPattern)){
      if(ands.isNotEmpty){
        OperandNode or = OperandNode(Operands.or, null, root);
        List<String> ors = ands.split(orSepPattern);
        ors.removeWhere((element) => element == "");
        if (ors.isNotEmpty){
          root.children.add(or);
          PrecedenceLeaf.fromStrings(ors, or);
        }
      }
    }
    return root;
  }
}