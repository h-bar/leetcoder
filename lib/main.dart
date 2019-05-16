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
  AppBar _appBar;
  AppBar _titleBar;
  AppBar _searchBar;
  Function _popAction;

  @override
  void initState() {
    super.initState();
    this._initAppBar();
    this._showTitleBar();
    this._loadList(refresh: false);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: this._appBar,
      body: Container(
        child: WillPopScope(
          onWillPop: this._popAction,
          child: Center(
            child: RefreshIndicator(
              child: Scrollbar(child: _problemList(this._filteredProblems),),
              onRefresh: _refreshList,
            ) 
          )
        )
      ),
    );
  }

  void _initAppBar() {
    this._titleBar = AppBar(
      title: Text('ProblemList'),
      actions: [IconButton(
        icon: Icon(Icons.search),
        onPressed: _showSearchBar,
    )],);
    this._searchBar = AppBar(
      title: TextField(
        autofocus: true,
        autocorrect: true,
        onChanged: this._search,
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.close),
          onPressed: _showTitleBar,
    )],);
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
      this._appBar = this._titleBar;
      _search('');
      this._popAction = null;
    });
  }

  void _showSearchBar() {
    setState(() {
      this._appBar = this._searchBar;
      this._popAction = () {
        this._showTitleBar();
      };
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
      } else {
        this._filteredProblems = this._problems;
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