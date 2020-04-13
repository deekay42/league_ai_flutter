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

import 'package:fbfunctions/fbfunctions.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:wakelock/wakelock.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../model/item.dart';
import '../model/items_repository.dart';
import '../resources/Strings.dart';
import '../resources/ads.dart';
import '../widgets/items_list.dart';
import '../supplemental/utils.dart';

bool notNull(Object o) => o != null;

class HomePage extends StatefulWidget {
  final bool hasSubscription;
  final bool outOfPredictions;
  final AnimationController mainBodyController;
  final Function updateRemaining;
  final Function updateSubscription;
  HomePage(
      {this.hasSubscription = false,
      this.outOfPredictions = false,
      this.updateRemaining,
      this.updateSubscription,
      this.mainBodyController});

  @override
  _HomePageState createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ItemsRepository itemsRepo = new ItemsRepository();
  List<Item> _items;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  bool outOfPredictions;
  StreamSubscription desktopLastFileStream;

  Ads ads;
  BannerAd ad;

  void initState() {
    super.initState();
    print("Homepage initState");

    outOfPredictions = widget.outOfPredictions;
    if (Platform.isAndroid || Platform.isIOS) {
      initFirebaseMessaging();
      ads = Ads();
      ads.getBannerAd().then((BannerAd newAd) {
        ad = newAd;
        ad.show();
      });
      Wakelock.enable();
      CloudFunctions.instance
          .getHttpsCallable(functionName: 'relayMessage')
          .call(<String, dynamic>{"items": "-100"});
    } 
    else
    {
        initDesktopReadMessage();
        Fbfunctions.fb_call(
            methodName: 'relayMessage',
            args: <String, dynamic>{"items": "-100"});
    }

    
  }

  void didUpdateWidget(HomePage oldWidget)
  {
    super.didUpdateWidget(oldWidget);
    outOfPredictions = widget.outOfPredictions;
    print("In homepage didUpdateWidget");
  }

  Future<void> _playListAnimation() async {
    try {
      widget.mainBodyController.reset();
      await widget.mainBodyController.forward().orCancel;
    } on TickerCanceled {
      // the animation got canceled, probably because we were disposed
    }
  }

  void dispose() {
    print("Disposing of old home state now");
    ad?.dispose();
    if (!Platform.isIOS && !Platform.isAndroid) 
    {
      desktopLastFileStream.cancel();
    }
    else
    {
      Wakelock.disable();
    }
    super.dispose();
  }

  Future<void> _handleNewMessageIncoming(Map<String, dynamic> message) async {
    print("Received new message: $message");
    if (!message.containsKey('data') || !message['data'].containsKey('body'))
      return;
    String content = message['data']['body'];

    print("building new list0: content: $content");
    if(content == "subscribe_success")
      widget.updateSubscription();
    //connectivity test successful
    if(content == "success")
    {
      var mySnack = SnackBar(
                duration: const Duration(seconds: 10),
                content: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Connectivity test successful!", textAlign: TextAlign.center)
                    ]));
      Scaffold.of(context).showSnackBar(mySnack);
      return;
    }
    if(content == "-100")
    {
        print("initial message test successful");
        return;
    }
    if(content != "-1") {
      List<String> itemsS = content.split(",");

      Iterable<Future<Item>> mappedList =
      itemsS.map((i) async => await itemsRepo.getItem(i));
      Future<List<Item>> futureList = Future.wait(mappedList);
      List<Item> items = await futureList;

      print("building new list1  ");
      setState(() {
        _items = items;
        //updateremaining does this
        //outOfPredictions = false;
        print("building new list2");

        if (message['data'].containsKey('remaining'))
          widget.updateRemaining(message['data']['remaining']);
      });
      if (mounted) {
        _playListAnimation();
      }
    }
    else
      setState(() {
        _items = List<Item>();
        if (message['data'].containsKey('remaining'))
          widget.updateRemaining(message['data']['remaining']);
      });

  }

  void initDesktopReadMessage() async {
    print("initDesktopReadMessage");
    String dirPath = Platform.environment['LOCALAPPDATA'] + "\\League IQ";
    String filePath = dirPath + "\\last";

    if (FileSystemEntity.typeSync(filePath) != FileSystemEntityType.notFound) {
      File file = File.fromUri(Uri.file(filePath));
      file.delete();
    }
    Stream<FileSystemEvent> dirStream =
        Directory(dirPath).watch(events: FileSystemEvent.create);

    desktopLastFileStream = dirStream.listen((foo) async {
      if (FileSystemEntity.typeSync(filePath) !=
          FileSystemEntityType.notFound) {
        print("New last file detected!");
        print("mounted is $mounted");
        //apparently creating a new file causes this loop to fire multiple times...
        //need to make sure only one event is processed

        File file = File.fromUri(Uri.file(filePath));
        await waitForFileToFinishLoading(file);
        var contents = await file.readAsString();

        file.delete();

        print("Contents: " + contents);
        final stopwatch = Stopwatch()..start();

        Fbfunctions.fb_call(
            methodName: 'relayMessage',
            args: <String, dynamic>{"items": contents}).then((response) {
            
        print('relayMessage executed in ${stopwatch.elapsed}');
          print("Response status: $response");
          if (response == null) {
            print("relayMessage ERROR");
            var mySnack = SnackBar(
                duration: const Duration(seconds: 10),
                content: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Connection problem", textAlign: TextAlign.center)
                    ]));
            Scaffold.of(context).showSnackBar(mySnack);
            return;
          }
          if (response.startsWith("SUCCESSFUL")) {
            String tmp = response.split(',')[1];
            // means that somebody is subscribed
            if (tmp != "1337")
              widget.updateRemaining(tmp);
            Map<String, dynamic> arg = {
              'data': <String, dynamic>{'body': contents}
            };
            _handleNewMessageIncoming(arg);
          } else if (response == "UID DOES NOT EXIST") {
            setState(() => {});
          } else if (response == "LIMIT REACHED") widget.updateRemaining("0");
        }).catchError((e) {
          print("relayMessage catchError ERROR $e");
        });
      }
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
  }

  Widget _buildInstructions(BuildContext context) {
    int counter = 0;
    ThemeData theme = Theme.of(context);
    List<String> instr;
    if (Platform.isAndroid || Platform.isIOS)
      instr = Strings.instructions;
    else
      instr = Strings.instructionsDesktop;

    return SlidingList(
        title: "INSTRUCTIONS",
        children: instr
            .map((p) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p,
                    textAlign: TextAlign.start,
                    style: theme.textTheme.body1,
                  ),
                  ++counter == instr.length
                      ? null
                      : SizedBox(
                          height: 72,
                        ),
                ].where(notNull).toList()))
            .toList(),
        animationController: widget.mainBodyController,
        origin: Offset(10, 0));
  }

  Widget _buildOutOfPredictions(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child:
              Center(child:

              Text(
                Strings.outOfPredictions,
                textAlign: TextAlign.center,
                style: theme.textTheme.body1,
              )))
            ]);
  }

  Widget build(BuildContext context) {
    // if (errorOccurred)
    //   showDialog(
    //     context: context,
    //     builder: (BuildContext context) {
    //       // return object of type Dialog
    //       return AlertDialog(
    //         title: new Text("Error"),
    //         content: new Text(
    //             "Unable to find user id. Make sure to create an account on the mobile app first. Then redownload and reinstall this desktop app."),
    //         actions: <Widget>[
    //           // usually buttons at the bottom of the dialog
    //           new FlatButton(
    //             child: new Text("Close"),
    //             onPressed: () {
    //               Navigator.of(context).pop();
    //             },
    //           ),
    //         ],
    //       );
    //     },
    //   );
    print("Building home.dart");
    var mainContent;
    if(outOfPredictions)
      return _buildOutOfPredictions(context);
    if (_items == null) {
      print("items are null");
      mainContent = _buildInstructions(context);
    } else {
      int counter = 0;

      var listItems = _items.map((item) {
        return MyItemListItem(item: item, last: ++counter == _items.length);
      }).toList();

      mainContent = SlidingList(
          title: Strings.buildRec,
          children: listItems,
          animationController: widget.mainBodyController);
    }

    return mainContent;

//    return Container(
//        margin: EdgeInsets.symmetric(horizontal: 20), child: mainContent);
  }
}
