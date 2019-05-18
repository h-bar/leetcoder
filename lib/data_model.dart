import 'dart:convert' as converter;

import 'package:markdown/markdown.dart' as markdown;
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

import 'content_loader.dart';

class SummaryLoader extends ContentLoader{
  static get _uri => Uri.parse('https://leetcode.com/api/problems/all');
  http.Request get request => http.Request('GET', SummaryLoader._uri);
  String get cacheFileName => 'problemList.json';
  List<ProblemSummary> processContent(List<int> contentBytes) {
    String content = String.fromCharCodes(contentBytes);
    Map<String, dynamic> contentJSON = converter.jsonDecode(content);
    List<ProblemSummary> problemList = List<ProblemSummary>();
    List<dynamic> problemJsonList = contentJSON['stat_status_pairs'];
    for ( Map<String, dynamic> problemJson in problemJsonList) {
      problemList.add(ProblemSummary.fromMap((problemJson)));
    }
    return problemList;
  }
}

class ProblemLoader extends ContentLoader{
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
                      isPaidOnly
                      solution {
                        content
                      }
                    }
                  }'''
    }
  };
  ProblemSummary summary;
  http.Request get request {
    Map<String, dynamic> graphql =_graphqlTemplate;
    graphql['body']['variables']['titleSlug'] = this.summary.titleSlug;
    http.Request request = http.Request(graphql['method'], graphql['endpoint']);
    request.headers.addAll(graphql['headers']);
    request.body = converter.jsonEncode(graphql['body']);
    return request;
  }
  String get cacheFileName => path.join('problems', this.summary.titleSlug + '.json');
  Problem processContent(List<int> contentBytes) {
    String content = String.fromCharCodes(contentBytes);
    Map<String, dynamic> contentJSON = converter.jsonDecode(content);
    Map<String, dynamic> question = contentJSON['data']['question'];
    Problem p =Problem.fromSummary(summary);
    p.description = summary.paidOnly ? '<p> Paid only content <p>' : this._extractDescription(question);
    p.solution =this._extractSolution(question);
    return p;
  }
  
  ProblemLoader(ProblemSummary summary) {
    this.summary = summary;
  }

  String _extractDescription(Map<String, dynamic> content) {
    return content['content'];
  }
  String _extractSolution(Map<String, dynamic> content) {
    String solutionMarkdown = content['solution'] != null ? content['solution']['content'] : 'No Solution Avaliable';
    solutionMarkdown = solutionMarkdown ?? 'No Solution Avaliable';
    solutionMarkdown = solutionMarkdown.replaceAll('[TOC]', '');
    return markdown.markdownToHtml(solutionMarkdown);
  }
}

class ProblemSummary {
  final List<String> _difficultyLevels = ['Easy', 'Medium', 'Hard'];
  
  int id;
  int qId;
  String title;
  String titleSlug;
  String difficultyLevel;
  bool paidOnly;

  ProblemSummary.fromMap(Map<String, dynamic> statStatusPair) {
    this.id=statStatusPair['stat']['question_id'];
    this.qId=statStatusPair['stat']['frontend_question_id'];
    this.title=statStatusPair['stat']['question__title'];
    this.titleSlug=statStatusPair['stat']['question__title_slug'];
    this.difficultyLevel=_difficultyLevels[statStatusPair['difficulty']['level']-1];
    this.paidOnly=statStatusPair['paid_only'];
  }

  String toString() {
    return this.id.toString() + '.' + this.title;
  }
}
class Problem {
    final Uri _context = Uri.parse('https://leetcode.com/problems/');
    
    String description;
    String solution;
    ProblemSummary summary;

    Uri get contextEndpoint => _context.resolve(this.summary.titleSlug+'/');
    Uri get descContext => _context.resolve(this.summary.titleSlug+'/').resolve('');
    Uri get solutionContext => _context.resolve(this.summary.titleSlug+'/').resolve('solution/');
    
    Problem.fromSummary(ProblemSummary summary) {
      this.summary = summary;
    }

    String toString() {
      return summary.toString() + ' -> ' + descContext.toString();
    }
}


main(List<String> args) {
  loadContent(SummaryLoader(), dir: './cache')
  .then((content) {
    print(content);
  });
  Uri uri = Uri.parse('https://assets.leetcode.com/uploads/2019/05/02/tree.png');
  loadContent(ImageLoader(uri), dir: './cache')
  .then((content) {
    print(content);
  });
}