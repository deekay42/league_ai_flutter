import 'dart:async';
import 'dart:ffi';
import 'dart:io' show Platform;
import 'dart:io';
import 'dart:math';
import 'dart:convert';

import 'package:fbfunctions/fbfunctions.dart';
import 'package:firebase_admob/firebase_admob.dart';
//import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:wakelock/wakelock.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/item.dart';
import '../model/items_repository.dart';
import '../model/champion_repository.dart';
import '../model/champion.dart';
import '../model/payload.dart';
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
  final String uid;
  HomePage(
      {this.hasSubscription = false,
      this.outOfPredictions = false,
      this.updateRemaining,
      this.updateSubscription,
      this.mainBodyController,
      this.uid});

  @override
  _HomePageState createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ItemsRepository itemsRepo = new ItemsRepository();
  final ChampionRepository championsRepository = new ChampionRepository();
  Payload payload;
//  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  bool outOfPredictions;
  StreamSubscription desktopLastFileStream;
  bool initialDataSnapshotComplete = false;
  StreamSubscription<QuerySnapshot> itemsListener;

//  Ads ads;
//  BannerAd ad;

  void initState() {
    super.initState();
//    print("Homepage initState");

    outOfPredictions = widget.outOfPredictions;
    if (Platform.isAndroid || Platform.isIOS) {


//      initFirebaseMessaging();
//      ads = Ads();
//      ads.getBannerAd().then((BannerAd newAd) {
//        ad = newAd;
//        ad.show();
//      });

    if(itemsListener == null)
      itemsListener = createItemsListener();

      Wakelock.enable();
//      CloudFunctions.instance
//          .getHttpsCallable(functionName: 'relayMessage')
//          .call(<String, dynamic>{"items": "-1"});
    } 
    else {
      initDesktopReadMessage();
//      Fbfunctions.fb_call(
//          methodName: 'relayMessage',
//          args: <String, dynamic>{"items": "-1"});
    }
//    _firebaseMessaging.getToken().then((token){print("Got device_id: $token");});
//

//    Future.delayed(Duration(seconds: 5), () {
//      print("Now sending relaymessage");
//
//        Map<String, dynamic> payload =
//        { "timestamp": 1234321,
//          "contents": {"items": [3111,1057,1042,1042],
//            "champs": [24,19,498,76,83,69,57,516,412,10],
//            "kills": [5,4,1,2,0,0,0,3,2,1],
//            "deaths": [0,0,1,2,3,0,0,0,1,1],
//            "assists": [5,6,8,1,5,4,1,3,4,2],
//            "levels": [11,11,12,13,5,11,9,12,11,7],
//            "pos": 4,
//            "patch": 10.18,
//            'num_games': 36332
//          }};
//
//      Firestore.instance.collection('users').document(widget.uid).collection('predictions').add(payload);
////      CloudFunctions.instance
////          .getHttpsCallable(functionName: 'relayMessage')
////          .call(payload);
////
//////      _handleNewMessageIncoming({'data':{'body':"3020,3067,1052,1052"}});
//    });
  }

  void didUpdateWidget(HomePage oldWidget)
  {
    super.didUpdateWidget(oldWidget);
    outOfPredictions = widget.outOfPredictions;
//    print("In homepage didUpdateWidget");
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
//    print("Disposing of old home state now");
//    ad?.dispose();
    print("NOW DISPOSING HOME");
    if (!Platform.isIOS && !Platform.isAndroid) 
    {
      desktopLastFileStream.cancel();
    }
    else
    {
      print("itemslistener canceled");
      itemsListener.cancel();
      itemsListener = null;
      Wakelock.disable();
    }
    super.dispose();
  }



//  Future<void> _handleNewMessageIncoming(Map<String, dynamic> message) async {
//    print("Received new message: $message");
//    String content;
//    String remaining;
//    if(Platform.isIOS) {
//      if (!message.containsKey('body'))
//        return;
//      content = message['body'];
////      if (message['aps']['alert'].containsKey('tag'))
////        remaining = message['aps']['alert']['tag'];
//    }
//    else// if(Platform.isAndroid || Platform.isWindows)
//    {
//      if (!message.containsKey('data') || !message['data'].containsKey('body'))
//        return;
//      content = message['data']['body'];
////      if (message['notification'].containsKey('tag'))
////        remaining = message['notification']['tag'];
//    }
//
////    print("building new list0: content: $content");
//    if(content == "subscribe_success")
//      widget.updateSubscription();
//    //connectivity test successful
//    if(content == "success")
//    {
//      var mySnack = SnackBar(
//                duration: const Duration(seconds: 10),
//                content: Row(
//                    mainAxisSize: MainAxisSize.max,
//                    mainAxisAlignment: MainAxisAlignment.center,
//                    children: [
//                      Text("Connectivity test successful!", textAlign: TextAlign.center)
//                    ]));
//      Scaffold.of(context).showSnackBar(mySnack);
//      return;
//    }
//    if(content != "-1") {
//      handleNewItems(content);
//    }
//    else
//      setState(() {
//        payload = null;
////        if (message['aps']['alert'].containsKey('tag'))
////          widget.updateRemaining(message['aps']['alert']['tag']);
//      });
//  }

  void initDesktopReadMessage() async {
//    print("initDesktopReadMessage");
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
//        print("New last file detected!");
//        print("mounted is $mounted");
        //apparently creating a new file causes this loop to fire multiple times...
        //need to make sure only one event is processed

        File file = File.fromUri(Uri.file(filePath));
        await waitForFileToFinishLoading(file);
        String contentsString = await file.readAsString();
        var contents = jsonDecode(contentsString);

        file.delete();

        contents = sanitizeContents(contents);

//        print("Contents: " + contents);
//        final stopwatch = Stopwatch()..start();
        Fbfunctions.fb_call(
                  methodName: 'newRecommendation',
                  args: contents);
        
        handleNewItems(contents);

//        Fbfunctions.fb_call(
//            methodName: 'relayMessage',
//            args: <String, dynamic>{"items": contents}).then((response) {
//
////        print('relayMessage executed in ${stopwatch.elapsed}');
////          print("Response status: $response");
//          if (response == null) {
////            print("relayMessage ERROR");
//            var mySnack = SnackBar(
//                duration: const Duration(seconds: 10),
//                content: Row(
//                    mainAxisSize: MainAxisSize.max,
//                    mainAxisAlignment: MainAxisAlignment.center,
//                    children: [
//                      Text("Connection problem", textAlign: TextAlign.center)
//                    ]));
//            Scaffold.of(context).showSnackBar(mySnack);
//            return;
//          }
//          if (response.startsWith("SUCCESSFUL")) {
//            String tmp = response.split(',')[1];
//            // means that somebody is subscribed
//            if (tmp != "1337")
//              widget.updateRemaining(tmp);
//            handleNewItems(contents);
//            // Map<String, dynamic> arg = {
//            //   'notification': <String, dynamic>{'body': contents}
//            // };
//            // _handleNewMessageIncoming(arg);
//          } else if (response == "UID DOES NOT EXIST") {
//            setState(() => {});
//          } else if (response == "LIMIT REACHED") widget.updateRemaining("0");
//        }).catchError((e) {
//          print("relayMessage catchError ERROR $e");
//        });
      }
    });
  }

//  void initFirebaseMessaging() {
////    print("init firebase messaging in home");
//    _firebaseMessaging.configure(
//      onMessage: (Map<String, dynamic> message) async {
////        print("onMessage: $message");
//        _handleNewMessageIncoming(message);
//      },
//      onLaunch: (Map<String, dynamic> message) async {
////        print("onLaunch: $message");
//        _handleNewMessageIncoming(message);
//      },
//      onResume: (Map<String, dynamic> message) async {
////        print("onResume: $message");
//        _handleNewMessageIncoming(message);
//      },
//    );
//  }

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
                  SizedBox(height:5),
                  Text(
                    p,
                    textAlign: TextAlign.start,
                    style: theme.textTheme.body1,
                  ),
                  SizedBox(height:5),
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
    if(outOfPredictions)
      return _buildOutOfPredictions(context);

    ThemeData theme = Theme.of(context);
    var mainContent;
    if (payload == null) {
//      print("items are null");
      mainContent = _buildInstructions(context);
    } else {
      int counter = 0;

//      var listItems = _items.map((item) {
//        return MyItemListItem(item: item, last: ++counter == _items.length);
//      }).toList();

      bool isMyChamp = false;
//      int currentGold = payload.currentGold;


      List<ChampListItem> champs_list = List<ChampListItem>();
      for(int i=0;i<5;++i) {
        if (i == payload.pos)
          isMyChamp = true;
        champs_list.add(
            ChampListItem(champ1: payload.champs[i],
            champ2: payload.champs[i+5],
            kills1: payload.kills[i],
            kills2: payload.kills[i+5],
            deaths1: payload.deaths[i],
            deaths2: payload.deaths[i+5],
            assists1: payload.assists[i],
            assists2: payload.assists[i+5],
            level1: payload.levels[i],
            level2: payload.levels[i+5],
//            champItems: payload.champItems,
//            currentGold:currentGold,
            isMyChamp: isMyChamp,
            last: ++counter == payload.champs.length/2
        ));
        isMyChamp = false;
      }
      counter = 0;

      var listItems = payload.suggestedItems.map((item) {
        return ItemListItem(item: item, last: ++counter == payload.suggestedItems.length);
      }).toList();

      var champsPlayed = SlidingList(
          scrollDir: Axis.vertical,
          title: "Based on your specific game state:",
          children: champs_list,
          animationController: widget.mainBodyController);

      var itemsSuggested = SlidingList(
          scrollDir: Axis.horizontal,
          title: "The item buy with the highest win rate is:",
          children: listItems,
          showLines:false,
          animationController: widget.mainBodyController);

//      var lol = Image.asset(
//        "assets/item_imgs/1006.png",
//        height: 50,
//        width: 50,
//        fit: BoxFit.contain,
//      );
//      List<Widget> lulz = [lol,lol,lol,lol,lol];




      mainContent = Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Flexible(child:champsPlayed, flex:20),
//        SizedBox(height:10),
        Flexible(child: Container(), flex:1),
      Flexible(child: itemsSuggested, flex:6),
        Flexible(child: Container(), flex:1),
        Flexible(child: Text("${payload.num_games} games analyzed (patch ${payload.patch})", style: theme.textTheme.body2), flex:2),
        Flexible(child: Container(), flex:1),
      ]);

    }
 
    return mainContent;
  }

  void handleNewItems(Map<String, dynamic> content) async
  {
    String remaining;
    List<int> champsList = List<int>.from(content["champs"]);
    List<int> itemsList = List<int>.from(content["items"]);
    Iterable<Future<Champion>> mappedListC =
      champsList.map((i) async => await championsRepository.getChamp(i.toString()));
    Future<List<Champion>> futureListC = Future.wait(mappedListC);
    List<Champion> champs = await futureListC;

    Iterable<Future<Item>> mappedList =
      itemsList.map((i) async => await itemsRepo.getItem(i.toString()));
    Future<List<Item>> futureList = Future.wait(mappedList);
    List<Item> items = await futureList;
print(items.length);
//      print("building new list1  ");
    setState(() {
      print(content);
      payload = Payload(champs: champs, kills: content['kills'], deaths:content['deaths'], assists:content['assists'], levels:content['levels'], pos:content['pos'], suggestedItems: items, patch:content['patch']*1.0, num_games:content['num_games']);

      //updateremaining does this
      //outOfPredictions = false;
//        print("building new list2");

      if (remaining!=null)
        widget.updateRemaining(remaining);
    });
    if (mounted) {
      _playListAnimation();
    }
  }

  Map<String, dynamic> sanitizeContents(Map<String, dynamic> contents)
  {
    int maxLen = 10;
    Map<String, dynamic> result = Map<String, dynamic>();
    for(var elem in ["champs", "kills", "deaths", "assists", "levels", "items"]) {
      if(elem != "items")
        result[elem] = List.filled(maxLen,0);
      if(contents.containsKey(elem)) {
        var givenData = contents[elem];
        if(givenData is Iterable) {
          if(elem == "items")
            result[elem] = List.filled(min(maxLen, contents[elem].length),0);
          for (int i = 0; i < min(maxLen, contents[elem].length); ++i) {
            try {
              result[elem][i] = contents[elem][i] as int;
            }
            on TypeError catch (e) {
              result[elem][i] = 0;
            }
          }
        }
      }
    }

    for(String elem in ["patch", "num_games", "pos"]) {
      result[elem] = 0;
      if (contents.containsKey(elem))
        try {
          if(contents[elem] is int)
            result[elem] = contents[elem] as int;
          else if(contents[elem] is double)
            result[elem] = contents[elem] as double;
          else
            result[elem] = contents[elem] as int;
        }
        on TypeError catch (e) {
          continue;
        }
    }


    return result;
  }

  StreamSubscription<QuerySnapshot> createItemsListener()
  {
    StreamSubscription<QuerySnapshot> streamSub = Firestore.instance.collection('users').document(widget.uid).collection('predictions').snapshots().listen((snapshot)
    {
      if(!initialDataSnapshotComplete)
      {
        print("this was the initial itemslistener INIT");
        print(snapshot.documentChanges[0].document.data);
        initialDataSnapshotComplete = true;
        return;
      }
      print("this was the REAL itemslistener");
      print(snapshot.documentChanges[0].document.data);
      var newDoc = snapshot.documentChanges[0];
      if(newDoc.type != DocumentChangeType.added)
        return;

      int counter = 0;
      var content = newDoc.document.data['contents'];
      content = sanitizeContents(content);
      var itemUpdate = content["items"][0];

      if(itemUpdate == -1)
      {
        // Future.delayed(Duration(seconds: 3), () {
          var mySnack = SnackBar(
              duration: const Duration(seconds: 5),
              content: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Desktop connection established!", textAlign: TextAlign.center)
                  ]));
          Scaffold.of(context).showSnackBar(mySnack);
        // });
        return;
      }

      handleNewItems(content);
        
      });
    return streamSub;
  }

//   Widget createItemsListener()
//   {
//     return StreamBuilder<QuerySnapshot>(
//       stream: Firestore.instance.collection('users').document(widget.uid).collection('predictions').snapshots(),
//       builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
//         if (snapshot.hasError)
//           return new Text('Error: ${snapshot.error}');
//         switch (snapshot.connectionState) {
//           case ConnectionState.waiting:
//             return _buildInstructions(context);
//           default:
//             if(!initialDataSnapshotComplete)
//             {
//               initialDataSnapshotComplete = true;
//               return _buildInstructions(context);
//             }
//             var newDoc = snapshot.data.documentChanges[0];
//             if(newDoc.type != DocumentChangeType.added)
//               return _buildInstructions(context);

//             int counter = 0;
//             String itemUpdate = newDoc.document.data["items"];

//             if(itemUpdate == "-1")
//             {

//               Future.delayed(Duration(seconds: 3), () {
//                 var mySnack = SnackBar(
//                     duration: const Duration(seconds: 10),
//                     content: Row(
//                         mainAxisSize: MainAxisSize.max,
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text("Desktop connection established!", textAlign: TextAlign.center)
//                         ]));
//                 Scaffold.of(context).showSnackBar(mySnack);
//               });
//               return _buildInstructions(context);
//             }

//             List<String> itemsS = itemUpdate.split(",");
//             Iterable<Future<Item>> mappedList =
//             itemsS.map((i) async => await itemsRepo.getItem(i));
//             Future<List<Item>> futureList = Future.wait(mappedList);

//             return FutureBuilder<List<Item>>(
//               future: futureList, // async work
//               builder: (BuildContext context, AsyncSnapshot<List<Item>> snapshot) {
//                 switch (snapshot.connectionState) {
//                   case ConnectionState.waiting: return _buildInstructions(context);
//                   default:
//                     if (snapshot.hasError)
//                       return new Text('Error: ${snapshot.error}');
//                     else {
//                       List<Item> items = snapshot.data;
// //                      if(items[0].id== "0")
// //                        return _buildInstructions(context);
//                       var listItems = items.map((item) {
//                         return MyItemListItem(item: item, last: ++counter == items.length);
//                       }).toList();
// //                      if (remaining!=null)
// //                        widget.updateRemaining(remaining);


//                       if (mounted) {
//                         _playListAnimation();
//                       }
//                       return SlidingList(
//                           title: Strings.buildRec,
//                           children: listItems,
//                           animationController: widget.mainBodyController);
//                     }
//                 }
//               },
//             );


//         }
//       },
//     );
//   }
}
