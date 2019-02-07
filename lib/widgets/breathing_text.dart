import 'package:flutter/material.dart';

class BreathingText extends StatefulWidget {
  final String text;

  BreathingText({this.text});

  @override
  BreathingTextState createState() => BreathingTextState();
}

class BreathingTextState extends State<BreathingText>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> animation;

  @override
  void initState() {
    _controller = AnimationController(
        duration: const Duration(milliseconds: 1500), vsync: this);

    animation = Tween(begin: 12.0, end: 14.0).animate(
      new CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ),
    );

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _controller.forward();
      }
    });

    _controller.forward();

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget child) => Text(
              widget.text,

              style: TextStyle(
                  fontSize: animation.value, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
            ));
  }
}
