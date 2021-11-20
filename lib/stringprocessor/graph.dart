import 'package:flutter/material.dart';

enum Operands {or, and}
const String orChar = ',';
const String andChar = '&';
const orSepString = "(:|,|;)";
const andSepString = "&";
const allSepCharacters = ",:;&";
Pattern orSepPattern = RegExp(orSepString);
Pattern andSepPattern = RegExp(andSepString);
Pattern leftBracketPattern = RegExp(r"\)[^"+allSepCharacters+r"]|[^"+allSepCharacters+r"]\(");


abstract class PrecedenceNode{
  PrecedenceNode? parent;
  List<PrecedenceNode>? children;
  PrecedenceNode(this.parent, this.children){
      children??= <PrecedenceNode>[];
  }
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
  static List<PrecedenceNode> fromStrings(List<String> strings,PrecedenceNode parent){
    List<PrecedenceNode> output = <PrecedenceLeaf>[];
    for (String string in strings){
      PrecedenceLeaf leaf = PrecedenceLeaf(string, parent);
      parent.children?.add(leaf);
      output.add(leaf);
    }
    return output;
  }
}
class OperandNode extends PrecedenceNode{
  final Operands operand;
  OperandNode(this.operand, List<PrecedenceNode>? terms, PrecedenceNode? parent):super(parent, terms);
  OperandNode.empty(Operands operand):this(operand, null, null);
  @override
  String getString(){
    if (children == null) return "";
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
    for (PrecedenceNode node in children!){
      string += node.getString();
      if(node != children?.last){
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
      if (!PGraphGenerator.checkBalance(string)){
        root = PrecedenceLeaf.foster("Brackets not balanced!");
      }
      else{
        root = PrecedenceLeaf.foster("Working on it...");
        //root = PGraphGenerator.generateFromString(string);
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
  static bool checkBalance(String string){
    return getBalance(string)==0;
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
  static PrecedenceNode? generateFromString(String string){
    Characters characters = Characters(string);
    if (characters.isEmpty) return null;

    PrecedenceNode root = OperandNode.empty(Operands.and);
    PrecedenceLeaf("", null);
    PrecedenceNode focus = root;
    for (int i = 0; i<characters.length ; i++){
      var char = characters.elementAt(i);
      if ( char == '('){
        //Do something recursive
        //Skip some chars according to the top stuff
        focus;
      }
      if (char == '');
    }


    string.codeUnits.removeAt(0);

    return PrecedenceLeaf(string, null);
  }
  static PrecedenceNode? simpleGenerate(String string){
    PrecedenceNode root = OperandNode(Operands.and, null, null);

    for (String ands in string.split(andSepPattern)){
      OperandNode ors = OperandNode(Operands.or, null, root);
      root.children?.add(ors);
      ors.children = PrecedenceLeaf.fromStrings(ands.split(orSepPattern), ors);
    }
    return root;
  }
}