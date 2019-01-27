library flutter_html;

import 'package:flutter/material.dart';
import 'html_parser.dart';

class Html extends StatelessWidget {
  Html({
    Key key,
    @required this.data,
    this.padding,
    this.backgroundColor,
    this.defaultTextStyle = const TextStyle(color: Colors.black),
    this.onLinkTap,
  }) : super(key: key);

  final String data;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final TextStyle defaultTextStyle;
  final OnLinkTap onLinkTap;

  @override
  Widget build(BuildContext context) {
    // final double width = MediaQuery.of(context).size.width;
    final double width = 600;
    return Container(
      padding: padding,
      color: backgroundColor,
      width: width,
      child: DefaultTextStyle.merge(
        style: defaultTextStyle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: HtmlParser(
            width: width,
            onLinkTap: onLinkTap,
          ).parse(data),
        ),
      ),
    );
  }
}