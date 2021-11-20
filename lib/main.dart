import 'package:flutter/material.dart';
import 'package:mon_go_search/creative_search/precedence_graph.dart';
import 'package:graphview/GraphView.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MonGo Search',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'MonGo Creative Search'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _text ="";
  PrecedenceGraph? precedenceGraph;

  void _incrementCounter() {
    setState(() {
      _text = "Wowzers";
      precedenceGraph = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Wrap(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      TextField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Desired pokemon search string",
                        ),
                        onSubmitted: _textSubmitted,
                      ),
                      const Text(
                        'Copy this to Pokemon Go:',
                      ),
                      Text(
                        _text,
                        style: Theme.of(context).textTheme.headline4,
                      ),
                    ],
                ),
              ],
            ),
            Expanded(
              child: InteractiveViewer(
                  constrained: false,
                  boundaryMargin: EdgeInsets.all(100),
                  minScale: 0.01,
                  maxScale: 5.6,
                  child: GraphView(
                    graph: graph,
                    algorithm: BuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder)),
                    paint: Paint()
                      ..color = Colors.green
                      ..strokeWidth = 1
                      ..style = PaintingStyle.stroke,
                    builder: (Node node) {
                      // I can decide what widget should be shown here based on the id
                      return rectangleWidget(nodeNames[node]??"EMPTY");
                    },
                  )),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Clear',
        child: const Icon(Icons.add),
      ),
    );
  }

  Graph graph = Graph()..isTree = true;
  BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();

  Widget rectangleWidget(String text) {
    return InkWell(
      onTap: () {
        print('This is a node');
      },
      child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [
              BoxShadow(color: Colors.blue, spreadRadius: 1),
            ],
          ),
          child: Text(text)
      ),
    );
  }

  void _textSubmitted(String value) {
    setState(() {
      precedenceGraph = PrecedenceGraph.fromString(value);
      _text = precedenceGraph?.buildString()??":3";

      var newGraph = precedenceGraph?.toGraph();
      if (newGraph == null || graph.nodes.isEmpty){
        newGraph = Graph()..isTree = true;
        newGraph.nodes.add(Node.Id(134));
      }
      graph = newGraph;
    });
  }

  @override
  void initState() {
    super.initState();
    graph = Graph()..isTree = true;
    graph.addNode(Node.Id(134));
    nodeNames[Node.Id(134)]="Made by Lebeg134";

    builder
      ..siblingSeparation = (100)
      ..levelSeparation = (150)
      ..subtreeSeparation = (150)
      ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM);
  }
}
