import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'package:flutter/widgets.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:url_launcher/url_launcher.dart';

class _RenderTreeNodeStyle {
  bool isInline = true;
  bool isPre = false;
  Color bgColor;
  String href;
  TextStyle textStyle;

  _RenderTreeNodeStyle(bool isInline, {bool isPre: false, Color bg, TextStyle style}) {
    this.isInline = isInline;
    this.isPre = isPre;
    this.bgColor = bg;
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
      backgroundColor: Colors.grey[200],
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
    'pre': _RenderTreeNodeStyle(false, isPre: true, bg: Colors.grey[200]),
    'img': _RenderTreeNodeStyle(false),
    'sub': _RenderTreeNodeStyle(true),
    'sup': _RenderTreeNodeStyle(true),
    'strong': _RenderTreeNodeStyle(true, style: _textStyleSheet['strong']),
    'span': _RenderTreeNodeStyle(true),
    'em': _RenderTreeNodeStyle(true, style: _textStyleSheet['em']),
    'text': _RenderTreeNodeStyle(true, style: _textStyleSheet['text']),
    'code': _RenderTreeNodeStyle(true, style: _textStyleSheet['code']),
    'i': _RenderTreeNodeStyle(true,style:  _textStyleSheet['i']),
    'font': _RenderTreeNodeStyle(true, style: _textStyleSheet['font']),
    'b': _RenderTreeNodeStyle(true, style: _textStyleSheet['b']),
    'a': _RenderTreeNodeStyle(true, style: _textStyleSheet['a']),
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

      if (this.parent.style.textStyle != null) {
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
        widgets.add(RichText(
              text: TextSpan(
                children: lineText,
                style: TextStyle(
                  color: Colors.black,
        ))));
      }
    }

    if (widgets.isEmpty) {
      return null;
    }

    Widget renderedWidget;
    if (widgets.length == 1) {
      renderedWidget = widgets[0];
    } else {
      renderedWidget = Column(
        children: widgets,
        crossAxisAlignment: CrossAxisAlignment.start,
      );
    }

    if (!this.style.isInline) {
      renderedWidget =  Container(
            color: this.style.bgColor,
            constraints: BoxConstraints(minWidth: double.infinity),
            child: renderedWidget
    );
  }

    return renderedWidget;
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