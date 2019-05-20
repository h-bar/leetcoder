import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui show Codec;
import 'dart:ui' show hashValues;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import 'content_loader.dart';

class ImageLoader extends ContentLoader{
  Uri _uri;
  http.Request get request => http.Request('GET', this._uri);
  String get cacheFileName {
    List<String> pathSegments = ['.'];
    pathSegments.addAll(request.url.pathSegments);
    return path.joinAll(pathSegments);
  }
  List<int> processContent(List<int> contentBytes) => contentBytes;

  ImageLoader(Uri uri) {
    this._uri = uri;
  }
}

class CLImage extends ImageProvider<CLImage> {
  /// Creates an object that fetches the image at the given URL.
  ///
  /// The arguments must not be null.
  const CLImage(this.url, { this.scale = 1.0, this.headers, this.resourceDir })
    : assert(url != null),
      assert(scale != null);

  final String resourceDir;
  
  /// The URL from which the image will be fetched.
  final String url;

  /// The scale to place in the [ImageInfo] object of the image.
  final double scale;

  /// The HTTP headers that will be used with [HttpClient.get] to fetch image from network.
  final Map<String, String> headers;

  @override
  Future<CLImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<CLImage>(this);
  }

  @override
  ImageStreamCompleter load(CLImage key) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key),
      scale: key.scale,
      informationCollector: (StringBuffer information) {
        information.writeln('Image provider: $this');
        information.write('Image key: $key');
      },
    );
  }


  Future<ui.Codec> _loadAsync(CLImage key) async {
    assert(key == this);

    ImageLoader loader = ImageLoader(Uri.parse(key.url));
    final Uint8List bytes = await loadContent(loader, dir: this.resourceDir);
    return PaintingBinding.instance.instantiateImageCodec(bytes);
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType)
      return false;
    final CLImage typedOther = other;
    return url == typedOther.url
        && scale == typedOther.scale;
  }

  @override
  int get hashCode => hashValues(url, scale);

  @override
  String toString() => '$runtimeType("$url", scale: $scale)';
}