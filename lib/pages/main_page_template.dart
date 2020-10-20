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
  final scaffoldKey;

  MainPageTemplateAnimator(
      {@required AnimationController mainController,
      this.appBar,
      @required this.body,
      AnimationController mainBodyController,
      this.footer,
      @required this.backdrop,
      this.bottomSheet,
      this.scaffoldKey})
      : animationController = MainPageTemplateAnimations(
            controller: mainController,
            mainBodyController: mainBodyController);

  @override
  Widget build(BuildContext context) {
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
                        color: Colors.black.withOpacity(0.3),
                        child: Container(
                            margin:
                                const EdgeInsets.only(left: 20.0, right: 20.0),
                            child: Column(children: [
                              MediaQuery.of(context).size.height > 500 ?
                              Flexible(flex:2, child:
                              Padding(
                                  padding: EdgeInsets.only(top: 15),
                                  child: PoppingLogoAnimation(
                                    child: Image.asset(
                                      'assets/icons/logo.png',
                                      fit: BoxFit.fitHeight,
                                    ),
                                    animation: animationController.logoPop,
                                  ))) : Container(height:10),
                              Flexible( flex:12,

                                child:Align(child:body, alignment:Alignment.center)
                                                            
                              ),
                              Flexible(
                                flex:1,

                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: footer,
                                ),
                              ),
                            ])))
                  ,
                )
                  
              ]             
              
            ));
  }
}

class MainPageTemplateAnimations {
  MainPageTemplateAnimations(
      {@required this.controller, this.mainBodyController})
      : backdropOpacity = new Tween(begin: 1.0, end: 0.7).animate(
          new CurvedAnimation(
            parent: controller,
            curve: Interval(
              0.0,
              1.0,
              curve: Curves.ease,
            ),
          ),
        ),
        backdropBlur = new Tween(begin: 0.0, end: 3.0).animate(
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
