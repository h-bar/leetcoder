import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'package:flutter/widgets.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:url_launcher/url_launcher.dart';

import 'image_loader.dart';
import 'content_loader.dart';

class _RenderTreeNodeStyle {
  bool isInline = true;
  bool isPre = false;
  Color bgColor;
  String href;
  TextStyle textStyle;

  _RenderTreeNodeStyle(bool isInline, {bool isPre: false, Color bg, TextStyle style, String href}) {
    this.isInline = isInline;
    this.isPre = isPre;
    this.bgColor = bg;
    this.textStyle = style;
    this.href = href;
  }

  _RenderTreeNodeStyle merge(_RenderTreeNodeStyle nodeStyle) {
    TextStyle textStyle;
    if (this.textStyle != null) {
      textStyle = this.textStyle.merge(nodeStyle.textStyle);
    }

    return _RenderTreeNodeStyle(
      nodeStyle.isInline, 
      isPre: this.isPre || nodeStyle.isPre,
      bg: nodeStyle.bgColor ?? this.bgColor,
      href: nodeStyle.href ?? this.href,
      style: textStyle
      );
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
  String resourceDir;

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

  final Map<String, _RenderTreeNodeStyle> _styleSheet = {
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

  _RenderTreeNode(dom.Node node, _RenderTreeNode parent, Uri context, String resourceDir) {
    this.node = node;
    this.parent = parent;
    this.htmlContext = context;
    this.resourceDir = resourceDir;

    if (this.node is dom.Text) {
      this.text = this.node.text;
      this.type = 'text';
      this.tag = 'text';
    } else if (this.node is dom.Element) {
      dom.Element nodeE = this.node as dom.Element;
      this.tag = nodeE.localName;
      this.type = this.tag;
    }

    for (dom.Node nextNode in node.nodes) {
      this.children.add(_RenderTreeNode(nextNode, this, this.htmlContext, this.resourceDir));
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

    this.type = 'text';
    if (this.children.length == 1 && this.children[0].tag == 'text') {
      this.text = node.text;
      this.children = [];
    }
  }

  void addStyle() {
    this.style = this.type == 'text' ? this._styleSheet['text'] : this._styleSheet['body'];
    this.style.href = this.node.attributes['href'];
    this.style = this.parent == null ? this.style : this.style.merge(this.parent.style);
    this.style = this._styleSheet[this.tag] == null ? this.style : this.style.merge(this._styleSheet[this.tag]);  

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
          return Image(image: CLImage(uri.toString(), resourceDir: this.resourceDir),);
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
    
    RichText conctracteTexts(List<TextSpan> texts) {
      if (texts.isNotEmpty) {
        return RichText(
          text: TextSpan(children: texts,));
      }
      return null;
    }

    for (List<Widget> widgetRow in widgetsHolder) {
      List<TextSpan> lineText = List<TextSpan>();
      for (Widget widget in widgetRow) {
        if (widget is Text) {
          lineText.add(widget.textSpan);
        } else if (widget is RichText) {
          lineText.addAll(widget.text.children);
        } else {
          if (lineText.isNotEmpty) {
            widgets.add(conctracteTexts(lineText));
          }
          lineText.clear();
          widgets.add(widget);
        }
      }

      if (lineText.isNotEmpty) {
        widgets.add(conctracteTexts(lineText));
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

void cacheHTML(String htmldata, Uri htmlContext, String resourceDir) {
  dom.Document document = parser.parse(htmldata);
  List<dom.Element> nodes = List<dom.Element>();
  nodes.addAll(document.children);

  while (nodes.isNotEmpty) {
    dom.Element node = nodes.removeLast();
    nodes.addAll(node.children);
    
    if (node.localName == 'img') {
      Uri uri = Uri.parse(node.attributes['src']);
      uri = uri.hasScheme ? uri : htmlContext.resolveUri(uri);
      loadContent(ImageLoader(uri), refresh: true, dir: resourceDir);
    }
  }
}

Widget html2Widget(String htmlData, Uri htmlContext, String resourceDir) {
  dom.Document document = parser.parse(htmlData);
  _RenderTreeNode renderTree = _RenderTreeNode(document.body, null, htmlContext, resourceDir)..initNode()..addStyle();
  return renderTree.toWidget();
}

Widget html2View(String htmlData, Uri htmlContext,  String resourceDir, {Function refreshCallback}) {
  return RefreshIndicator(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      physics: const AlwaysScrollableScrollPhysics(),
      child: html2Widget(htmlData, htmlContext, resourceDir),
    ),
    onRefresh: refreshCallback
  );
}