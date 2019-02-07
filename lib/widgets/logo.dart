import 'package:flutter/material.dart';

class PoppingLogoAnimation extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;

  PoppingLogoAnimation({this.child, this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget child) => Container(
            height: animation.value, width: animation.value, child: child),
        child: child);
  }
}