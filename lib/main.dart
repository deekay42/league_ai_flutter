// Copyright 2018-present the Flutter authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:io' show Platform;

import 'package:Shrine/app.dart';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';

void _setTargetPlatformForDesktop() {
  TargetPlatform targetPlatform;
  if (Platform.isMacOS) {
    targetPlatform = TargetPlatform.iOS;
  } else if (Platform.isLinux || Platform.isWindows) {
    targetPlatform = TargetPlatform.android;
  }
  if (targetPlatform != null) {
    debugDefaultTargetPlatformOverride = targetPlatform;
  }
}

void main() {  
  _setTargetPlatformForDesktop();
  runApp(MainApp());
}

//class MyClass extends StatefulWidget {
//  @override
//  _MyClassState createState() => _MyClassState();
//}
//
//class _MyClassState extends State<MyClass> with TickerProviderStateMixin {
//  AnimationController controller;
//  Animation<double> logoPop;
//
//  void initState()
//  {
//    super.initState();
//    controller =
//        AnimationController(duration: Duration(milliseconds: 5000), vsync: this);
//    logoPop = Tween(begin: 0.0, end: 100.0).animate(
//      new CurvedAnimation(
//        parent: controller,
//        curve: new Interval(
//          0.0,
//          0.5,
//          curve: Curves.elasticOut,
//        ),
//      ),
//    );
//    controller.forward();
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    return MaterialApp(home:Scaffold(body:Container(
//        child: Center(child: PoppingLogoAnimation(
//          child: Image.asset(
//            'assets/ic_launcher_foreground.png',
//            fit: BoxFit.fitHeight,
//          ),
//          animation: logoPop,
//        ))
//
//    )));
//  }
//}