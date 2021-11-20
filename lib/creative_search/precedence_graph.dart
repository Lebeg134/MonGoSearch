import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

const String orChar = ',';
const String andChar = '&';
const orSepString = "(:|,|;)";
const andSepString = "&";
const allValidCharacters = ",:;&";
Pattern orSepPattern = RegExp(orSepString);
Pattern andSepPattern = RegExp(andSepString);
Pattern bracketPatterns = RegExp(r"\)[^"+allValidCharacters+r")]|"
                                   r"[^"+allValidCharacters+r"(]\(");
enum Operands {or, and}
Operands opFromString(String sep){
  print("op from:"+sep);
  String firstChar = sep.characters.first;
  if (firstChar.contains(orSepPattern)){
    return Operands.or;
  }
  else if(firstChar.contains(andSepPattern)){
    return Operands.and;
  }
  throw "Illegal operand";
}
String getOperandLongName(Operands operand){
  switch(operand){
    case Operands.or: return "OR";
    case Operands.and: return "AND";
  }
}
int globalID = 0;
Map<Node, String> nodeNames = {};
abstract class PrecedenceNode{
  Node node;
  PrecedenceNode? parent;
  List<PrecedenceNode> children;
  PrecedenceNode(this.parent, List<PrecedenceNode>? newChildren):
        children =newChildren??<PrecedenceNode>[],
        node = Node.Id(globalID++);
  String getString(){
    return "dQw4w9WgXcQ"; // ¯\_(ツ)_/¯
  }
  List<Node> getNodes();
  void addToGraph(Graph graph);
  void debugPrint();
  void register(PrecedenceNode precedenceNode){
    children.add(precedenceNode);
    precedenceNode.parent = this;
  }
}

class PrecedenceLeaf extends PrecedenceNode{
  final String content;
  PrecedenceLeaf(this.content, PrecedenceNode? parent): super(parent, null){
    nodeNames[node] = content;
  }
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
  @override
  List<Node> getNodes() {
    return [node];
  }
  @override
  void addToGraph(Graph graph) {
    //graph.addNode(node);
    //debugPrint();
    // Do nothing with the edges ¯\_(ツ)_/¯
  }
  @override
  void debugPrint() {
    print("|Leaf:"+content);
  }
}

class OperandNode extends PrecedenceNode{
  final Operands operand;
  OperandNode(this.operand, List<PrecedenceNode>? terms, PrecedenceNode? parent)
      :super(parent, terms){
    nodeNames[node] = getOperandLongName(operand);
  }
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
  @override
  List<Node> getNodes() {
    List<Node> nodes = [node];
    for(PrecedenceNode pNode in children){
      nodes.addAll(pNode.getNodes());
    }
    return nodes;
  }
  @override
  void addToGraph(Graph graph) {
    Color edgeColor = Colors.black;
    switch (operand){
      case Operands.and:
        edgeColor = Colors.indigo;
        break;
      case Operands.or:
        edgeColor = Colors.deepOrange;
        break;
    }
    graph.addNode(node);
    //debugPrint();
    for(PrecedenceNode pNode in children){
      graph.addEdge(node, pNode.node, paint: Paint()..color = edgeColor);
      pNode.addToGraph(graph);
    }
  }

  @override
  void debugPrint() {
    print("|OperandNode:"+getOperandLongName(operand));
  }
}

class PrecedenceGraph{
  PrecedenceNode? root;
  PrecedenceGraph(this.root);
  PrecedenceGraph.fromString(String string){
    globalID = 0;
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
  Graph toGraph(){
    final Graph graph = Graph()..isTree = true;
    root?.addToGraph(graph);
    return graph;
  }
  void compact(){

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
    print("generating from: "+characters.string);
    if (characters.isEmpty) return null;
    if (!characters.contains("(")) return simpleGenerate(characters.string); //end of recursion
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
    firstLB??= characters.length-1;

    PrecedenceNode? root;


    root = simpleGenerate(characters.getRange(0, firstLB).string);
    Operands opType;

    PrecedenceNode? middle = generateFromString(characters.getRange(firstLB+1, lastRB));
    if (firstLB <= 0){
      root = OperandNode.empty(Operands.and);
      root.register(OperandNode.empty(Operands.or));
      root.register(middle!);
    }
    else{
      opType = opFromString(characters.elementAt(firstLB-1));
      switch(opType){
        case Operands.or:
          root?.children.last.register(middle!);
          break;
        case Operands.and:
          root?.register(middle!);
          root?.register(OperandNode.empty(Operands.or));
          break;
      }
    }
    if (lastRB == characters.length-1) return root;

    opType = opFromString(characters.elementAt(min(lastRB+1, characters.length-1)));
    PrecedenceNode? tail = simpleGenerate(characters.getRange(lastRB+1, characters.length).string);
    switch(opType){
      case Operands.or:
        root?.children.last.register(tail!);
        break;
      case Operands.and:
        root?.register(tail!);
        break;
    }



    //Iterator<OperandNode> orIter = root?.children.iterator as Iterator<OperandNode>;

    /*OperandNode newOrNode = OperandNode.empty(Operands.or);
    PrecedenceNode? root = OperandNode(Operands.and, [newOrNode], null);
    newOrNode.parent = root;
    OperandNode? focus = root as OperandNode?;*/



  /*  if (firstRB! < firstLB){
      PrecedenceNode? beforeFRB = simpleGenerate(characters.getRange(0, firstRB).string);
      Operands opType = opFromString(characters.elementAt(firstRB+1))??Operands.and;
      PrecedenceNode? newNode = generateFromString(characters.getRange(firstRB+2, characters.length));
      if (newNode!=null){
        opNode.children.add(beforeFRB);


        beforeFRB.parent=opNode;
        beforeFRB = opNode;
        opNode.children.add(newNode);
        newNode.parent = opNode;
        return root;
      }
    }*/

    //root = simpleGenerate(characters.getRange(0, firstLB).string);

    return root;
  }
  static PrecedenceNode? simpleGenerate(String string){
    print("simple from: "+string);
    PrecedenceNode root = OperandNode.empty(Operands.and);
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