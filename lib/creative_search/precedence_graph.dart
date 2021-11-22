import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

/// debugLevel
/// 0 - off
/// 1 - print data
/// 2 - don't compact
const int debugLevel = 1;
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
  if (debugLevel > 0) print("op from:"+sep);
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
/// Negative node Ids are reserved for status codes
/// Range 200-299 Success:
/// -200 = Root
/// -201 = Made by Lebeg134
/// -204 = Cleared
/// -205 = Empty
Map<Node, String> nodeNames = {
  Node.Id(-200): "AncestorRoot",
  Node.Id(-201): "Made by Lebeg134",
  Node.Id(-204): "Cleared",
  Node.Id(-205): "Empty",
};
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
  /// Returning null means node can be removed from parent
  PrecedenceNode? compact(){
    if (debugLevel > 0){
      int num = node.key!.value;
      print("Compacting node{$num}!");
    }
    if (debugLevel >=2 ) return this;
    if (isEnd()) return this;
    if (!isEnd() && children.isEmpty) return null;
    PrecedenceNode end = this;
    while(end.children.length == 1){
      end = end.children.first;
    }
    if (debugLevel >0) print("end node: {$end}");
    if (end!= this){
      if (debugLevel >0 ){
        int num = end.node.key!.value;
        print("Shortcut to node{$num}!");
      }
      if(end.isEnd() || end.children.isNotEmpty){
        end.compact();
        return end;
      }
    }
    List<PrecedenceNode> newChildren = [];
    for(PrecedenceNode child in children){
      var newChild = child.compact();
      if (newChild != null){
        newChildren.add(newChild);
      }
    }
    children.clear();
    for (PrecedenceNode newchild in newChildren){
      register(newchild);
    }
    return this;
  }
  bool isEnd();
  void removeFromParent(){
    if (parent != null){
      parent!.children.remove(this);
      parent = null;
    }
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
        parent.register(leaf);
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
    // Do nothing with the edges ¯\_(ツ)_/¯
  }
  @override
  void debugPrint() {
    if (debugLevel > 0) print("|Leaf:"+content);
  }

  @override
  bool isEnd() {
    return true;
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
    if (debugLevel > 0) print("|OperandNode:"+getOperandLongName(operand));
  }
  @override
  bool isEnd() {
    return false;
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
        root = PGraphGenerator.generateFromString(string.characters);
      }
    }
    compact();
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
    root!.addToGraph(graph);
    if (graph.nodes.isEmpty){
      graph.addNode(Node.Id(-201));
    }
    return graph;
  }
  void compact(){
    root?.compact();
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
      root.register(middle);
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