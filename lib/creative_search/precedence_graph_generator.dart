import 'package:flutter/material.dart';
import 'precedence_graph.dart';

class PGraphGenerator{
  static PrecedenceNode generateFromString(String searchString){
    Characters characters = (andChar+searchString).characters;
    if (debugLevel > 0) print("generating from: "+characters.string);
    if (characters.isEmpty) return simpleGenerate(""); //ends of recursion
    if (!characters.contains("(")) return simpleGenerate(characters.string);
    int? openLB;
    int lastRB = -1;
    int depth= 0;
    Operands opType;
    PrecedenceNode root = simpleGenerate("");
    for (int i = 0 ; i<characters.length ; i++){
      if ( characters.elementAt(i) == '('){
        if (openLB==null){
          openLB = i;
          opType = opFromString(characters.elementAt(lastRB+1));
          if (debugLevel > 0) print("Simple from ${lastRB+2} to $i");
          registerToAndRoot(root,
              simpleGenerate(characters.getRange(lastRB+1, openLB).string)
              ,opType);
        }
        depth++;
      }
      if( characters.elementAt(i) == ')'){
        depth--;
      }
      if (openLB != null && depth == 0){
        lastRB = i;
        opType = opFromString(characters.elementAt(openLB-1));
        if (debugLevel > 0) print("Generate() from ${openLB+1} to $lastRB");
        registerToAndRoot(root,
            generateFromString(characters.getRange(openLB+1, lastRB).string)
            ,opType);
        openLB = null;
      }
    }
    if (lastRB != characters.length-1){
      if (debugLevel > 0) print("Simple tail from ${lastRB+1} to ${characters.length}");
      opType = opFromString(characters.elementAt(lastRB+1));
      registerToAndRoot(root,
          simpleGenerate(characters.getRange(lastRB+1, characters.length).string),
          opType);
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