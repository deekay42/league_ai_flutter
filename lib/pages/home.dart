import 'dart:async';
import 'dart:io' show Platform;
import 'dart:io';

import 'package:fbfunctions/fbfunctions.dart';
import 'package:firebase_admob/firebase_admob.dart';
//import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:wakelock/wakelock.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  List<Item> _items;
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
//     Future.delayed(Duration(seconds: 10), () {
//       print("Now sending relaymessage");
//       CloudFunctions.instance
//           .getHttpsCallable(functionName: 'relayMessage')
//           .call(<String, dynamic>{"items": "3111,1057,1042,1042"});
// //      _handleNewMessageIncoming({'data':{'body':"3020,3067,1052,1052"}});
//     });
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



  Future<void> _handleNewMessageIncoming(Map<String, dynamic> message) async {
    print("Received new message: $message");
    String content;
    String remaining;
    if(Platform.isIOS) {
      if (!message.containsKey('body'))
        return;
      content = message['body'];
//      if (message['aps']['alert'].containsKey('tag'))
//        remaining = message['aps']['alert']['tag'];
    }
    else// if(Platform.isAndroid || Platform.isWindows)
    {
      if (!message.containsKey('data') || !message['data'].containsKey('body'))
        return;
      content = message['data']['body'];
//      if (message['notification'].containsKey('tag'))
//        remaining = message['notification']['tag'];
    }

//    print("building new list0: content: $content");
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
    if(content != "-1") {
      handleNewItems(content);
    }
    else
      setState(() {
        _items = List<Item>();
//        if (message['aps']['alert'].containsKey('tag'))
//          widget.updateRemaining(message['aps']['alert']['tag']);
      });
  }

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
        var contents = await file.readAsString();

        file.delete();

//        print("Contents: " + contents);
//        final stopwatch = Stopwatch()..start();
        Fbfunctions.fb_call(
                  methodName: 'newRecommendation',
                  args: <String, dynamic>{"items": contents});
        
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
    if(outOfPredictions)
      return _buildOutOfPredictions(context);

    var mainContent;
    if (_items == null) {
//      print("items are null");
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
  }

  void handleNewItems(String content) async
  {
    String remaining;
    List<String> itemsS = content.split(",");

    Iterable<Future<Item>> mappedList =
    itemsS.map((i) async => await itemsRepo.getItem(i));
    Future<List<Item>> futureList = Future.wait(mappedList);
    List<Item> items = await futureList;

//      print("building new list1  ");
    setState(() {
      _items = items;
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
      String itemUpdate = newDoc.document.data["items"];

      if(itemUpdate == "-1")
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

      handleNewItems(itemUpdate);
        
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
