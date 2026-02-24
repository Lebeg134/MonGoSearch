import 'package:flutter/material.dart';
import 'package:mon_go_search/creative_search/precedence_graph.dart';
import 'package:mon_go_search/creative_search/search_string_helper.dart';
import 'package:graphview/GraphView.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });
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
  String _text = "";
  String _invertedText = "";
  bool debugMode = false;
  PrecedenceGraph? precedenceGraph;
  final myController = TextEditingController();

  void _clear() {
    _turnOffDebugMode();
    setState(() {
      _text = r"¯\_(ツ)_/¯";
      precedenceGraph = null;
      _invertedText = r"¯\_(ツ)_/¯";
      graph = Graph()..isTree = true;
      graph.nodes.add(Node.Id(-204));
      myController.clear();
    });
  }

  void _turnOnDebugMode() {
    setState(() {
      debugMode = true;
      DebugData.setDebugLevel(2);
    });
    _onPressed();
  }

  void _turnOffDebugMode() {
    setState(() {
      debugMode = false;
      tapTimes = 0;
      DebugData.setDebugLevel(0);
    });
    _onPressed();
  }

  void _textSubmitted(String value) {
    // First strip inline comments (space + #) then remove all whitespace
    final withoutComments = SearchStringHelper.stripComments(value);
    final sanitized = withoutComments.replaceAll(RegExp(r'\s+'), '');
    try {
      final pg = PrecedenceGraph.fromString(sanitized);
      setState(() {
        precedenceGraph = pg;
        _text = precedenceGraph?.buildString() ?? "Error";
        _invertedText = precedenceGraph?.buildInvertedString() ?? "";
        graph = precedenceGraph!.toGraph();
      });
        debugPrint('Converted: main="$_text" inverted="$_invertedText" debug=${DebugData.getDebugLevel()}');
    } catch (e) {
      setState(() {
        _text = "Error";
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Parse error: $e')));
    }
  }

  void _onPressed() {
    _textSubmitted(myController.text);
  }

  /// 12 turns on Debug mode
  int tapTimes = 0;
  void _nodeTapped() {
    tapTimes++;
    if (tapTimes > 8) {
      if (tapTimes >= 12) {
        final SnackBar debug = SnackBar(
          content: const Text("Debug mode activated!"),
          action: SnackBarAction(
            label: "Turn off",
            onPressed: _turnOffDebugMode,
          ),
        );
        _turnOnDebugMode();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(debug);
      } else {
        final SnackBar message = SnackBar(
          content: Text("Debug in: ${12 - tapTimes}"),
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
                      "You can use brackets () and add comments with #",
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 750),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Flexible(
                            flex: 4,
                            child: TextField(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: "Desired pokemon search string",
                              ),
                              keyboardType: TextInputType.multiline,
                              minLines: 3,
                              maxLines: null,
                              onSubmitted: _textSubmitted,
                              controller: myController,
                            ),
                          ),
                          Flexible(
                            flex: 1,
                            child: ElevatedButton(
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
                    if (_text.isNotEmpty &&
                        DebugData.getDebugLevel() <= 1 &&
                        _text != r"¯\\_(ツ)_/¯")
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Copy this to Pokemon Go:',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Flexible(
                              child: Text(
                                _text,
                                style: Theme.of(context).textTheme.headlineMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 36,
                              child: ElevatedButton(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: _text));
                                  ScaffoldMessenger.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(SnackBar(
                                      content: Text("Copied \""
                                          "${_text.characters.take(10)}"
                                          "${_text.length > 10 ? "..." : ""}"
                                          "\" to clipboard!"),
                                    ));
                                },
                                child: const Text("Copy"),
                              ),
                            ),
                          ])
                        ],
                      ),
                    const SizedBox(height: 6),
                      if (_invertedText.isNotEmpty &&
                          DebugData.getDebugLevel() <= 1 &&
                          _invertedText != r"¯\\_(ツ)_/¯")
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              "'Trash' (inverted) search string:",
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Flexible(
                                child: Text(
                                  _invertedText,
                                  style: Theme.of(context).textTheme.headlineSmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.left,
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 36,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Clipboard.setData(
                                        ClipboardData(text: _invertedText));
                                    ScaffoldMessenger.of(context)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(SnackBar(
                                        content: Text("Copied \""
                                            "${_invertedText.characters.take(10)}"
                                            "${_invertedText.length > 10 ? "..." : ""}"
                                            "\" to clipboard!"),
                                      ));
                                  },
                                  child: const Text("Copy"),
                                ),
                              ),
                            ])
                          ],
                        ),
                    if (debugMode) const Divider(),
                    if (debugMode)
                      Container(
                          height: 32,
                          constraints: const BoxConstraints(maxWidth: 350),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                const Flexible(
                                    flex: 2,
                                    child: Text(
                                      "debugLevel",
                                      textAlign: TextAlign.center,
                                    )),
                                Flexible(
                                  flex: 1,
                                  child: DropdownButton<int>(
                                    value: DebugData.getDebugLevel(),
                                    icon: const Icon(Icons.arrow_downward),
                                    iconSize: 32,
                                    onChanged: (int? newValue) {
                                      setState(() {
                                        DebugData.setDebugLevel(newValue ?? 2);
                                        _onPressed();
                                      });
                                    },
                                    items: <int>[
                                      1,
                                      2,
                                      3
                                    ].map<DropdownMenuItem<int>>((int level) {
                                      return DropdownMenuItem<int>(
                                          value: level, child: Text("$level"));
                                    }).toList(),
                                  ),
                                ),
                                Flexible(
                                    flex: 4,
                                    child: SizedBox.expand(
                                      child: ElevatedButton(
                                          onPressed: _turnOffDebugMode,
                                          child: const Text(
                                              "Turn off debug mode")),
                                    )),
                              ])),
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
                    algorithm: BuchheimWalkerAlgorithm(
                        builder, TreeEdgeRenderer(builder)),
                    paint: Paint()
                      ..color = Colors.green
                      ..strokeWidth = 1
                      ..style = PaintingStyle.stroke,
                    builder: (Node node) {
                      return rectangleWidget(node, nodeNames[node] ?? "Error");
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

  Widget rectangleWidget(Node node, String text) {
    final id = node.key?.value ?? 0;
    if (id == -201) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(color: Colors.orange, spreadRadius: 1),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          ElevatedButton(
            onPressed: () async {
              _nodeTapped();
              try {
                final uri = Uri.parse('https://github.com/Lebeg134/MonGoSearch');
                await launchUrl(uri);
              } catch (_) {}
            },
            child: const Text('Made by'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              _nodeTapped();
              try {
                final uri = Uri.parse('https://github.com/Jeshii/MonGoSearch');
                await launchUrl(uri);
              } catch (_) {}
            },
            child: const Text('Forked by Jeshii'),
          ),
        ]),
      );
    }

    return InkWell(
      onTap: () async {
        _nodeTapped();
        try {
          if (id == -201) {
            final uri = Uri.parse('https://github.com/Lebeg134/MonGoSearch');
            await launchUrl(uri);
          }
        } catch (_) {}
      },
      child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [
              BoxShadow(color: Colors.orange, spreadRadius: 1),
            ],
          ),
          child: Text(text)),
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
