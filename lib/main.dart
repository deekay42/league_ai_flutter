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

import 'resources/Strings.dart';
import 'app.dart';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'resources/Colors.dart';

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
  runApp(MaterialApp(title: Strings.name, home: MainApp(), theme: _myTheme));
  //runApp(MaterialApp(title: "lol", home: Container(child:Text("HI"))));
}

final ThemeData _myTheme = _buildMyTheme();

ThemeData _buildMyTheme() {
  final ThemeData base = ThemeData.dark();
  return base.copyWith(
    buttonTheme: base.buttonTheme.copyWith(
      buttonColor: buttonDark,
      textTheme: ButtonTextTheme.normal,
    ),
    textSelectionColor: kPink100,
    errorColor: kErrorRed,
    textTheme: _buildTextTheme(base.textTheme),
    primaryTextTheme: _buildTextTheme(base.primaryTextTheme),
    accentTextTheme: _buildTextTheme(base.accentTextTheme),
  );
}

TextTheme _buildTextTheme(TextTheme base) {
  return base
      .copyWith(
        headline: base.headline
            .copyWith(fontWeight: FontWeight.w500, color: primaryText),
        title: base.title.copyWith(fontSize: 18.0, color: primaryText),
        display1: base.display1.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 16.0,
          color: primaryText,
        ),
        caption: base.caption.copyWith(
          fontWeight: FontWeight.w300,
          fontSize: 13.0,
          color: primaryText,
        ),
        body1: base.body1.copyWith(
            fontWeight: FontWeight.w300,
            fontSize: 16.0,
            color: primaryText,
            letterSpacing: 1.1),
        body2: base.body2.copyWith(
            fontWeight: FontWeight.w300,
            fontSize: 14.0,
            color: secondaryText,
            letterSpacing: 1.1),
        subtitle: base.subtitle.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 14.0,
            color: secondaryText,
            letterSpacing: 1.3),
        overline: base.overline.copyWith(
            fontWeight: FontWeight.w300, fontSize: 13.0, color: secondaryText),
      )
      .apply(fontFamily: 'Roboto');
}

class Parent extends StatefulWidget {
  @override
  _ParentState createState() => _ParentState();
}

class _ParentState extends State<Parent> {
  int counter = 0;

  void inc() {
    setState(() => ++counter);
  }

  void initState() {
    super.initState();
  }

  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget lol = Center(
      child: Column(
        children: <Widget>[
          Text(counter.toString()),
          SizedBox(height: 55),
          Child(updateParent: inc)
        ],
      ),
    );

    if (counter % 2 == 0) return lol;
    return Container(child: lol);
  }
}

class Child extends StatefulWidget {
  final updateParent;

  Child({this.updateParent});

  @override
  _ChildState createState() => _ChildState();
}

class _ChildState extends State<Child> {
  void initState() {
    super.initState();
    print("Child in initState");
  }

  void dispose() {
    print("Child in dispose");
    super.dispose();
  }

  void didUpdateWidget(Child oldWidget) {
    super.didUpdateWidget(oldWidget);
    print("In child didUpdateWidget");
    print("oldWidget,key is : ${oldWidget.key}");
    print("newWidget.key is : ${widget.key}");
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [RaisedButton(onPressed: widget.updateParent), Child2()]);
  }
}

class Child2 extends StatefulWidget {
  Child2();

  @override
  _Child2State createState() => _Child2State();
}

class _Child2State extends State<Child2> {
  void initState() {
    super.initState();
    print("Child2 in initState");
  }

  void dispose() {
    print("Child2 in dispose");
    super.dispose();
  }

  void didUpdateWidget(Child2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    print("In child2 didUpdateWidget");
    print("oldWidget,key is : ${oldWidget.key}");
    print("newWidget.key is : ${widget.key}");
  }

  @override
  Widget build(BuildContext context) {
    return Text("Child2");
  }
}
