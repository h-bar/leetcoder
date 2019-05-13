import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'package:flutter/widgets.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:url_launcher/url_launcher.dart';

class _RenderTreeNodeStyle {
  bool isInline = true;
  bool isPre = false;
  String href;
  TextStyle textStyle;

  _RenderTreeNodeStyle(bool isInline, {bool isPre: false}) {
    this.isInline = isInline;
    this.isPre = isPre;
  }

  _RenderTreeNodeStyle.fromTextStyle(bool isInline, TextStyle style) {
    this.isInline = isInline;
    this.textStyle = style;
  }
}

class _RenderTreeNode {
  bool isTerminal;
  String text = '';
  String type;
  String tag;
  dom.Node node;
  _RenderTreeNodeStyle style;
  Uri htmlContext;

  _RenderTreeNode parent;
  List<_RenderTreeNode> children = List<_RenderTreeNode>();

  static const List<String> _terminalTag = [
    'img',
  ];

  static const List<String> _textTag = [
    "strong",
    "em",
    "i",
    "font",
    "b",
    "code",
    "span",
    "a",
    "sub",
    "sup",
    "text"
  ];
  
  static final Map<String, TextStyle> _textStyleSheet = {
    "strong": const TextStyle(
      fontWeight: FontWeight.bold,
    ),
    "em": const TextStyle(
      fontStyle: FontStyle.italic,
    ),
    "i": const TextStyle(
      fontStyle: FontStyle.italic,
    ),
    "font": const TextStyle(
      fontFamily: 'monospace',
    ),
    "b": const TextStyle(
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
    "text": const TextStyle(
      color: Colors.black,
    )
  };

  Map<String, _RenderTreeNodeStyle> _styleSheet = {
    'body': _RenderTreeNodeStyle(false),
    'p': _RenderTreeNodeStyle(false),
    'div': _RenderTreeNodeStyle(false,),
    'pre': _RenderTreeNodeStyle(false, isPre: true),
    'img': _RenderTreeNodeStyle(false),
    'sub': _RenderTreeNodeStyle.fromTextStyle(true, null),
    'sup': _RenderTreeNodeStyle.fromTextStyle(true, null),
    'strong': _RenderTreeNodeStyle.fromTextStyle(true, _textStyleSheet['strong']),
    'span': _RenderTreeNodeStyle.fromTextStyle(true, _textStyleSheet['span']),
    'em': _RenderTreeNodeStyle.fromTextStyle(true, _textStyleSheet['em']),
    'text': _RenderTreeNodeStyle.fromTextStyle(true, _textStyleSheet['text']),
    'code': _RenderTreeNodeStyle.fromTextStyle(true, _textStyleSheet['code']),
    'i': _RenderTreeNodeStyle.fromTextStyle(true, _textStyleSheet['i']),
    'font': _RenderTreeNodeStyle.fromTextStyle(true, _textStyleSheet['font']),
    'b': _RenderTreeNodeStyle.fromTextStyle(true, _textStyleSheet['b']),
    'a': _RenderTreeNodeStyle.fromTextStyle(true, _textStyleSheet['a']),
  };

  _RenderTreeNode(dom.Node node, _RenderTreeNode parent, Uri context) {
    this.node = node;
    this.parent = parent;
    this.htmlContext = context;

    if (this.node is dom.Text) {
      this.text = this.node.text;
      this.type = 'text';
      this.tag = 'text';
    } else {
      dom.Element nodeE = this.node as dom.Element;
      this.tag = nodeE.localName;
      this.type = this.tag;
    }

    for (dom.Node nextNode in node.nodes) {
      this.children.add(_RenderTreeNode(nextNode, this, this.htmlContext));
    }
  }

  void initNode() {   
    for (_RenderTreeNode child in this.children) {
      child.initNode();
    }

    if (!_textTag.contains(this.tag)) {
      return;
    }
    
    if (this.children.any((child) => child.type != 'text')) {
      return;
    }

    this.type   = 'text';
    if (this.children.length == 1 && this.children[0].tag == 'text') {
      this.text = node.text;
      this.children = [];
    }
  }

  void addStyle() {
    this.style = this._styleSheet[this.tag];  
    if (this.parent != null) {
      this.style = this.style ?? this.parent.style;
      this.style.href = this.node.attributes['href'] ?? this.parent.style.href;
      this.style.isPre = this.parent.style.isPre || this.style.isPre;

      if (this.parent.type == 'text') {
        this.style.textStyle = this.parent.style.textStyle.merge(this.style.textStyle);
      }
    }
    
    for (_RenderTreeNode child in this.children) {
      child.addStyle();
    }
  }

  TapGestureRecognizer _linkTapped() {
    if (this.style.href != null) {
      return TapGestureRecognizer()..onTap = () async {
        Uri uri = Uri.parse(this.style.href);
        uri = uri.hasScheme ? uri : this.htmlContext.resolveUri(uri);
        if (await canLaunch(uri.toString())) {
          await launch(uri.toString());
        } else {
          throw 'Could not launch $uri';
        }
      };
    }

    return null;
  }

  Widget toWidget() {
    if (this.children.isEmpty) {
      switch (this.type) {
        case 'text':
          String text = this.text;
          if (!this.style.isPre) {
            text = text.replaceAll(new RegExp(r'\s+'), ' ');
            text = text.trim().isNotEmpty ? text : '';

            text = this.parent.children.indexOf(this) == 0 && this.tag == 'text' ? text.trimLeft() : text;
          }
          
          return text.isEmpty ? null : Text.rich(TextSpan(
            text: text,
            style: this.style.textStyle,
            recognizer: _linkTapped()
          ));
        case 'img':
          Uri uri = Uri.parse(this.node.attributes['src']);
          uri = uri.hasScheme ? uri : this.htmlContext.resolveUri(uri);
          return Image.network(uri.toString());
      }
    }
      
    List<List<Widget>> widgetsHolder =  List<List<Widget>>();
    _RenderTreeNode olderChild = this.children.length == 0 ? null : this.children[0];
    for (_RenderTreeNode child in this.children) {
      bool addNewCol = !olderChild.style.isInline || !child.style.isInline;
      addNewCol |= widgetsHolder.length == 0;
      
      if (addNewCol) { 
        widgetsHolder.add(List<Widget>());
      }

      Widget childWidget = child.toWidget();
      if (childWidget != null) {
        widgetsHolder.last.add(childWidget); 
      }
      olderChild = child;
    }
    // print(widgetsHolder);
    List<Widget> widgets = List<Widget>();
    for (List<Widget> widgetRow in widgetsHolder) {
      bool isText = false;
      List<TextSpan> lineText = List<TextSpan>();
      for (Widget widget in widgetRow) {
        if (widget is Text) {
          isText = true;
          lineText.add(widget.textSpan);
        } else if (widget is RichText) {
          isText = true;
          lineText.addAll(widget.text.children);
        } else {
          widgets.add(widget);
        }
      }

      if (isText) {
        widgets.add(
          RichText(
            text: TextSpan(
              children: lineText,
              style: TextStyle(color: Colors.black),
        )));
      }
    }

    if (widgets.isEmpty) {
      return null;
    }
    if (widgets.length == 1) {
      return widgets[0];
    }

    return Column(
      children: widgets,
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }
}

class HtmlRenderer {
  String htmlData;
  Uri htmlContext;

  Widget parse() {
    dom.Document document = parser.parse(this.htmlData);
    _RenderTreeNode renderTree = _RenderTreeNode(document.body, null, this.htmlContext);
    renderTree.initNode();
    renderTree.addStyle();
    Widget widgeList = renderTree.toWidget();
    return widgeList;
  }
}