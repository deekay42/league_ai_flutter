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

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase_ui/flutter_firebase_ui.dart';
import 'package:firebase_admob/firebase_admob.dart';

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
  @override
  _HomePageState createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final ItemsRepository itemsRepo = new ItemsRepository();
  List<Item> _items;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  String _remaining = '';
  bool hasSubscription = false;
  Ads ads = Ads();

  AnimationController mainController;
  AnimationController mainBodyController;

  void checkIfUserHasSubscription() {
    CloudFunctions.instance
        .call(functionName: 'isValid')
        .then((dynamic remaining) {
      setState(() {
        if (remaining == "true") {
          print("user has a subscription");
          hasSubscription = true;
        } else
          _remaining = remaining;
      });
    });
  }

  void initState() {
    super.initState();

    mainController =
      AnimationController(duration: Duration(seconds: 10), vsync: this);
    mainBodyController = AnimationController(duration: Duration(seconds: 10), vsync: this);
    _playFullAnimation();
    initFirebaseMessaging();
    checkIfUserHasSubscription();

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

  void dispose()
  {
    mainBodyController.dispose();
    mainController.dispose();
    super.dispose();
  }

  Future<void> _handleNewMessageIncoming(Map<String, dynamic> message) async {
    List<String> items_s = message['aps']['alert']['body'].split(",");

    Iterable<Future<Item>> mappedList =
        items_s.map((i) async => await itemsRepo.getItem(i));
    Future<List<Item>> futureList = Future.wait(mappedList);
    List<Item> items = await futureList;

    _playListAnimation();
    setState(() {
      _items = items;
    });
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
    Future.delayed(
        const Duration(seconds: 5),
        () => Timer.periodic(
            Duration(seconds: 10),
            (Timer t) => _handleNewMessageIncoming(<String, dynamic>{
                  'aps': <String, dynamic>{
                    'alert': <String, dynamic>{'body': "1,2,3,4,5"}
                  }
                })));
  }

  void _unsubscribe() {
    print('unsubscribe');
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

  Widget _buildInstructions(BuildContext context, AnimationController mainBodyController) {
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
                                height: 36,
                              ),
                      ].where(notNull)
                          .toList())).toList()
              ,animationController: mainBodyController,
          origin: Offset(10, 0));
  }

  Widget _getBody() {
    var mainContent;
    if (_items == null)
      mainContent = Container(child: _buildInstructions(context, mainBodyController));
    else {
      int counter = 0;
      var listItems = _items.map((item) {
        return MyItemListItem(item: item, last: ++counter == _items.length);
      }).toList();

      mainContent = SlidingList(
        title: Strings.buildRec,
        children: listItems,
        animationController: mainBodyController
      );
    }

    return Container(
        margin: EdgeInsets.symmetric(horizontal: 20), child: mainContent);
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
                SizedBox(height: 15),
                RaisedButton(
                  child: Text(Strings.sub),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SubscribePage()),
                    );
                    _playFullAnimation();
                  },
                )
              ]),
            )),
      );
  }

  @override
  Widget build(BuildContext context) {
    print("Rebuild home page");
//    if(!hasSubscription)
//      ads.getBannerAd().then((BannerAd ad){ad.show(
////      anchorOffset: 60.0,
////      // Banner Position
////      anchorType: AnchorType.bottom,
//      );});
    return MainPageTemplateAnimator(
      mainController: mainController,
      appBar: _myAppBar(),
      body: _getBody(),
      mainBodyController: mainBodyController,
      footer: _getFooter(context),
      backdrop: "assets/main_backdrop.png",
    );
  }
}
