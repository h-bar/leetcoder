import 'package:flutter/material.dart';

import 'html_render.dart';
import 'data_provider.dart';

ContentLoader cL = ContentLoader();

void main() {
  cL.inited
  .then((_) => runApp(MyApp()));
}

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
            onRefresh: _refreshList,
          ) 
        ),
      ),
    );
  }

  Future<void> _loadList({refresh = false}) {
    return cL.loadProblemList(refresh: refresh)
    .then((problems) {
      return setState(() {
        this._problems =problems;  
      });
    });
  }

  @override
  void initState() {
    _loadList(refresh: false);
  }

  Future<void> _refreshList() {
    return _loadList(refresh: true);
  }

  Widget _problemList() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: _summaryRows(this._problems),
    );
  }

  List<ListTile> _summaryRows(List<ProblemSummary> problems) {
    List<ListTile> summaryList = List<ListTile>();
    if (problems == null) {
      print('dsdfs');
      summaryList.add(ListTile(
        title: Text('Loading'),
      ));
      return summaryList;
    }
    for (ProblemSummary summary in problems) {
      summaryList.add(ListTile(
        title: Text('${summary.id}. ${summary.title}'),
        subtitle: Text(summary.difficultyLevel),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProblemPage(
                summary:  summary
              )),
          );
        },
      ));
    }
    return summaryList;
  }
}

class ProblemPage extends StatefulWidget {
  final ProblemSummary summary;
  ProblemPage({Key key, @required this.summary}) : super(key: key);
  @override
  ProblemPageState createState() => new ProblemPageState(summary: this.summary);
}
class ProblemPageState extends State<ProblemPage> {
  final ProblemSummary summary;
  Problem problem;
  ProblemPageState({@required this.summary});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(this.summary.title),
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

  Future<void> _loadProblem({refresh = false}) {
    return cL.loadProblem(summary, refresh: refresh)
    .then((problem) {
      return setState(() {
        this.problem = problem;
      });
    });
  }

  @override
  void initState() {
    _loadProblem();
  }

  Future<void> _refreshProblem() {
    return _loadProblem(refresh: true);
  }

  Widget _detailePage() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: <Widget>[
          htmlParse(this.problem != null ? this.problem.description : '<p>Loading...<p/>'), 
          htmlParse(this.problem != null ? this.problem.solution : '**No Solution Available**') 
        ],
      )
    );
  }
}