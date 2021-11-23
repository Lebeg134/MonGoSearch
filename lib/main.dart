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
        primarySwatch: Colors.orange,
        highlightColor: Colors.lightGreen,
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
  final myController = TextEditingController();

  void _clear() {
    setState(() {
      _text = r"¯\_(ツ)_/¯";
      precedenceGraph = null;
      graph = Graph()..isTree = true;
      graph.nodes.add(Node.Id(-204));
      DebugData.setDebugLevel(0);
      tapTimes = 0;
    });
  }

  void _textSubmitted(String value) {
    setState(() {
      precedenceGraph = PrecedenceGraph.fromString(value);
      _text = precedenceGraph?.buildString()??"Error";
      graph = precedenceGraph!.toGraph();
    });
  }

  void _onPressed() {
    _textSubmitted(myController.text);
  }

  /// 12 turns on Debug mode
  int tapTimes = 0;
  void _nodeTapped() {
    tapTimes++;
    if (tapTimes > 8){
      if (tapTimes >= 12){
        final SnackBar debug = SnackBar(
          content: const Text("Debug mode activated! Press clear to turn off"),
          action: SnackBarAction(
            label: "Turn off",
            onPressed: (){
              setState(() {
                DebugData.setDebugLevel(0);
                tapTimes = 0;
              });
            },
          ),
        );
        setState(() {
          DebugData.setDebugLevel(2);
          _onPressed();
        });
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(debug);
      }
      else{
        final SnackBar message = SnackBar(
          content: Text("Debug in: ${12-tapTimes}"),
          //duration: const Duration(milliseconds: 250),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(message);
      }
    }
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
                      Text(
                        "You can use brackets! () :D",
                        style: Theme.of(context).textTheme.headline4,
                      ),
                      Container(
                        height: 69,
                        constraints: const BoxConstraints(maxWidth: 750),
                        child:
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                Flexible(
                                  flex: 4,
                                  child:
                                  TextField(
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: "Desired pokemon search string",
                                    ),
                                    onSubmitted: _textSubmitted,
                                    controller: myController,
                                  ),
                                ),
                                Flexible(
                                  flex: 1,
                                  child:
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(58),
                                    ),
                                    onPressed: _onPressed,
                                    child: const Text(
                                      "Convert!",
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
            const Divider(),
            Expanded(
              child: InteractiveViewer(
                  constrained: false,
                  boundaryMargin: const EdgeInsets.all(100),
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
                      return rectangleWidget(nodeNames[node]??"Error");
                    },
                  )),
            ),

          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _clear,
        tooltip: 'Clear',
        child: const Icon(Icons.delete),
      ),
    );
  }

  Graph graph = Graph()..isTree = true;
  BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();

  Widget rectangleWidget(String text) {
    return InkWell(
      onTap: _nodeTapped,
      child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [
              BoxShadow(color: Colors.orange, spreadRadius: 1),
            ],
          ),
          child: Text(text)
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    graph = Graph()..isTree = true;
    graph.addNode(Node.Id(-201));


    builder
      ..siblingSeparation = (100)
      ..levelSeparation = (150)
      ..subtreeSeparation = (150)
      ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM);

  }
}
