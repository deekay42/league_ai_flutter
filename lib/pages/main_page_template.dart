import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../widgets/logo.dart';

class MainPageTemplateAnimator extends StatelessWidget {
  final Widget body;
  final Widget appBar;
  final Widget footer;
  final String backdrop;
  final MainPageTemplateAnimations animationController;
  final Widget bottomSheet;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  MainPageTemplateAnimator(
      {@required AnimationController mainController,
      this.appBar,
      @required this.body,
      AnimationController mainBodyController,
      this.footer,
      @required this.backdrop,
      this.bottomSheet})
      : animationController = MainPageTemplateAnimations(
            controller: mainController,
            mainBodyController: mainBodyController);

  @override
  Widget build(BuildContext context) {
    print("Rebuild main page template");
    return Scaffold(
        key: scaffoldKey, appBar: appBar, body: _buildAnimation(context), bottomSheet:bottomSheet);
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
                        color: Colors.black.withOpacity(0.2),
                        child: Container(
                            margin:
                                const EdgeInsets.only(left: 20.0, right: 20.0),
                            child: Column(children: [
                              SizedBox(height:125),
                              Expanded(

                                child:Align(child:body, alignment:Alignment.center)
                                                            
                              ),
                              Container(
                                alignment: Alignment.bottomCenter,
                                margin: const EdgeInsets.only(bottom: 50),
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: footer,
                                ),
                              ),
                            ])))
                  ,
                ),
                Positioned( top:0.0, height:125.0,
                    child: Padding(
                          padding: EdgeInsets.only(top: 15),
                          child: PoppingLogoAnimation(
                            child: Image.asset(
                              'assets/logo.png',
                              fit: BoxFit.fitHeight,
                            ),
                            animation: animationController.logoPop,
                          )))
                  
              ]             
              
            ));
  }
}

class MainPageTemplateAnimations {
  MainPageTemplateAnimations(
      {@required this.controller, this.mainBodyController})
      : backdropOpacity = new Tween(begin: 1.0, end: 0.2).animate(
          new CurvedAnimation(
            parent: controller,
            curve: Interval(
              0.0,
              1.0,
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
        logoPop = Tween(begin: 0.0, end: 1.0).animate(
          new CurvedAnimation(
            parent: controller,
            curve: new Interval(
              0.4,
              0.7,
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
