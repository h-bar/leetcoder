import 'package:flutter/material.dart';

import 'html_render.dart';
import 'data_provider.dart';

ContentLoader cL = ContentLoader();

void main() {
  cL.inited.then((_) => runApp(LeetCoder()));
}

class LeetCoder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LeetCoder',
      theme: ThemeData(
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
  List<ProblemSummary> _filteredProblems;
  Widget _appBartitle;
  List<Widget> _appBarActions;
  
  @override
  void initState() {
    super.initState();
    _showTitleBar();
    _loadList(refresh: false);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: this._appBartitle, 
        actions: this._appBarActions,
      ),
      body: Container(
        child: Center(
          child: RefreshIndicator(
            child: Scrollbar(child: _problemList(this._filteredProblems),),
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
        this._problems = problems;
        this._problems.sort((a, b) => b.qId - a.qId);
        this._filteredProblems = this._problems;
      });
    }); 
  }

  Future<void> _refreshList() {
    return _loadList(refresh: true);
  }

  void _showTitleBar() {
    setState(() {
      this._appBartitle = Text('ProblemList');
      this._appBarActions = [
        IconButton(
              icon: Icon(Icons.search),
              onPressed: _showSearchBar,
              ),
        ];
    });
  }

  void _showSearchBar() {
    setState(() {
      this._appBartitle = TextField(
        autofocus: true,
        autocorrect: true,
        onChanged: this._search,
        style: TextStyle(color: Colors.white),
      );
      this._appBarActions = [
        IconButton(
          icon: Icon(Icons.close),
          onPressed: _showTitleBar,
          )
      ];
    });
  }

  void _search(String text) {
    setState(() {
      if (text.isNotEmpty) {
        String filterText = text.toLowerCase();
        this._filteredProblems = this._problems.where((p) => 
          (p.qId.toString().toLowerCase().contains(filterText)) || 
          (p.title.toLowerCase().contains(filterText))
        ).toList();
      }
    });
  }
  Widget _problemList(List<ProblemSummary> problems) {
    return ListView.builder(
      physics: BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      itemCount: problems == null ? 0 : problems.length,
      itemBuilder: (BuildContext context, int index) => _summaryRow(problems[index]),
    );
  }

  ListTile _summaryRow(ProblemSummary summary) {
    return ListTile(
      title: Text('${summary.qId}. ${summary.title}'),
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
    );
  }

}

class ProblemPage extends StatefulWidget {
  final ProblemSummary summary;
  ProblemPage({Key key, @required this.summary}) : super(key: key);
  @override
  ProblemPageState createState() => new ProblemPageState(summary: this.summary);
}
class ProblemPageState extends State<ProblemPage> with SingleTickerProviderStateMixin {
  final ProblemSummary summary;
  Problem problem;
  HtmlRenderer _renderer = HtmlRenderer();
  TabController _tabController;
  ProblemPageState({@required this.summary});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(this.summary.title),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          Container(
          child: RefreshIndicator(
            child: _detailePage(),
            onRefresh: _refreshProblem,
          ),),
          Container(
          child: RefreshIndicator(
            child: _solutionPage(),
            onRefresh: _refreshProblem,
          ) 
        )]
      ),
      bottomNavigationBar: TabBar(
        controller: _tabController,
        tabs: <Widget>[
          Tab(text: 'Description',),
          Tab(text: 'Solution',)
        ],
        labelColor: Colors.black,
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
    super.initState();
    _tabController = TabController(vsync: this, length: 2);
    _loadProblem();
  }

  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  Future<void> _refreshProblem() {
    return _loadProblem(refresh: true);
  }

  Widget _detailePage() {
    _renderer.htmlData = this.problem != null ? this.problem.description : '<p>Loading...<p/>';
    _renderer.htmlContext = this.problem != null ?  this.problem.descContext : null;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      physics: const AlwaysScrollableScrollPhysics(),
      child: _renderer.parse(),
    );
  }

  Widget _solutionPage() {
    _renderer.htmlData = this.problem != null ? this.problem.solution : '<p>Loading...<p/>';
    _renderer.htmlContext = this.problem != null ?  this.problem.solutionContext : null;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      physics: const AlwaysScrollableScrollPhysics(),
      child: _renderer.parse(),
    );
  }
}