import 'package:flutter/material.dart';

import 'html_render.dart';
import 'data_provider.dart';


void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LeetCoder',
      theme: new ThemeData(
        primaryColor: Colors.black,
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
  List<ProblemSummary> _problems;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Problems'), 
      ),
      body: Container(
        child: Center(
          child: RefreshIndicator(
            child: _problemList(),
            onRefresh: _refresh,
          ) 
        ),
      ),
    );
  }
  @override
  void initState() {
    SummaryLoader.load()
    .then((problems) => this._problems =problems);
  }

  Future<void> _refresh() {
    return SummaryLoader.load(refresh: true)
    .then((problems) => this._problems =problems);
  }

  Widget _problemList() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: _summaryRows(this._problems),
    );
  }

  List<ListTile> _summaryRows(List<ProblemSummary> problems) {
    List<ListTile> summaryList = List<ListTile>();
    for (ProblemSummary summary in problems) {
      summaryList.add(ListTile(
        title: Text('${summary.id}. ${summary.title}'),
        subtitle: Text(summary.difficultyLevel),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProblemPage(
                problemDetails:  Problem.fromSummary(summary)
              )),
          );
        },
      ));
    }
    return summaryList;
  }
}

class ProblemPage extends StatefulWidget {
  final Problem problemDetails;
  ProblemPage({Key key, @required this.problemDetails}) : super(key: key);
  @override
  ProblemPageState createState() => new ProblemPageState(problemDetails: this.problemDetails);
}
class ProblemPageState extends State<ProblemPage> {
  final Problem problemDetails;
  ProblemPageState({@required this.problemDetails});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(this.problemDetails.summary.title),
      ),
      body: Container(
        child: Center(
          child: RefreshIndicator(
            child: _detailePage(),
            onRefresh: _refreshProblem,
          ) 
        ),
      ),
    );
  }

  @override
  void initState() {
    problemDetails.loaded
    .then((_) {
      setState(() {});
    });
  }

  Future<void> _refreshProblem() {
    return problemDetails.loadDetail(refresh: true)
    .then((_) {
      setState(() {});
    });
  }

  Widget _detailePage() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: <Widget>[
          htmlParse(this.problemDetails.description ?? '<p>Loading...<p/>'), 
          htmlParse(this.problemDetails.solution ?? '**No Solution Available**') 
        ],
      )
    );
  }
}