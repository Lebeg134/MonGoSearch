import 'package:flutter/material.dart';

const String orChar = ',';
const String andChar = '&';
const orSepString = "(:|,|;)";
const andSepString = "&";
const allSepCharacters = ",:;&";
Pattern orSepPattern = RegExp(orSepString);
Pattern andSepPattern = RegExp(andSepString);
Pattern bracketPatterns = RegExp(r"\)[^"+allSepCharacters+r"]|"
                                   r"[^"+allSepCharacters+r"]\(");
enum Operands {or, and}
Operands? opFromString(String sep){
  String firstChar = sep.characters.first;
  Operands? operand;
  if (firstChar.contains(orSepPattern)){
    operand = Operands.or;
  }
  else if(firstChar.contains(andSepPattern)){
    operand = Operands.and;
  }
  return operand;
}

abstract class PrecedenceNode{
  PrecedenceNode? parent;
  List<PrecedenceNode> children;
  PrecedenceNode(this.parent, List<PrecedenceNode>? newChildren):
        children =newChildren??<PrecedenceNode>[];
  String getString(){
    return "dQw4w9WgXcQ"; // ¯\_(ツ)_/¯
  }
}
class PrecedenceLeaf extends PrecedenceNode{
  final String content;
  PrecedenceLeaf(this.content, PrecedenceNode? parent): super(parent, null);
  PrecedenceLeaf.foster(String content):this(content, null);
  @override
  String getString(){
    return content;
  }
  static List<PrecedenceNode>
  fromStrings(List<String> strings,PrecedenceNode parent){
    List<PrecedenceNode> output = <PrecedenceLeaf>[];
    for (String string in strings){
      if (string.isNotEmpty){
        PrecedenceLeaf leaf = PrecedenceLeaf(string, parent);
        parent.children.add(leaf);
        output.add(leaf);
      }
    }
    return output;
  }
}

class OperandNode extends PrecedenceNode{
  final Operands operand;
  OperandNode(this.operand, List<PrecedenceNode>? terms, PrecedenceNode? parent)
      :super(parent, terms);
  OperandNode.empty(Operands operand):this(operand, null, null);
  @override
  String getString(){
    if (children.isEmpty) return "";
    String string = "";
    String sep;
    switch(operand){
      case Operands.or:
        sep = orChar;
        break;
      case Operands.and:
        sep = andChar;
        break;
    }
    for (PrecedenceNode node in children){
      string += node.getString();
      if(node != children.last){
        string += sep;
      }
    }
    return string;
  }
}

class PrecedenceGraph{
  PrecedenceNode? root;
  PrecedenceGraph(this.root);
  PrecedenceGraph.fromString(String string){
    string = string.replaceAll(" ", "");
    if (!string.contains('(')){
      root = PGraphGenerator.simpleGenerate(string);
    }
    else{
      if (!PGraphGenerator.checkValidity(string)){
        root = PrecedenceLeaf.foster("Check your brackets!");
      }
      else{
        //root = PrecedenceLeaf.foster("Working on it...");
        root = PGraphGenerator.generateFromString(string.characters);
      }

    }
  }
  void addRoot(PrecedenceNode root){
    this.root = root;
  }
  String buildString(){
    String? ret = root?.getString();
    ret ??= "";
    return ret;
  }
}

class PGraphGenerator{
  static bool checkValidity(String input){
    String string = input.replaceAll(" ", "");
    return getBalance(string)==0 && !string.contains(bracketPatterns);
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
  static PrecedenceNode? generateFromString(Characters characters){
    if (characters.isEmpty) return null;
    int? firstLB;
    int? firstRB;
    int lastRB = 0;
    for (int i = 0 ; i<characters.length ; i++){
      if ( characters.elementAt(i) == '('){
        firstLB??=i;
      }
      if ( characters.elementAt(i) == ')'){
        firstRB??=i;
        lastRB = i;
      }
    }
    PrecedenceNode? root = simpleGenerate(characters.getRange(0, firstLB).string);
    PrecedenceNode? middle = generateFromString(characters.getRange(
        firstLB == null ? lastRB-1 : firstLB +1,
        lastRB-1));
    PrecedenceNode? tail = simpleGenerate(characters.getRange(lastRB+1, characters.length).string);

    /*if (firstRB == lastRB){
      middle = simpleGenerate(characters.getRange(firstLB??lastRB, lastRB).string);
    }
    else{
      if (firstRB != null){
        Operands? op = opFromString(characters.elementAt(firstRB+1));
        if (op != null){
          middle = OperandNode.empty(op);
          PrecedenceNode? newNode = simpleGenerate(characters.getRange(firstLB??0, firstRB).string);
          if (newNode != null){
            middle.children.add(newNode);
          }
          newNode = generateFromString(characters.getRange(firstRB+2, lastRB-1));
        }
      }
    }*/
    return root;
  }
  static PrecedenceNode? simpleGenerate(String string){
    PrecedenceNode root = OperandNode(Operands.and, null, null);

    for (String ands in string.split(andSepPattern)){
      if(ands.isNotEmpty){
        OperandNode or = OperandNode(Operands.or, null, root);
        List<String> ors = ands.split(orSepPattern);
        ors.removeWhere((element) => element == "");
        if (ors.isNotEmpty){
          root.children.add(or);
          or.children = PrecedenceLeaf.fromStrings(ors, or);
        }
      }
    }
    return root;
  }
}