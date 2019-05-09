import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'package:flutter/widgets.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:url_launcher/url_launcher.dart';

class _RenderTreeNodeStyle {
  bool isInline = true;
  bool isPre = false;
  bool isLink = false;
  TextStyle textStyle;

  _RenderTreeNodeStyle(bool isInline, {bool isPre: false, bool isLink: false}) {
    this.isInline = isInline;
    this.isPre = isPre;
    this.isLink = isLink;
  }

  _RenderTreeNodeStyle.textStyole(bool isInline, TextStyle style, {bool isLink: false}) {
    this.isInline = isInline;
    this.textStyle = style;
    this.isLink = isLink;
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

  static final Map<String, TextStyle> _textStyleSheet = {
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

  Map<String, _RenderTreeNodeStyle> _styleSheet = {
    'body': _RenderTreeNodeStyle(false),
    'p': _RenderTreeNodeStyle(false),
    'div': _RenderTreeNodeStyle(false,),
    'pre': _RenderTreeNodeStyle(false, isPre: true),
    'img': _RenderTreeNodeStyle(false),
    'strong': _RenderTreeNodeStyle.textStyole(true, _textStyleSheet['strong']),
    'span': _RenderTreeNodeStyle.textStyole(true, _textStyleSheet['span']),
    'em': _RenderTreeNodeStyle.textStyole(true, _textStyleSheet['em']),
    'text': _RenderTreeNodeStyle.textStyole(true, _textStyleSheet['text']),
    'code': _RenderTreeNodeStyle.textStyole(true, _textStyleSheet['code']),
    'i': _RenderTreeNodeStyle.textStyole(true, _textStyleSheet['i']),
    'font': _RenderTreeNodeStyle.textStyole(true, _textStyleSheet['font']),
    'b': _RenderTreeNodeStyle.textStyole(true, _textStyleSheet['b']),
    'a': _RenderTreeNodeStyle.textStyole(true, _textStyleSheet['a'], isLink: true),
  };

  _RenderTreeNode(dom.Node node, _RenderTreeNode parent, Uri context) {
    this.node = node;
    this.parent = parent;
    this.htmlContext = context;
    _initNode();
    _addStyle();
    for (dom.Node nextNode in node.nodes) {
      this.children.add(_RenderTreeNode(nextNode, this, this.htmlContext));
    }
  }

  void _initNode() {
    if (node is dom.Text) {
      this.text = node.text;
      this.type = 'text';
      this.tag = 'text';
      return;
    }
    
    dom.Element nodeE = node as dom.Element;
    this.tag = nodeE.localName;
    this.type = this.tag;

    if (node.children.isEmpty && !_RenderTreeNode._terminalTag.contains(this.tag)) {
      this.type = 'text';
      this.text = node.text;
      return;
    }
  }

  void _addStyle() {
    this.style = this._styleSheet[this.tag] ?? _RenderTreeNodeStyle(false);
    if (this.parent != null) {
      this.style.isPre = this.parent.style.isPre || this.style.isPre;
    }
  }

  TapGestureRecognizer _linkTapped() {
    if (this.style.isLink) {
      return TapGestureRecognizer()..onTap = () async {
        Uri uri = Uri.parse(this.node.attributes['href']);
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
    switch (this.type) {
      case 'text':
        String text = this.style.isPre? this.text : this.text.replaceAll(new RegExp(r"\s+"), " ");
        text = this.style.isPre ? text : text.trimLeft();
        
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
      
    List<List<Widget>> widgetsHolder =  List<List<Widget>>();
    _RenderTreeNode olderChild = this.children.length == 0 ? null : this.children[0];
    for (_RenderTreeNode child in this.children) {
      bool addNewCol = !olderChild.style.isInline || !child.style.isInline;
      addNewCol &= !child.style.isPre;
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
    
    List<Widget> widgets = List<Widget>();
    for (List<Widget> widgetRow in widgetsHolder) {
      bool isText = false;
      List<TextSpan> lineText = List<TextSpan>();
      for (Widget widget in widgetRow) {
        if (widget is Text) {
          isText = true;
          lineText.add(widget.textSpan);
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
    Widget widgeList = renderTree.toWidget();
    return widgeList;
  }
}