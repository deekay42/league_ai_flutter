import 'package:flutter/material.dart';

class PoppingLogoAnimation extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;

  PoppingLogoAnimation({this.child, this.animation});

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: animation, child: Container(child: child),);
  }
}