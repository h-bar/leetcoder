import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

Future<String> _fetchContent(String contentId) async {
  Directory appDocDir = await getApplicationDocumentsDirectory();
  String appDocPath = appDocDir.path;

  String contentFolder;
  String contentFile;
  Uri url; 
  http.Request request;
  if (contentId == 'problemList') {
    contentFolder = appDocPath;
    contentFile = p.join(contentFolder, 'problemsList.json');
    url = Uri.parse("https://leetcode.com/api/problems/all");
    request = http.Request('GET', url);
  } else {
    contentFolder = p.join(appDocPath, 'problemContents');
    contentFile = p.join(contentFolder, contentId + '.json');
    url = Uri.parse('https://leetcode.com/graphql');
    request = http.Request('POST', url);
    request.headers.addAll({"Content-Type": "application/json"});
    request.body = jsonEncode({
      "operationName": "questionData",
      "variables": {
        "titleSlug": "$contentId"
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
  }

  
  Directory(contentFolder).createSync();
  File(contentFile).createSync();

  http.StreamedResponse responseStream = await request.send();
  String responseContent = await responseStream.stream.toStringStream().join();
  
  File(contentFile)
  .openWrite()
  .write(responseContent);
  print(contentId + ' fetched and cached');

  return responseContent;
}

Future<Map<String, dynamic>> loadContent(String contentId, bool refresh) async {
  Directory appDocDir = await getApplicationDocumentsDirectory();
  String appDocPath = appDocDir.path;
  
  String contentFolder;
  String contentFile;
  if (contentId == 'problemList') {
    contentFolder = appDocPath;
    contentFile = p.join(contentFolder, 'problemsList.json');
  } else {
    contentFolder = p.join(appDocPath, 'problemContents');
    contentFile = p.join(contentFolder, contentId + '.json');
  }

  Directory(contentFolder).createSync();
  File(contentFile).createSync();
  
  String fileContents = File(contentFile).readAsStringSync();
  if (refresh || fileContents.isEmpty) {
    fileContents = await _fetchContent(contentId);
  }
  return jsonDecode(fileContents);
}