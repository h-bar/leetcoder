import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'flutter_html.dart';

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

  Future<void> _loadProblems() async {
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
        title: Text('Problem Detail'), //TODO: change to problem title 
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

  Widget _buildProblemPage() { //TODO: Extend the html_parser lib to convert discription into somthing like Leetcode website
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Html(
        data: this._problemDesc ?? """
          <!--For a much more extensive example, look at example/main.dart-->
          <div>
            <h1>Demo Page</h1>
            <p>This is a fantastic nonexistent product that you should buy!</p>
            <h2>Pricing</h2>
            <p>Lorem ipsum <b>dolor</b> sit amet.</p>
            <h2>The Team</h2>
            <p>There isn't <i>really</i> a team...</p>
            <h2>Installation</h2>
            <p>You <u>cannot</u> install a nonexistent product!</p>
            <!--You can pretty much put any html in here!-->
          </div>
        """,
      )
    );
  }
}