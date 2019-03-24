import 'dart:convert' as converter;
import 'dart:io' as io;
import 'package:http/http.dart' as http;
import 'package:markdown/markdown.dart' as markdown;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

Future<String> _fetchContent(http.Request request) {
  return request.send()
  .then((resp) {
    return resp.stream.toStringStream().join();
  });
}

Future<String> _loadContent(io.File file) {
  return file.readAsString().asStream().join();
}

Future<void> _cacheContent(io.File file, String content) {
  return file.writeAsString(content);
}

Future<Map<String, dynamic>> _load(String cacheFileName, http.Request request, refresh) async {
  // io.Directory _appDocDir = io.Directory('');
  io.Directory appDocDir =  await getApplicationDocumentsDirectory();
  String appDocPath =appDocDir.absolute.path;
  io.File cacheFile = io.File(path.join(appDocPath + cacheFileName));
  cacheFile.createSync(recursive: true);

  if (refresh) {
    return _fetchContent(request)
    .then((content){
      _cacheContent(cacheFile, content);
      return converter.jsonDecode(content);
    });
  }
  return _loadContent(cacheFile)
  .then((content) async {
    if (content.isEmpty) {
      content = await _fetchContent(request);
      _cacheContent(cacheFile, content);
    }
    return converter.jsonDecode(content);
  });
}


class SummaryLoader {
  static Uri get _url => Uri.parse('https://leetcode.com/api/problems/all');
  static http.Request get _request => http.Request('GET', _url);
  static String _cacheFileName = 'problemList.json';

  static Future<List<ProblemSummary>> load({refresh = false}) {
    List<ProblemSummary> problemList = List<ProblemSummary>();
    return _load(_cacheFileName, _request, refresh)
    .then((content){
      List<dynamic> problemJsonList=content['stat_status_pairs'];
      for ( Map<String, dynamic> problemJson in problemJsonList) {
        problemList.add(ProblemSummary.fromMap((problemJson)));
      }
      return problemList;
    });
  }
}
class DetailLoader {
  static Map<String, dynamic> _graphqlTemplate = {
    'method': 'POST',
    'endpoint': Uri.parse('https://leetcode.com/graphql'),
    'headers': {'Content-Type': 'application/json'},
    'body': {
      'operationName': 'questionData',
      'variables': {
        'titleSlug': ''
      },
      'query': '''query questionData(\$titleSlug: String!) {
                    question(titleSlug: \$titleSlug) {
                      content
                      solution {
                        content
                      }
                    }
                  }'''
    }
  };
  static http.Request _generateRequest(String titleSlug) {
    Map<String, dynamic> graphql =_graphqlTemplate;
    graphql['body']['variables']['titleSlug'] =titleSlug;
    http.Request request = http.Request(graphql['method'], graphql['endpoint']);
    request.headers.addAll(graphql['headers']);
    request.body = converter.jsonEncode(graphql['body']);
    return request;
  }
  
  static String _cacheDirName = 'problems';
  static String _cacheFilePath(String titleSlug) => path.join(_cacheDirName, titleSlug + '.json');
  
  static String _extractDescription(Map<String, dynamic> content) {
    return content['content'];
  }
  static String _extractSolution(Map<String, dynamic> content) {
    String solutionMarkdown = content['solution'] != null ? content['solution']['content'] : 'No Solution Avaliable';
    solutionMarkdown = solutionMarkdown.replaceAll('[TOC]', '');
    return markdown.markdownToHtml(solutionMarkdown);
  }

  static Future<Map<String, String>> load(String titleSlug, refresh) {
    return _load(_cacheFilePath(titleSlug), _generateRequest(titleSlug), refresh)
    .then((content){
      content = content['data']['question'];
      return {
        'desc': _extractDescription(content),
        'solution': _extractSolution(content)
      };
    });
  }
}

class ProblemSummary {
  final List<String> _difficultyLevels = ['Easy', 'Medium', 'Hard'];
  
  int id;
  String title;
  String titleSlug;
  String difficultyLevel;
  bool paidOnly;

  ProblemSummary.fromMap(Map<String, dynamic> statStatusPair) {
    this.id=statStatusPair['stat']['question_id'];
    this.title=statStatusPair['stat']['question__title'];
    this.titleSlug=statStatusPair['stat']['question__title_slug'];
    this.difficultyLevel=_difficultyLevels[statStatusPair['difficulty']['level']-1];
    this.paidOnly=statStatusPair['paid_only'];
  }
}
class Problem {
    final Uri _context = Uri.parse('https://leetcode.com/problems/');
    
    String description;
    String solution;
    ProblemSummary summary;
    Future<void> loaded;

    Uri get contextEndpoint => _context.resolve(this.summary.titleSlug+'/');
    Uri get descContext => _context.resolve(this.summary.titleSlug+'/').resolve('');
    Uri get solutionContext => _context.resolve(this.summary.titleSlug+'/').resolve('solution/');
    
    Problem.fromSummary(ProblemSummary summary) {
      this.summary = summary;
      this.loaded = this.loadDetail();
    }

    Future<void> loadDetail({refresh=false}) {
      return DetailLoader.load(this.summary.titleSlug, refresh)
      .then((content) {
        this.description = content['desc'];
        this.solution = content['solution'];
      });
    }

    Future<void> refreshDetail() {
      return loadDetail(refresh: true);
    }

    String toString() {
      return summary.id.toString() + '.' + summary.title + ' -> ' + descContext.toString();
    }
}



main(List<String> args) {
  SummaryLoader.load()
  .then((problemList) {
    var p = Problem.fromSummary(problemList[212]);
    p.loaded
    .then((_) => print(p.description));
  });
}