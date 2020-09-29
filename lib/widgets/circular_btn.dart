import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CircularButton extends StatelessWidget {
  final double height;
  final double width;
  final Color color;
  final Widget icon;
  final Function onClick;

  const CircularButton(
      {Key key, this.height, this.width, this.color, this.icon, this.onClick})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      width: width,
      height: height,
      child: IconButton(
        icon: icon,
        enableFeedback: true,
        onPressed: onClick,
      ),
    );
  }
}
