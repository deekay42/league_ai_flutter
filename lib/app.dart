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
import 'dart:io';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:Shrine/pages/home.dart';
import 'package:Shrine/supplemental/utils.dart';
import 'package:Shrine/pages/login.dart';
import 'package:flutter_firebase_ui/flutter_firebase_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fbfunctions/fbfunctions.dart' as fbfunctions;
import 'widgets/appbar.dart';
import 'pages/main_page_template.dart';
import 'dart:math';

import 'pages/QRPage.dart';
import 'resources/Colors.dart';
import 'resources/Strings.dart';
import 'pages/MobilePairingPage.dart';
import 'pages/subscribe.dart';

class AuthException implements Exception {
  String cause;
  AuthException(this.cause);
}

class MainApp extends StatefulWidget {
  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp>  with TickerProviderStateMixin {
  FirebaseUser user;
  StreamSubscription<FirebaseUser> _listener;
  Future<String> desktopUID;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  bool newlyCreatedUser = false;
  bool paired;
  bool hasSubscription;
  String _remaining;
  bool desktopAuthenticated = false;
  String background;

  AnimationController mainController;
  AnimationController mainBodyController;

  void initState() {
    super.initState();
      mainController =
        AnimationController(duration: Duration(milliseconds: 3500), vsync: this);
      mainBodyController =
        AnimationController(duration: Duration(milliseconds: 2500), vsync: this);

      var list = ['assets/lol1.png', 'assets/lol2.png', 'assets/lol3.png', 'assets/lol4.png','assets/lol5.png'];
      final _random = new Random();
      background = list[_random.nextInt(list.length)];  

    _playFullAnimation();
    if (Platform.isAndroid || Platform.isIOS) {
      checkIfUserHasSubscription();
      initFirebaseMessaging();
      Future<String> deviceID = _firebaseMessaging.getToken();
      _listener = FirebaseAuth.instance.onAuthStateChanged
          .listen((FirebaseUser result) {
        print("AUTHCHANGE!!");
        if (result != null &&
            DateTime.now().millisecondsSinceEpoch -
                    result.metadata.creationTimestamp <
                15000) {
          print("User was JUST created");
          print(result?.metadata?.lastSignInTimestamp);
          newlyCreatedUser = true;
        }
        print('This is hte user: ');
        print(result.toString());
        setState(() {
          user = result;
        });
      });
    }
    else
      fbfunctions.fb_call(methodName: 'authenticate')
        .then((result)
        {
          if(result == false) throw AuthException("FATAL: Unable to authenticate user");
          desktopAuthenticated = result;
          checkIfUserHasSubscription();
        });

  }

    Future<void> _playFullAnimation() async {
    try {
      print("play full");
      mainController.reset();
      mainBodyController.reset();
      mainController.forward().orCancel;
      Future.delayed(
       const Duration(seconds: 1),
       (){ _playListAnimation();});
      
    } on TickerCanceled {
      // the animation got canceled, probably because we were disposed
    }
  }

  Future<void> _playListAnimation() async {
    try {
      mainBodyController.reset();
      await mainBodyController.forward().orCancel;
    } on TickerCanceled {
      // the animation got canceled, probably because we were disposed
    }
  }

//  void onSignOut() {
//    hasSubscription = false;
//    _remaining = '';
//  }

  @override
  void dispose() {
    _listener?.cancel();
    mainBodyController.dispose();
    mainController.dispose();
    super.dispose();
  }

  void initFirebaseMessaging() {
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
        _handleNewMessageIncoming(message);
      },
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
        _handleNewMessageIncoming(message);
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
        _handleNewMessageIncoming(message);
      },
    );
    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });
  }

  Future<void> _handleNewMessageIncoming(Map<String, dynamic> message) async {
    //its the pairing confirmation message
    if (message['notification']['title'] == "PAIRING SUCCESSFUL") {
      showDialog<Null>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) => AlertDialog(
              title: Text("Success"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Pairing successful"),
                  SizedBox(
                    height: 15,
                  ),
                  RaisedButton(
                    child: Text("OK"),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
      );

      setState(() {
        paired = true;
      });
      _playFullAnimation();

      return;
    }
  }

  
  void checkIfUserHasSubscription() async {
    dynamic resp;
    if (Platform.isIOS || Platform.isAndroid)
    {
      String deviceID = await _firebaseMessaging.getToken();
      print("Got device_id: $deviceID");
    assert(deviceID != null);
      resp = CloudFunctions.instance
        .call(functionName: 'isValid',
        parameters: <String, dynamic>{"device_id": deviceID});
    }
    else
      resp =  fbfunctions.fb_call(methodName: 'isValid');
        
    resp.then((dynamic result) {
      setState(() {
        

        var parsed = result.split(',');
        if (parsed[1] == "false") paired = false;
        
        if (result.startsWith("true")) {
         
          hasSubscription = true;
        } else {
          hasSubscription = false;
          _remaining = parsed[0];

          // ads.getBannerAd().then((BannerAd newAd) {
          //   ad = newAd;
          //   ad.show();
          // });
        }
        
       
      });
    }).catchError((e) {
      print("isvalid ERROR " + e.error);
      setState(() {
        _remaining = "10";
        // ads.getBannerAd().then((BannerAd newAd) {
        //   ad = newAd;
        //   ad.show();
        // });
      });
    });
  }

  Future<void> listenForUIDFile(String dirPath, String filePath) async {
    //UID not present. need to wait until file appears which contains it.
    Stream<FileSystemEvent> dirStream =
        Directory(dirPath).watch(events: FileSystemEvent.create);
    await for (var value in dirStream) {
      print("Some event!!");
      if (FileSystemEntity.typeSync(filePath) != FileSystemEntityType.notFound)
        setState(() {
          desktopUID = File(filePath).readAsString();
        });
    }
  }

  Future<String> getUIDForDesktop() {
    String dirPath = ".";
    String filePath = dirPath + "/uid";
    if (FileSystemEntity.typeSync(filePath) != FileSystemEntityType.notFound)
      return File(filePath).readAsString();
    else {
      listenForUIDFile(dirPath, filePath);
      return null;
    }
  }

  Future<String> getUIDDBKeyForDesktop() async {
    String dirPath = ".";
    String filePath = dirPath + "/db_key";
    if (FileSystemEntity.typeSync(filePath) != FileSystemEntityType.notFound)
      return await File(filePath).readAsString();
    else
      throw "WAAAAH";
  }

   Widget _myAppBar() {
    var choices = <Choice>[
      // hasSubscription != null && hasSubscription
      //     ? Choice(
      //         title: 'My Account',
              
      //         action: _myaccount)
      //     : null,
      hasSubscription != null && hasSubscription
          ? Choice(
              title: 'Unsubscribe',
              
              action: _unsubscribe)
          : null,
      (Platform.isIOS || Platform.isAndroid) ?
      Choice(
          title: 'Logout', action: signOutProviders) : null
    ].where(notNull).toList();
    return BasicAppBar(false, choices, false);
  }

  
  void _unsubscribe() {
    print('unsubscribe');
    dynamic resp;
    if (Platform.isIOS || Platform.isAndroid)
    {
      resp = CloudFunctions.instance
        .call(functionName: 'cancelSub');
    }
    else
      resp =  fbfunctions.fb_call(methodName: 'cancelSub');

    resp.then((dynamic result) {
      setState(() {
        print("Unsubscribe done: $result");
        if(result is bool) print("It is a bool");
        hasSubscription = false;
        _remaining = "10";
      });
    });
  }

  void _myaccount() {
    print('myaccount');
  }

  Widget buildBody() {
    ThemeData theme = Theme.of(context);
    // isValid hasn't returned yet
    if(paired == null || !desktopAuthenticated)
    {
      print("piared is null");

      //return Container();
      //return MyDialog(modalText:"Loading...", spinner: true);
     
      return Container(           
            child: new Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children:  [
                CircularProgressIndicator(),
                SizedBox(
                  height: 15,
                ),
                Text("Loading...", style: theme.textTheme.body1),
              ],
            ),
          );
    }
    if (Platform.isAndroid || Platform.isIOS) {
        if(paired)
          return HomePage(hasSubscription:hasSubscription, remaining:_remaining, mainBodyController:mainBodyController);
        else
          return MobilePairingPage();
    }
    if (desktopUID != null) {
      print("first");
      return HomePage(hasSubscription:hasSubscription, remaining:_remaining, mainBodyController:mainBodyController);
    }
    desktopUID = getUIDForDesktop();
    if (desktopUID != null) {
      print("second");
      _playListAnimation();
      return HomePage(hasSubscription:hasSubscription, remaining:_remaining, mainBodyController:mainBodyController);
    } else {
      print("third");
      return QRPage(dataString: getUIDDBKeyForDesktop());
    }
  }

  Widget _getFooter(BuildContext context) {
    ThemeData theme = Theme.of(context);
    if (hasSubscription != null && hasSubscription)
      return null;
    else
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              child:
                  Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                _remaining != null ? Text(
                  Strings.remaining.replaceAll("N", _remaining),
                  style: theme.textTheme.overline,
                  maxLines: 1,
                ):Container(),
                SizedBox(height: 8),
                 RaisedButton(
                        child: Text(Strings.sub),
                        onPressed: () async {
                          //print("Here's the ad we're disposing: $ad");
                          
                          await Navigator.of(context).push(
                            
                            MaterialPageRoute(
                                builder: (context) => SubscribePage()),
                          );
                          checkIfUserHasSubscription();
                           _playFullAnimation();
                        },
                      )
                    
              ]),
            )),
      );
  }

  @override
  Widget build(BuildContext context) {
  if (user == null && (Platform.isAndroid || Platform.isIOS))
      return LoginPage();
   else 
   {
    return MainPageTemplateAnimator(
      mainController: mainController,
      appBar: _myAppBar(),
      body: buildBody(),
      mainBodyController: mainBodyController,
      footer: _getFooter(context),
      backdrop: background,
    );
    }
  }
}
