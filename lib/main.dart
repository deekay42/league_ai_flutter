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
  runApp(MaterialApp(title: Strings.name, home: MainApp(), theme: _myTheme) );
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
          letterSpacing: 1.1
        ),
        body2: base.body2.copyWith(
          fontWeight: FontWeight.w300,
          fontSize: 14.0,
          color: secondaryText,
          letterSpacing: 1.1
        ),
        subtitle: base.subtitle.copyWith(
            fontWeight: FontWeight.w500, fontSize: 14.0, color: secondaryText, letterSpacing: 1.3),
        overline: base.overline.copyWith(
            fontWeight: FontWeight.w300, fontSize: 13.0, color: secondaryText),
      )
      .apply(fontFamily: 'Roboto'
          );
}
