import 'package:flutter/material.dart';
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;

typedef CustomRender = Widget Function(dom.Node node, List<Widget> children);
typedef OnLinkTap = void Function(String url);

class HtmlParser {
  HtmlParser({
    @required this.width,
    this.onLinkTap
  });

  final double width;
  final OnLinkTap onLinkTap;

  final Map<String, TextStyle> textStyleSheet = {
    "text": const TextStyle(
      color: Colors.black,
    ),
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
    ),
  };

  List<Widget> parse(String data) {
    data = data.replaceAll('\r\n\r\n', '');
    dom.DocumentFragment document = parser.parseFragment(data);
    List<Widget> widgeList = _parseNodeList(document.nodes);
    // debugDumpApp();
    return widgeList;
  }

  bool isTextNode(dom.Node node) {
    return node is dom.Text || textStyleSheet.containsKey((node as dom.Element).localName);
  }

  bool isImgNode(dom.Node node) {
    return node is dom.Element && node.localName == 'img';
  }

  List<Widget> _parseNodeList(List<dom.Node> nodeList) {
    List<Widget> widgetList = List<Widget>();
    Iterator<dom.Node> nodeItr = nodeList.iterator;
    nodeItr.moveNext();
    dom.Node currentNode = nodeItr.current;
    while(currentNode != null) {
      if (isTextNode(currentNode)) {
        List<TextSpan> textSpans = List<TextSpan>();
        while(currentNode != null && isTextNode(currentNode)) {
          String text = '';
          String styleKey = '';
          if (currentNode is dom.Text) {
            text = currentNode.text;
            styleKey = 'text';
          } else if (currentNode is dom.Element) {
            text = currentNode.innerHtml;
            styleKey = currentNode.localName;
          }

          textSpans.add(TextSpan(
            text: text,
            style: textStyleSheet[styleKey],
          ));

          nodeItr.moveNext();
          currentNode = nodeItr.current;
        }

        widgetList.add(RichText(
          text: TextSpan(
            children: textSpans,
          ),
        ));
      } else if (isImgNode(currentNode)) {
        widgetList.add(Image.network(currentNode.attributes['src']));
        nodeItr.moveNext();
        currentNode = nodeItr.current;   
      } else {
        widgetList.add(Wrap(
          children: _parseNodeList(currentNode.nodes)
          ));
        nodeItr.moveNext();
        currentNode = nodeItr.current;   
      }  
    }
    return widgetList;
  }
}
