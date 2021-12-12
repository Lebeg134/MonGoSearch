import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'precedence_graph_generator.dart';
import 'search_string_helper.dart';

class DebugData{
  /// debugLevel
  /// 0 - off
  /// 1 - print data
  /// 2 - don't generate string
  /// 3 - don't compact
  static void setDebugLevel(int level){
    debugLevel = level;
  }
  static int getDebugLevel(){
    return debugLevel;
  }
}
int debugLevel = 0;
const String orChar = ',';
const String andChar = '&';
const orSepString = "(:|,|;)";
const andSepString = "&";
const allValidCharacters = ",:;&|";
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
      print("Compacting node$num:");
      debugPrint();
    }
    if (debugLevel >=3 ) return this;
    if (isEnd()) return this;
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
    if (debugLevel > 0){
      var num = node.key!.value;
      nodeNames[node] = "$num "+content;
    }
    else{
      nodeNames[node] = content;
    }
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
    if (debugLevel > 0){
      var num = node.key!.value;
      nodeNames[node] = "$num "+getOperandLongName(operand);
    }
    else{
      nodeNames[node] = getOperandLongName(operand);
    }
  }
  OperandNode.empty(Operands operand):this(operand, null, null);

  @override
  String getString() {
    if (children.isEmpty) return "";
    switch(operand){
      case Operands.or:
        return _stringAsOr();
      case Operands.and:
        return _stringAsAnd();
    }
  }
  String _stringAsOr(){
    if (children.isEmpty) return "";
    String string = "";
    bool simple = true;

    for (PrecedenceNode node in children){
      if (!(node is OperandNode && node.operand == Operands.and)){
        string += node.getString();
        string += orChar;
      }
      else{
        simple = false;
      }
    }
    if (simple){
      return string.characters.getRange(0,string.length-1).string;
    }

    Set<Set<String>> allTags = {};
    for (PrecedenceNode node in children){
      if (node is OperandNode && node.operand == Operands.and){
        allTags.add(SearchStringHelper.simplifyResult(node.getString())
            .split(andSepPattern).toSet());
      }
    }
    if (debugLevel > 0){
      int i = 0;
      for(Set<String> slots in allTags){
        print("slot$i");
        print(slots.toString());
        i++;
      }
    }
    String output = SearchStringHelper.getRecursiveMethod(allTags, string);
    if (debugLevel > 0) print(output);
    return output;
  }
  String _stringAsAnd(){
    String string = "";
    for (PrecedenceNode node in children){
      string += node.getString();
      if(node != children.last){
        string += andChar;
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
        edgeColor = Colors.green;
        break;
      case Operands.or:
        edgeColor = Colors.red;
        break;
    }
    graph.addNode(node);
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
  @override
  PrecedenceNode? compact() {
    super.compact(); // because of debug print
    if (debugLevel >=3 ) return this;
    if (children.isEmpty) return null;
    PrecedenceNode end = this;
    while(end.children.length == 1){
      end = end.children.first;
    }
    if (debugLevel >0)
    {
      int num = end.node.key!.value;
      print("end node:$num");
      end.debugPrint();
    }
    if (end!= this){
      if (debugLevel >0 ){
        int num = end.node.key!.value;
        print("Shortcut to node$num!");
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
        if (newChild is OperandNode && operand == newChild.operand){
          for (PrecedenceNode migratingChild in newChild.children){
            newChildren.add(migratingChild);
          }
        }
        else{
          newChildren.add(newChild);
        }
      }
    }

    if (newChildren.isEmpty) return null;
    children.clear();
    for (PrecedenceNode newChild in newChildren){
      register(newChild);
    }
    return this;
  }
}
class PrecedenceGraph{
  PrecedenceNode? root;
  PrecedenceGraph(this.root);
  PrecedenceGraph.fromString(String string){
    globalID = 0;
    //string = string.replaceAll(" ", "");
    if (!string.contains('(')){
      root = PGraphGenerator.simpleGenerate(string);
    }
    else{
      if (!SearchStringHelper.checkValidity(string)){
        root = PrecedenceLeaf.foster("Check your brackets!");
      }
      else{
        root = PGraphGenerator.generateFromString(string.characters.string);
      }
    }
    compact();
  }
  void addRoot(PrecedenceNode root){
    this.root = root;
  }
  String buildString(){
    if (debugLevel >=2) return "Disabled in debugLevel > 1";
    String? output = root?.getString();
    output ??= "Error";
    return SearchStringHelper.simplifyResult(output);
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
    if (debugLevel >0) print("==Compact start==");
    root?.compact();
    if (debugLevel >0) print("==Compact end==");
  }
}

