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

import 'package:flutter/material.dart';
import 'package:Shrine/app.dart';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;

import 'dart:io' show Platform;

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

//class LOL extends StatelessWidget {
//
//  GlobalKey box1 = GlobalKey();
//  GlobalKey box2 = GlobalKey();
//  GlobalKey box3 = GlobalKey();
//
//  @override
//  Widget build(BuildContext context) {
//    return MaterialApp(home:Scaffold(body:Container(key: box1,
//      child: Column(key: box2, children: [
//
//          SizedBox(key:box3,
//            height: 50,
//            child: RaisedButton(child: Text("LOL"),onPressed: (){printSize(box1); printSize(box2); printSize(box3);},)
//          )])
//
//      )));
//  }
//
//
//  void printSize(var key)
//  {
//      final RenderBox renderBoxList = key.currentContext.findRenderObject();
//      final size = renderBoxList.size;
//      print(size);
//  }
//}
