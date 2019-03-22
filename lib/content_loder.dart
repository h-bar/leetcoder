import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

Future<Map<String, dynamic>> _getProblemDescriptor(String contentType, String contentId) async {
  Directory appDocDir = await getApplicationDocumentsDirectory();
  String appDocPath = appDocDir.path;

  String contentFilePath;
  http.Request contentRequest;
  switch (contentType) {
    case 'problemList':
      Uri url = Uri.parse("https://leetcode.com/api/problems/all");
      contentFilePath = p.join(appDocPath, 'problemsList.json');
      contentRequest = http.Request('GET', url);
      break;
    case 'problemDetail': //TODO: Handle no solution, non-free question
      Uri url = Uri.parse('https://leetcode.com/graphql');
      contentFilePath = p.join(appDocPath, 'problemDetails', contentId + '.json');
      contentRequest = http.Request('POST', url);
      contentRequest.headers.addAll({"Content-Type": "application/json"});
      contentRequest.body = jsonEncode({
      "operationName": "questionData",
      "variables": {
        "titleSlug": "$contentId"
      },
      "query": '''query questionData(\$titleSlug: String!) {
                    question(titleSlug: \$titleSlug) {
                      content
                      difficulty
                      likes
                      dislikes
                      isLiked
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
                          content
                        canSeeDetail
                        __typename
                      }
                      __typename
                    }
                  }'''
    });
      break;
    default:
  }

  Map<String, dynamic> contentDescriptor = {
    'contentId': contentId,
    'contentType':contentType,
    'contentFilePath': contentFilePath,
    'contentRequest': contentRequest
  };
  
  return contentDescriptor;
}
Future<String> _fetchContent(String contentType, String contentId) async {
  Map<String, dynamic> problemDescriptor = await _getProblemDescriptor(contentType, contentId);
  Directory(p.dirname(problemDescriptor['contentFilePath'])).createSync();
  File(problemDescriptor['contentFilePath']).createSync();

  http.StreamedResponse responseStream = await problemDescriptor['contentRequest'].send();
  String responseContent = await responseStream.stream.toStringStream().join();
  
  File(problemDescriptor['contentFilePath'])
  .openWrite()
  .write(responseContent);
  print(contentId + ' fetched and cached');

  return responseContent;
}

Future<Map<String, dynamic>> loadContent(String contentType, String contentId, bool refresh) async {
  Map<String, dynamic> problemDescriptor = await _getProblemDescriptor(contentType, contentId);
  Directory(p.dirname(problemDescriptor['contentFilePath'])).createSync();
  File(problemDescriptor['contentFilePath']).createSync();
  
  String fileContents = File(problemDescriptor['contentFilePath']).readAsStringSync();
  if (refresh || fileContents.isEmpty) {
    fileContents = await _fetchContent(contentType, contentId);
  }
  return jsonDecode(fileContents);
}