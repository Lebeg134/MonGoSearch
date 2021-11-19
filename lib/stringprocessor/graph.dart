

enum Operands {or, and}

abstract class PrecedenceNode{
  bool hasChildren = false;
}
class PrecedenceLeaf implements PrecedenceNode{
  final String content;
  PrecedenceLeaf(this.content);
  @override
  bool hasChildren = false;
}
class OperandNode implements PrecedenceNode{
  final Operands operand;
  final PrecedenceNode lhs;
  final PrecedenceNode rhs;
  OperandNode(this.lhs, this.operand, this.rhs);
  @override
  bool hasChildren = true;
}
class PrecedenceGraph implements PrecedenceNode{
  @override
  bool hasChildren = false;
  PrecedenceNode? root;
  PrecedenceGraph(this.root){
    hasChildren = root != null;
  }
  PrecedenceGraph.fromSearch(String search){
    if (search.contains('(')){

    }
    List<String> andSplit = search.split('&');
    List<String> orSplit = search.split(',');

    // Somekind of add leaf as end of recursion
  }
  void addRoot(PrecedenceGraph root){
    this.root = root;
  }

}