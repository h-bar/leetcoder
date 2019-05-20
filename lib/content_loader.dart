import 'dart:async';
import 'dart:io' as io;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

Future<dynamic> loadContent(ContentLoader loader, {bool refresh: false, String dir: '.'}) async {
  List<int> content;
  String fileName = path.join(dir, loader.cacheFileName);
  io.File cacheFile = io.File(fileName);
  if (!refresh && cacheFile.existsSync()) {
    content = cacheFile.readAsBytesSync();
  } else {
    cacheFile.parent.createSync(recursive: true);
    http.StreamedResponse resp = await loader.request.send();
    // contentStream = resp.stream.asBroadcastStream();
    // contentStream.pipe(cacheFile.openWrite());
    content = await resp.stream.toBytes();
    cacheFile.writeAsBytesSync(content);
  }

  return loader.processContent(content);
}

class ContentLoader {
  http.Request get request => null;
  String get cacheFileName => '';
  dynamic processContent(List<int> data) {
    print('Loading');
  }
}