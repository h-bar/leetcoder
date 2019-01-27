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

  static const _supportedElements = [
    "body",
    "br",
    "code",
    "div",
    "em",
    "img",
    "li",
    "ol", //partial
    "p",
    "pre",
    "span",
    "strong",
    "ul", //partial
    "a",
  ];
  final Map<String, TextStyle> styleSheet = {
    "text": const TextStyle(
      color: Colors.black,
    ),
    "strong": const TextStyle(
      fontWeight: FontWeight.bold,
    ),
    "em": const TextStyle(
      fontStyle: FontStyle.italic,
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
    "link": const TextStyle(
      decoration: TextDecoration.underline,
      color: Colors.blueAccent,
      decorationColor: Colors.blueAccent
    ),
  };

  List<Widget> parse(String data) {
    dom.DocumentFragment document = parser.parseFragment(data);
    return _parseNodeList(document.nodes);
  }

  List<Widget> _parseNodeList(List<dom.Node> nodeList) {
    List<Widget> widgetList = List<Widget>();
    for (dom.Node node in nodeList) {
      if (node is dom.Text && node.text.trim() != '') {
        // TODO: Text wrapping not working correctly, breaking lines from the middle
        // The reason behind this may be that the container for the texts start a new
        //  lines when there's no enought room to put the whole Text() into that line,
        widgetList.add(Text(node.text));
      }
      else if (node is dom.Element && _supportedElements.contains(node.localName)){
        widgetList.add(_parseNode(node));
      }
    }
    return widgetList;
  }

  Widget _parseNode(dom.Element node) {
    String nodeType = node.localName;
    if (styleSheet[nodeType] != null) {
      return Text(
          node.text,
          style: styleSheet[nodeType],
        ); 
    }

    switch (node.localName) {
      case "img":
        return Image.network(node.attributes['src']);
      case "br":
        return Divider(
          height: 0,
          color: Colors.transparent,
        );
      case "a":
        return GestureDetector(
          child: Text(
            node.text,
            style: styleSheet["link"],
          ),
          onTap: () {
            if (node.attributes['href'] != null && onLinkTap != null) {
              String url = node.attributes['href'];
              onLinkTap(url);
            }
          });
    }

    if (["body", "div"].contains(nodeType)) {
      return Container(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _parseNodeList(node.nodes),
        ),
      );
    }
  
    if(nodeType == "pre") {
      List<dom.Node> strongList = List<dom.Node>();

      for (dom.Node tmpNode in node.nodes) {
        if (tmpNode is dom.Element && tmpNode.localName == 'strong') {
          strongList.add(tmpNode);
        }
      }

      if (strongList.isNotEmpty) {
        for (dom.Node tmpNode in strongList.getRange(1, strongList.length)) {
          node.insertBefore(dom.Element.tag('br'), tmpNode);
        }
      }
      return Wrap(
        children: _parseNodeList(node.nodes),
        );
    }

    if (["ol", "ul"].contains(nodeType)) {
      return Column(
        children: _parseNodeList(node.nodes),
        crossAxisAlignment: CrossAxisAlignment.start,
      );
    }

    if (nodeType == "p") {
      return Wrap(
          children: _parseNodeList(node.nodes),
      );
    }

    if (nodeType == "li") {
      String type = node.parent.localName;
      const EdgeInsets markPadding = EdgeInsets.symmetric(horizontal: 4.0);
      String markText = type == "ol" ? '${node.parent.children.indexOf(node) + 1}.' : '•'; 
      Widget mark = Container(child: Text(markText), padding: markPadding);

      return Container(
        width: width,
        child: Wrap(
          children: <Widget>[
            mark,
            Wrap(children: _parseNodeList(node.nodes))
          ],
        ),
      );
    }

    return Wrap();
  }
}
