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
import 'dart:io' show Platform;
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase_ui/flutter_firebase_ui.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:qrcode_reader/qrcode_reader.dart';

import '../model/item.dart';
import '../model/items_repository.dart';
import '../pages/main_page_template.dart';
import '../pages/subscribe.dart';
import '../resources/Strings.dart';
import '../widgets/appbar.dart';
import '../widgets/items_list.dart';
import '../resources/ads.dart';

bool notNull(Object o) => o != null;

class HomePage extends StatefulWidget {
  final Future<String> desktopUID;
  HomePage({this.desktopUID});

  @override
  _HomePageState createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final ItemsRepository itemsRepo = new ItemsRepository();
  List<Item> _items;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  String _remaining = '';
  bool hasSubscription = false;
  bool paired = true;
  Ads ads;
  BannerAd ad;
  Future<String> desktopUID;
  bool errorOccurred = false;

  AnimationController mainController;
  AnimationController mainBodyController;

  void checkIfUserHasSubscription() {


    CloudFunctions.instance
        .call(functionName: 'isValid')
        .then((dynamic remaining) {
      setState(() {
        paired = remaining.split(',')[1];
        if (remaining.startsWith("true")) {
          print("user has a subscription");
          hasSubscription = true;
        } else {
          hasSubscription = false;
          _remaining = remaining;

          ads.getBannerAd().then((BannerAd newAd) {
            ad = newAd;
            ad.show();
          });
        }
      });
    }).catchError((e) {

      setState(() {
        _remaining = "10";
        ads.getBannerAd().then((BannerAd newAd) {
          ad = newAd;
          ad.show();
        });
      });
    });
  }

  void initState() {
    super.initState();
    print("Calling initstate now");
    
    mainController =
        AnimationController(duration: Duration(seconds: 10), vsync: this);
    mainBodyController =
        AnimationController(duration: Duration(seconds: 10), vsync: this);

    if (Platform.isAndroid || Platform.isIOS)
    {
      initFirebaseMessaging();
      ads = Ads();
    }
    else
      initDesktopReadMessage();

    onReload();
  }

  Future<void> _playFullAnimation() async {
    try {
      mainController.reset();
      mainBodyController.reset();
      await mainController.forward().orCancel;
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

  void dispose() {
    mainBodyController.dispose();
    mainController.dispose();
    ad?.dispose();
    super.dispose();
  }

  Future<void> _handleNewMessageIncoming(Map<String, dynamic> message) async {

    String content = message['aps']['alert']['body'];
    //its the pairing confirmation message
    if(message == "PAIRING SUCCESSFUL")
    {  
      setState((){paired = true;});
      return;
    }

    //its a new build recommendation
    List<String> itemsS = content.split(",");

    Iterable<Future<Item>> mappedList =
        itemsS.map((i) async => await itemsRepo.getItem(i));
    Future<List<Item>> futureList = Future.wait(mappedList);
    List<Item> items = await futureList;

    _items = items;
    if (mounted) {
      setState(() {});
      _playListAnimation();
    }
  }


  void initDesktopReadMessage() async
  {
    String dirPath = ".";
    String filePath = dirPath+"/last";
    if(FileSystemEntity.typeSync(filePath) != FileSystemEntityType.notFound)
    {
      File file = File.fromUri(Uri.file(filePath));
      file.delete();
    }

    Stream<FileSystemEvent> dirStream = Directory(dirPath).watch(events: FileSystemEvent.create);
    await for (var value in dirStream) {
      print("Some event!!");
      if(FileSystemEntity.typeSync(filePath) != FileSystemEntityType.notFound)
      {
        File file = File.fromUri(Uri.file(filePath));
        var contents = await File(filePath).readAsString();
        file.delete();
        
        print("Contents: "+contents);

        var url = "https://us-central1-neuralleague.cloudfunctions.net/relayMessage";
        var body = {"uid": await widget.desktopUID, "items":contents};
        http.post(url, body: body)
            .then((response) {
          print("Response status: ${response.statusCode}");
          print("Response body: ${response.body}");

          if(response.body.startsWith("SUCCESSFUL"))
          {
            _remaining = response.body.split(',')[1];
            // means that somebody is subscribed
            if(_remaining == "1337")
              hasSubscription = true;
            Map<String, dynamic> arg = {
                    'aps': <String, dynamic>{
                      'alert': <String, dynamic>{'body': contents}
                    }
                  };
            _handleNewMessageIncoming(arg); 
          }
          else if(response.body == "UID DOES NOT EXIST")
          {
            setState(() => {});
          }
        });  
      } 
    
    }
    
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
    print("FCM configured!");
//    Future.delayed(
//        const Duration(seconds: 5),
//        () => Timer.periodic(
//            Duration(seconds: 10),
//            (Timer t) => _handleNewMessageIncoming(<String, dynamic>{
//                  'aps': <String, dynamic>{
//                    'alert': <String, dynamic>{'body': "1,2,3,4,5,6,7,8"}
//                  }
//                })));
  }

  void _unsubscribe() {
    print('unsubscribe');
    CloudFunctions.instance
        .call(functionName: 'cancelSub')
        .then((dynamic result) {
      setState(() {
        hasSubscription = false;
        _remaining = "10";
        onReload();
      });
    });
  }

  void _myaccount() {
    print('myaccount');
  }

  Widget _myAppBar() {
    var choices = <Choice>[
      hasSubscription
          ? Choice(
              title: 'My Account',
              icon: Icons.directions_boat,
              action: _myaccount)
          : null,
      hasSubscription
          ? Choice(
              title: 'Unsubscribe',
              icon: Icons.directions_bike,
              action: _unsubscribe)
          : null,
      Choice(
          title: 'Logout', icon: Icons.directions_car, action: signOutProviders)
    ].where(notNull).toList();
    return BasicAppBar(false, choices);
  }

  Widget _buildInstructions(
      BuildContext context, AnimationController mainBodyController) {
    int counter = 0;
    ThemeData theme = Theme.of(context);

    print("Now building slidinglist");
    return SlidingList(
        title: "Instructions",
        children: Strings.instructions
            .map((p) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p,
                    textAlign: TextAlign.start,
                    style: theme.textTheme.body1,
                  ),
                  ++counter == Strings.instructions.length
                      ? null
                      : SizedBox(
                          height: 64,
                        ),
                ].where(notNull).toList()))
            .toList(),
        animationController: mainBodyController,
        origin: Offset(10, 0));
  }

  Widget _getBody(BuildContext context) {
    if(errorOccurred)
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Error"),
          content: new Text("Unable to find user id. Make sure to create an account on the mobile app first. Then redownload and reinstall this desktop app."),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
    var mainContent;
    if (_items == null)
      mainContent =
          Container(child: _buildInstructions(context, mainBodyController));
    else {
      int counter = 0;
      var listItems = _items.map((item) {
        return MyItemListItem(item: item, last: ++counter == _items.length);
      }).toList();

      mainContent = SlidingList(
          title: Strings.buildRec,
          children: listItems,
          animationController: mainBodyController);
    }

    return mainContent;

//    return Container(
//        margin: EdgeInsets.symmetric(horizontal: 20), child: mainContent);
  }

  Widget _getFooter(BuildContext context) {
    ThemeData theme = Theme.of(context);
    if (hasSubscription)
      return null;
    else
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              child:
                  Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text(
                  Strings.remaining.replaceAll("N", _remaining),
                  style: theme.textTheme.subtitle,
                  maxLines: 1,
                ),
                SizedBox(height: 8),
                (Platform.isAndroid || Platform.isIOS) ?
                RaisedButton(
                  child: Text(Strings.sub),
                  onPressed: () async {
                    print("Here's the ad we're disposing: $ad");
                    ad?.dispose();
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SubscribePage()),
                    );
                    onReload();
                  },
                ) : Container()
              ]),
            )),
      );
  }

  void onReload() {
    _playFullAnimation();
    if(Platform.isAndroid || Platform.isIOS)
      checkIfUserHasSubscription();
  }

  Widget buildHomePage()
  {
    

return MainPageTemplateAnimator(
      mainController: mainController,
      appBar: (Platform.isAndroid || Platform.isIOS) ? _myAppBar() : null,
      body: _getBody(context),
      mainBodyController: mainBodyController,
      footer: _getFooter(context),
      backdrop: "assets/main_backdrop.png",
    );

          
  }

  Widget getPairingPageContent()
  {
    return Column(children:[Text(Strings.pairingInstructions),
    RaisedButton(child:Text("Pair Now"), 
      onPressed: () async 
      {
        String realtimeDBID = await QRCodeReader()
                .setAutoFocusIntervalInMs(200)
                .setForceAutoFocus(true)
                .setTorchEnabled(true)
                .setHandlePermissions(true)
                .setExecuteAfterPermissionGranted(true)
                .scan();

        print("Obtained the realtimeDBID: "+realtimeDBID);
        
        CloudFunctions.instance.call(
          functionName: 'passUIDtoDesktop',
          parameters: <String, dynamic>{
            'realtimeDBID': realtimeDBID,
          },  
        );
      }
    )]);
  }

  Widget buildPairingPage()
  {

return MainPageTemplateAnimator(
      mainController: mainController,
      appBar:  _myAppBar(),
      body: getPairingPageContent(),
      mainBodyController: null,
      footer: _getFooter(context),
      backdrop: "assets/main_backdrop.png",
    );

    
  }

  @override
  Widget build(BuildContext context) {
    print("Rebuild home page");
    if(paired)
      return buildHomePage();
    else
      return buildPairingPage();
  }
}
