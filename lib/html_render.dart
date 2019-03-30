import 'package:flutter/material.dart';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;

Widget htmlParse(String data) {
  data = data.replaceAll('\r\n\r\n', '');
  dom.Document document = parser.parse(data);
  Widget widgeList = _parseNode(document.body);
  return widgeList;
}

final Map<String, TextStyle> textStyleSheet = {
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
      background: Paint()..color = Colors.grey[100],
    ),
    "span": TextStyle(
      fontFamily: 'monospace',
      color: Colors.blueGrey,
    ),
    "a": const TextStyle(
      decoration: TextDecoration.underline,
      color: Colors.blueAccent,
      decorationColor: Colors.blueAccent
    )
  };


bool _isInlineText(dom.Node node) {
  return (node is dom.Text) || (node is dom.Element && textStyleSheet.keys.contains(node.localName));
}


TextSpan _parseInLineNode(dom.Node node) { //TODO: Solve the Notes gap problem, caused by having some '\n' or '\n    ' that was rendered into a colume
  if (node is dom.Text) {
    return TextSpan(text: node.text);
  }
  
  dom.Element nodeE = node as dom.Element;
  List<TextSpan> textSpan = List<TextSpan>();
  for (dom.Node nextNode in node.nodes) {
    textSpan.add(_parseInLineNode(nextNode));
  }
  return TextSpan(
    children: textSpan,
    style: textStyleSheet[nodeE.localName],
  );
}

Widget _node2Widget(dom.Node node) {
  Widget childNode = _parseNode(node);
  if (node is! dom.Element) {
    return childNode;
  }

  dom.Element nodeE = node as dom.Element;
  if (nodeE.localName == 'pre') {
    return new Container(
      color: Colors.grey[200],
      child: childNode,
    );
  }
  return childNode;
}

Widget _parseNode(dom.Node node) {
  if (node is! dom.Element) {
    return null;
  }

  dom.Element nodeE = node as dom.Element;
  dom.NodeList children = nodeE.nodes;
  String nodeTag = nodeE.localName;

  if (nodeTag == 'img') {
    return Image.network(
      node.attributes['src']
    );
  }

  if (children.isEmpty) {
    return null;
  }

  List<Widget> childWidgets = List<Widget>();
  for (dom.Node nextNode in nodeE.nodes) {
    if (_isInlineText(nextNode)) {
      List<TextSpan> textSpans = List<TextSpan>();
      if (childWidgets.isNotEmpty && childWidgets.last is RichText) {
        textSpans.addAll((childWidgets.removeLast() as RichText).text.children);
      }
      textSpans.add(_parseInLineNode(nextNode));
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