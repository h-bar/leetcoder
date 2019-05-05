import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:url_launcher/url_launcher.dart';

class HtmlRenderer{
  String htmlData;
  Uri htmlContext;

  Widget parse() {
    dom.Document document = parser.parse(this.htmlData);
    Widget widgeList = _parseNode(document.body);
    return widgeList;
  }

  final Map<String, TextStyle> _textStyleSheet = {
    "strong": const TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
    ),
    "em": const TextStyle(
      color: Colors.black,
      fontStyle: FontStyle.italic,
    ),
    "i": const TextStyle(
      color: Colors.black,
      fontStyle: FontStyle.italic,
    ),
    "font": const TextStyle(
      color: Colors.black,
      fontFamily: 'monospace',
    ),
    "b": const TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
    ),
    "code": TextStyle(
      fontFamily: 'monospace',
      color: Colors.blueGrey,
      background: Paint()..color = Colors.grey[200],
    ),
    "span": TextStyle(
      fontFamily: 'monospace',
      color: Colors.blueGrey,
    ),
    "a": const TextStyle(
      decoration: TextDecoration.underline,
      color: Colors.blueAccent,
      decorationColor: Colors.blueAccent
    ),
    "defalut": const TextStyle(
      color: Colors.black,
    )
  };


  bool _isInlineText(dom.Node node) {
    return (node is dom.Text) || (node is dom.Element && _textStyleSheet.keys.contains(node.localName));
  }


  TextSpan _parseTextNode(dom.Node node,{bool isPre: false}) {
    if (node is dom.Text) {
      if (!isPre && node.text.trim() == '') {
        return null;
      }

      if (node.parent.localName == 'a') {
        return TextSpan(
          text: node.text,
          style: _textStyleSheet[node.parent.localName] ?? _textStyleSheet['defalut'],
          recognizer: TapGestureRecognizer()
          ..onTap = () async {
            String url = node.parent.attributes['href'];
            if (await canLaunch(url)) {
              await launch(url);
            } else {
              throw 'Could not launch $url';
            }
          }, 
        ); 
      }
      
      return TextSpan(
        text: node.text,
        style: _textStyleSheet[node.parent.localName] ?? _textStyleSheet['defalut']
      );
    }
    
    List<TextSpan> textSpan = List<TextSpan>();
    for (dom.Node nextNode in node.nodes) {
      TextSpan nextSpan = _parseTextNode(nextNode, isPre: isPre);
      if (nextSpan != null){
        textSpan.add(nextSpan);
      }
    }
    return TextSpan(children: textSpan);
  }

  Widget _parsePreNode(dom.Node node) {
    return new Container(
        color: Colors.grey[200],
        child: RichText(
          text: _parseTextNode(node, isPre: true)
        )
      );
  }

  Widget _node2Widget(dom.Node node) {
    if (node is! dom.Element) {
      return _parseNode(node);
    }

    dom.Element nodeE = node as dom.Element;
    if (nodeE.localName == 'pre') {
      return _parsePreNode(node);
    }
    return _parseNode(node);
  }

  Widget _parseNode(dom.Node node) {
    if (node is! dom.Element) {
      return null;
    }

    dom.Element nodeE = node as dom.Element;
    dom.NodeList children = nodeE.nodes;
    String nodeTag = nodeE.localName;

    if (nodeTag == 'img') {
      Uri uri = Uri.parse(node.attributes['src']);
      uri = uri.hasScheme ? uri : this.htmlContext.resolveUri(uri);
      return Image.network(uri.toString());
    }

    if (children.isEmpty) {
      return null;
    }

    List<Widget> childWidgets = List<Widget>();
    for (dom.Node nextNode in nodeE.nodes) {
      if (_isInlineText(nextNode)) {
        List<TextSpan> textSpans = List<TextSpan>();
        TextSpan nextTextSpan = _parseTextNode(nextNode);
        if (nextTextSpan == null) {
          continue;
        }
        if (childWidgets.isNotEmpty && childWidgets.last is RichText) {
          textSpans.addAll((childWidgets.removeLast() as RichText).text.children);
        }
        textSpans.add(nextTextSpan);
        childWidgets.add(RichText(
          text: TextSpan(
            children: textSpans, 
            style: TextStyle(color: Colors.black)
            ),
          textAlign: TextAlign.left,
        ));
      }
      else {
        Widget nextNodeWidget = _node2Widget(nextNode);
        if (nextNodeWidget != null) {
          childWidgets.add(nextNodeWidget);
        }
      }
    }

    return Column(
      children: childWidgets,
      crossAxisAlignment: CrossAxisAlignment.start,
      );
  }
}