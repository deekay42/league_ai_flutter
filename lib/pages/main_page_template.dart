import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../widgets/logo.dart';

class MainPageTemplateAnimator extends StatelessWidget {
  final Widget body;
  final Widget appBar;
  final Widget footer;
  final String backdrop;
  final MainPageTemplateAnimations animationController;

  MainPageTemplateAnimator(
      {AnimationController mainController,
      @required this.appBar,
      @required this.body,
      AnimationController mainBodyController,
      @required this.footer,
      @required this.backdrop})
      : animationController = MainPageTemplateAnimations(
            controller: mainController,
            mainBodyController: mainBodyController) {
    animationController.logoPop.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        try {
          await animationController.mainBodyController.forward().orCancel;
        } on TickerCanceled {
          // the animation got canceled, probably because we were disposed
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print("Rebuild main page template");
    return Scaffold(appBar: appBar, body: _buildAnimation(context));
  }

  Widget _buildAnimation(BuildContext context) {
    return AnimatedBuilder(
        animation: animationController.controller,
        builder: (BuildContext context, Widget child) => Stack(
              alignment: AlignmentDirectional.topCenter,
              fit: StackFit.expand,
              children: <Widget>[
        Opacity(
          opacity: animationController.backdropOpacity.value,
          child: new Image.asset(
            backdrop,
            fit: BoxFit.cover,
          ),
        ),
        BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: animationController.backdropBlur.value,
            sigmaY: animationController.backdropBlur.value,
          ),
          child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Container(
                  margin: const EdgeInsets.only(left: 20.0, right: 20.0),
                  child: Column(children: [
                    Expanded(
                      child: Container(),
                      flex: 1,
                    ),
                body,
                    Expanded(child: Container(), flex: 2),
                  ]))),
        ),
                Positioned(
                  top: 0,
                  child: Padding(padding: EdgeInsets.only(top: 15), child: PoppingLogoAnimation(
                    child: Image.asset(
                      'assets/ic_launcher_foreground.png',
                      fit: BoxFit.fitHeight,
                    ),
                    animation: animationController.logoPop,
                  )),
                ),
                Container(
                  alignment: Alignment.bottomCenter,
                  margin: const EdgeInsets.only(bottom: 100),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: footer,
                  ),
                )
              ],
            ));
  }
}

class MainPageTemplateAnimations {
  MainPageTemplateAnimations(
      {@required this.controller, @required this.mainBodyController})
      : backdropOpacity = new Tween(begin: 0.5, end: 1.0).animate(
          new CurvedAnimation(
            parent: controller,
            curve: Interval(
              0.25,
              0.75,
              curve: Curves.ease,
            ),
          ),
        ),
        backdropBlur = new Tween(begin: 0.0, end: 5.0).animate(
          new CurvedAnimation(
            parent: controller,
            curve: Interval(
              0.0,
              1.0,
              curve: Curves.ease,
            ),
          ),
        ),
        logoPop = Tween(begin: 0.0, end: 100.0).animate(
          new CurvedAnimation(
            parent: controller,
            curve: new Interval(
              0.0,
              0.5,
              curve: Curves.elasticOut,
            ),
          ),
        );

  final AnimationController controller;
  final AnimationController mainBodyController;
  final Animation<double> backdropOpacity;
  final Animation<double> backdropBlur;
  final Animation<double> logoPop;
}
