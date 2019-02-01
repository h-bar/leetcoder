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
      color: Colors.black,
      fontWeight: FontWeight.bold,
    ),
    "em": const TextStyle(
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
      if(node is dom.Element) {
        switch (node.localName) {
          case 'p':
            widgetList.add(_parseTextNodes(node.nodes));
            break;
          case 'img':
            widgetList.add(_parseImgNode(node));
            break; 
          case 'pre':
            widgetList.add(_parsePreNodes(node.nodes));
            break;
          default:
            widgetList.addAll(_parseNodeList(node.nodes));
        }
      }
    }
    return widgetList;
  }

  RichText _parseTextNodes(List<dom.Node> nodeList) {
    List<TextSpan> textDisplay = List<TextSpan>();
    for (dom.Node node in nodeList) {
      String textStyleKey = 'text';
      if (node is dom.Element) {
        textStyleKey = node.localName;
      }

      textDisplay.add(TextSpan(
        text: node.text,
        style: styleSheet[textStyleKey],
      ));
    }

    return RichText(
      text: TextSpan(
      children: textDisplay
    ));
  }
  Image _parseImgNode(dom.Node node) {
    return Image.network(node.attributes['src']);
  }
  
  // TODO: Finish the pre part
  Wrap _parsePreNodes(List<dom.Node> nodes) {
    return Wrap();
  }
  
  
  
  
  // Widget _parseNode(dom.Element node) {
  //   String nodeType = node.localName;
  //   if (styleSheet[nodeType] != null) {
  //     return Text(
  //         node.text,
  //         style: styleSheet[nodeType],
  //       ); 
  //   }

  //   switch (node.localName) {
  //     case "img":
  //       return Image.network(node.attributes['src']);
  //     case "br":
  //       return Divider(
  //         height: 0,
  //         color: Colors.transparent,
  //       );
  //     case "a":
  //       return GestureDetector(
  //         child: Text(
  //           node.text,
  //           style: styleSheet["link"],
  //         ),
  //         onTap: () {
  //           if (node.attributes['href'] != null && onLinkTap != null) {
  //             String url = node.attributes['href'];
  //             onLinkTap(url);
  //           }
  //         });
  //   }

  //   if (["body", "div"].contains(nodeType)) {
  //     return Container(
  //       width: width,
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: _parseNodeList(node.nodes),
  //       ),
  //     );
  //   }
  
  //   if(nodeType == "pre") {
  //     List<dom.Node> strongList = List<dom.Node>();

  //     for (dom.Node tmpNode in node.nodes) {
  //       if (tmpNode is dom.Element && tmpNode.localName == 'strong') {
  //         strongList.add(tmpNode);
  //       }
  //     }

  //     if (strongList.isNotEmpty) {
  //       for (dom.Node tmpNode in strongList.getRange(1, strongList.length)) {
  //         node.insertBefore(dom.Element.tag('br'), tmpNode);
  //       }
  //     }
  //     return Wrap(
  //       children: _parseNodeList(node.nodes),
  //       );
  //   }

  //   if (["ol", "ul"].contains(nodeType)) {
  //     return Column(
  //       children: _parseNodeList(node.nodes),
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //     );
  //   }

  //   if (nodeType == "p") {
  //     return Wrap(
  //         children: _parseNodeList(node.nodes),
  //     );
  //   }

  //   if (nodeType == "li") {
  //     String type = node.parent.localName;
  //     const EdgeInsets markPadding = EdgeInsets.symmetric(horizontal: 4.0);
  //     String markText = type == "ol" ? '${node.parent.children.indexOf(node) + 1}.' : '•'; 
  //     Widget mark = Container(child: Text(markText), padding: markPadding);

  //     return Container(
  //       width: width,
  //       child: Wrap(
  //         children: <Widget>[
  //           mark,
  //           Wrap(children: _parseNodeList(node.nodes))
  //         ],
  //       ),
  //     );
  //   }

  //   return Wrap();
  // }
}
