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

import 'dart:async';

import 'package:Shrine/pages/home.dart';
import 'package:Shrine/pages/login.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'resources/Colors.dart';
import 'resources/Strings.dart';

import 'dart:io' show Platform;

class MainApp extends StatefulWidget {
  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  FirebaseUser user;
  StreamSubscription<FirebaseUser> _listener;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  Future<String> _deviceID;


  void initState() {
    super.initState();

    if (Platform.isAndroid || Platform.isIOS) {
      _deviceID = _firebaseMessaging.getToken();

      _listener =
          FirebaseAuth.instance.onAuthStateChanged.listen((
              FirebaseUser result) {
            print("AUTHCHANGE!!");
            print('This is hte user: ');
            print(result.toString());
            setState(() {
              user = result;
              if (result != null) onSignInSuccess();
            });
          });
    }
  }

  void onSignInSuccess() {
    if (user != null) {
      updateDeviceID();
    }
  }

//  void onSignOut() {
//    hasSubscription = false;
//    _remaining = '';
//  }

  void updateDeviceID() async {
    String deviceID = await _deviceID;
    print("Updating deviceID NOW: $deviceID");
    assert(deviceID != null);
    CloudFunctions.instance.call(
        functionName: 'updateDeviceID',
        parameters: <String, dynamic>{"device_id": deviceID});
  }

  @override
  void dispose() {

    _listener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: Strings.name, home: user == null && (Platform.isAndroid || Platform.isIOS) ? LoginPage() : HomePage(), theme: _myTheme);
  }
}

// TODO: Build a Shrine Theme (103)
final ThemeData _myTheme = _buildMyTheme();

ThemeData _buildMyTheme() {
  final ThemeData base = ThemeData.dark();
  return base.copyWith(
//    accentColor: kShrineBrown900,
//    primaryColor: bgDark,
    buttonTheme: base.buttonTheme.copyWith(
      buttonColor: buttonDark,
      textTheme: ButtonTextTheme.normal,
    ),
//    scaffoldBackgroundColor: kShrineBackgroundWhite,
    textSelectionColor: kShrinePink100,
    errorColor: kShrineErrorRed,
    textTheme: _buildShrineTextTheme(base.textTheme),
    primaryTextTheme: _buildShrineTextTheme(base.primaryTextTheme),
    accentTextTheme: _buildShrineTextTheme(base.accentTextTheme),
//    primaryIconTheme: base.iconTheme.copyWith(
//        color: kShrineBrown900
//    ),
  );
}

// TODO: Build a Shrine Text Theme (103)
TextTheme _buildShrineTextTheme(TextTheme base) {
  return base
      .copyWith(
        headline: base.headline
            .copyWith(fontWeight: FontWeight.w500, color: primaryText),
        title: base.title.copyWith(fontSize: 18.0, color: primaryText),
        display1: base.display1.copyWith(
          fontWeight: FontWeight.w200,
          fontSize: 18.0,
          color: primaryText,
        ),
        caption: base.caption.copyWith(
          fontWeight: FontWeight.w300,
          fontSize: 13.0,
          color: primaryText,
        ),
        body1: base.body1.copyWith(
          fontWeight: FontWeight.w100,
          fontSize: 16.0,
          color: primaryText,
        ),
        body2: base.body2.copyWith(
          fontWeight: FontWeight.bold,
          color: primaryText,
        ),
        subtitle: base.subtitle.copyWith(
            fontWeight: FontWeight.w200, fontSize: 14.0, color: secondaryText),
        overline: base.overline.copyWith(
            fontWeight: FontWeight.w100, fontSize: 10.0, color: secondaryText),
      )
      .apply(fontFamily: 'Rubik'
//    bodyColor: kShrineBrown900,
          );
}
