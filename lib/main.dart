import 'package:flutter/material.dart';

import 'html_render.dart';
import 'content_loder.dart';


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
            onRefresh: _refreshProblems,
          ) 
        ),
      ),
    );
  }
  @override
  void initState() {
    _loadProblems();
  }

  Future<void> _loadProblems({refresh = false}) async {
    loadContent('problemList', refresh)
    .then((data) {
      setState(() {
        _problems = data['stat_status_pairs'];
        print('Data loaded from local cache');
      });
    });
  }

  Future<void> _refreshProblems() async {
    _loadProblems(refresh: true);
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
    _loadProblemDetail();
  } 

  Future<void> _loadProblemDetail({refresh = false}) async {
    loadContent(this.problemDetails['titleSlug'], refresh)
    .then((content) {
      var problemDetail = content['data']['question'];
      setState(() {
        this._problemDesc = problemDetail['content'];
      });
    });
  }

  Future<void> _refreshProblem() async {
    _loadProblemDetail(refresh: true);
  }

  Widget _buildProblemPage() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: htmlParse(this._problemDesc ?? '')
    );
  }
}