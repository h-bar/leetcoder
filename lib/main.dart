import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;

import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LeetCoder',
      theme: new ThemeData(
        primaryColor: Colors.white,
      ),
      home: ProblemList(),
    );
  }
}


class ProblemList extends StatefulWidget {
  @override
  ProblemListState createState() => new ProblemListState();
}

class ProblemListState extends State<ProblemList> {
  List<dynamic> _problems = new List<dynamic>();
  final _biggerFont = const TextStyle(fontSize: 18.0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Problem List'), 
      ),
      body: Container(
        child: Center(
          child: RefreshIndicator(
            child: _buildProblemList(),
            onRefresh: _loadProblems,
          ) 
        ),
      ),
    );
  }
  @override
  void initState() {
    _loadProblems();
  }

  Future<void> _loadProblems() async { //TODO: Cache problem list and descriptions
    var url = "https://leetcode.com/api/problems/all";
    http.get(url)
    .then((response) {
      Map<String, dynamic> responseBody = jsonDecode(response.body);
      setState(() {
        _problems = responseBody['stat_status_pairs'];
        print('Problem list Refreshed');
      });
    });
  }

  Widget _buildProblemList() {
    return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemBuilder: (context, idx) {
          return idx < _problems.length ? _buildRow(_problems[idx]) : null;
        },
      );
  }

  Widget _buildRow(Map<String, dynamic> problemDetail) {
    List<String> _difficultyLevel = ['Easy', 'Medium', 'Hard'];
    final Map<String, dynamic> _stat = problemDetail['stat'];
    final int _id = _stat['frontend_question_id'];
    final String _titleSlug = _stat['question__title_slug'];
    final String _displayTitle = _stat['question__title'];
    final int _diffculty = problemDetail['difficulty']['level'];
    
    return ListTile(
      title: Text(
        '$_id. $_displayTitle',
        style: _biggerFont,
      ),
      subtitle: Text(_difficultyLevel[_diffculty-1]),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProblemPage(problemSlug: _titleSlug)),
        );
      },
    );
  }
}

class ProblemPage extends StatefulWidget {
  final String problemSlug;
  ProblemPage({Key key, @required this.problemSlug}) : super(key: key);
  @override
  ProblemPageState createState() => new ProblemPageState(problemSlug: this.problemSlug);
}

class ProblemPageState extends State<ProblemPage> {
  final String problemSlug;
  String _problemDesc;
  ProblemPageState({@required this.problemSlug});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(this.problemSlug), //TODO: change to problem title 
      ),
      body: Container(
        child: Center(
          child: RefreshIndicator(
            child: _buildProblemPage(),
            onRefresh: _refreshProblem,
          ) 
        ),
      ),
    );
  }

  @override
  void initState() {
    _refreshProblem();
  } 

  Future<void> _refreshProblem() async {
    var url = "https://leetcode.com/graphql";
    var headers = {"Content-Type": "application/json"};
    var body = jsonEncode({
      "operationName": "questionData",
      "variables": {
        "titleSlug": "${this.problemSlug}"
      },
      "query": '''query questionData(\$titleSlug: String!) {
                          question(titleSlug: \$titleSlug) {
                            questionId
                            questionFrontendId
                            boundTopicId
                            title
                            titleSlug
                            content
                            translatedTitle
                            translatedContent
                            isPaidOnly
                            difficulty
                            likes
                            dislikes
                            isLiked
                            similarQuestions
                            contributors {
                              username
                              profileUrl
                              avatarUrl
                              __typename
                            }
                            langToValidPlayground
                            topicTags {
                              name
                              slug
                              translatedName
                              __typename
                            }
                            companyTagStats
                            codeSnippets {
                              lang
                              langSlug
                              code
                              __typename
                            }
                            stats
                            hints
                            solution {
                              id
                              canSeeDetail
                              __typename
                            }
                            status
                            sampleTestCase
                            metaData
                            judgerAvailable
                            judgeType
                            mysqlSchemas
                            enableRunCode
                            enableTestMode
                            envInfo
                            __typename
                          }
                        }'''
    });
    http.post(url, body: body, headers: headers)
    .then((response) {
      Map<String, dynamic> responseBody = jsonDecode(response.body);
      var problemDetail = responseBody['data']['question'];
      print('Problem details fetched');
      setState(() {
        this._problemDesc = problemDetail['content'];
      });
    });
  }

  Widget _buildProblemPage() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: htmlParse(this._problemDesc ?? '')
    );
  }
}


Widget htmlParse(String data) {
    data = data.replaceAll('\r\n\r\n', '');
    dom.Document document = parser.parse(data);
    Widget widgeList = _parseNode(document.body);
    return widgeList;
}

final Map<String, TextStyle> textStyleSheet = {
    "strong": const TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
    ),
    "em": const TextStyle(
      color: Colors.black,
      fontStyle: FontStyle.italic,
    ),
    "i": const TextStyle(
      color: Colors.black,
      fontStyle: FontStyle.italic,
    ),
    "font": const TextStyle(
      color: Colors.black,
      fontFamily: 'monospace',
    ),
    "b": const TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
    ),
    "code": TextStyle(
      fontFamily: 'monospace',
      color: Colors.blueGrey,
      background: Paint()..color = Colors.grey[100],
    ),
    "span": TextStyle(
      fontFamily: 'monospace',
      color: Colors.blueGrey,
    ),
    "a": const TextStyle(
      decoration: TextDecoration.underline,
      color: Colors.blueAccent,
      decorationColor: Colors.blueAccent
    )
  };


bool _isInlineText(dom.Node node) {
  return (node is dom.Text) || (node is dom.Element && textStyleSheet.keys.contains(node.localName));
}


TextSpan _parseInLineNode(dom.Node node) {
  if (node is dom.Text) {
    return TextSpan(text: node.text);
  }
  
  dom.Element nodeE = node as dom.Element;
  List<TextSpan> textSpan = List<TextSpan>();
  for (dom.Node nextNode in node.nodes) {
    textSpan.add(_parseInLineNode(nextNode));
  }
  return TextSpan(
    children: textSpan,
    style: textStyleSheet[nodeE.localName],
  );
}

Widget _parseNode(dom.Node node) {
  if (!(node is dom.Element)) {
    return null;
  }

  dom.Element nodeE = node as dom.Element;
  dom.NodeList children = nodeE.nodes;
  String nodeTag = nodeE.localName;

  if (nodeTag == 'img') {
    return Image.network(
      node.attributes['src'] 
    );
  }

  if (children.isEmpty) {
    return null;
  }

  List<Widget> childWidgets = List<Widget>();
  for (dom.Node nextNode in nodeE.nodes) {
    if (_isInlineText(nextNode)) {
      List<TextSpan> textSpans = List<TextSpan>();
      if (childWidgets.isNotEmpty && childWidgets.last is RichText) {
        textSpans.addAll((childWidgets.removeLast() as RichText).text.children);
      }
      textSpans.add(_parseInLineNode(nextNode));
      childWidgets.add(RichText(
        text: TextSpan(
          children: textSpans, 
          style: TextStyle(color: Colors.black)
          ),
        textAlign: TextAlign.left,
      ));
    }
    else {
      Widget nextNodeWidget = _parseNode(nextNode);
      if (nextNodeWidget != null) {
        childWidgets.add(nextNodeWidget);
      }
    }
  }

  return Column(
    children: childWidgets,
    crossAxisAlignment: CrossAxisAlignment.start,
    );
}