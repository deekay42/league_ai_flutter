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

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_firebase_ui/flutter_firebase_ui.dart';

class LoginPage extends StatefulWidget {
  LoginPage({Key key}) : super(key: key);

  @override
  _LoginPageState createState() => new _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseUser _currentUser;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    assert(_currentUser == null);
    return new SignInScreen(
      title: "Welcome",
      header: new Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: new Padding(
          padding: const EdgeInsets.all(16.0),
          child: new Text("Demo"),
        ),
      ),
      providers: [
        ProvidersTypes.google,
        ProvidersTypes.facebook,
        ProvidersTypes.twitter,
        ProvidersTypes.email
      ],
      twitterConsumerKey: "AUdn9voKiWbTzAfef4pucVnAk",
      twitterConsumerSecret: "XSb9f9pGBJ3Xm4VM3tUE3Vqamcsug8JEhBi0wqLG1kxWSshnt6",
    );
  }

  void _checkCurrentUser() async {
    _currentUser = await _auth.currentUser();
    _currentUser?.getIdToken(refresh: true);
  }
}
