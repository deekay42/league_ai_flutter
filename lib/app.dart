import 'dart:async';
import 'dart:io';
import 'dart:io' show Platform;
import 'dart:math';

import 'pages/home.dart';
import 'pages/login.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fbfunctions/fbfunctions.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase_ui/flutter_firebase_ui.dart';
import 'package:launchbrowser/launchbrowser.dart' as launchbrowser;
//import 'package:notification_permissions/notification_permissions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'pages/MobilePairingPage.dart';
import 'pages/QRPage.dart';
import 'pages/main_page_template.dart';
// import 'pages/subscribe.dart';
import 'resources/Strings.dart';
import 'widgets/appbar.dart';
import 'supplemental/utils.dart';

enum DesktopAuthState { AUTHENTICATED, WAITING, AUTHERROR }

class AuthException implements Exception {
  String cause;

  AuthException(this.cause);
}

class MainApp extends StatefulWidget {
  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with TickerProviderStateMixin, WidgetsBindingObserver {
  FirebaseUser user;
  StreamSubscription<FirebaseUser> _listener;
  Future<String> desktopUIDFuture;
  String desktopUID;
//  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  bool newlyCreatedUser = false;
  bool paired;
  bool hasSubscription;
  String _remaining;
  DesktopAuthState desktopAuthenticated = DesktopAuthState.WAITING;
  String background;
  bool aiLoaded = false;
  bool waitingOnIsValid = false;
  bool inviteCodeValid = true;
  bool waitingOnInviteCodeCheck = false;
  bool outOfPredictions = false;
  GlobalKey<ScaffoldState> homePageScaffoldKey = GlobalKey<ScaffoldState>();
  AnimationController mainController;
  AnimationController mainBodyController;
  StreamSubscription desktopUIDListener;
  StreamSubscription aiListener;
  String permissionStatus;
  StreamSubscription<DocumentSnapshot> pairedListener;
  bool initialPairedFired = false;

  var permGranted = "granted";
  var permDenied = "denied";
  var permUnknown = "unknown";

  void initState() {
    super.initState();

    mainController = AnimationController(
        duration: Duration(milliseconds: 15500), vsync: this);
    mainBodyController = AnimationController(
        duration: Duration(milliseconds: 1500), vsync: this);

    var list = [
      'assets/imgs/1.png'
    ];
    final _random = new Random();
    background = list[_random.nextInt(list.length)];

    _playFullAnimation();
    if (Platform.isAndroid || Platform.isIOS) {


      checkIfUserHasSubscription();
//      initFirebaseMessaging();


      _listener = FirebaseAuth.instance.onAuthStateChanged
          .listen((FirebaseUser result) {
//        print("AUTHCHANGE!!");
        if (result != null &&
            DateTime.now().millisecondsSinceEpoch -
                    result.metadata.creationTime.millisecondsSinceEpoch <
                15000) {
//          print("User was JUST created");
//          print(result?.metadata?.lastSignInTime.millisecondsSinceEpoch);
          newlyCreatedUser = true;
        }
//        print('This is the user: ');
//        print(result.toString());
        setState(() {
          user = result;
        });
        if (user != null) {
//          initFirebaseMessaging();
          checkIfUserHasSubscription();


          pairedListener = Firestore.instance
              .collection('users')
              .document(user.uid)
              .snapshots()
              .listen((DocumentSnapshot documentSnapshot) {
            print("new paired activity");
            if(!initialPairedFired) {
              initialPairedFired = true;
              print("this was the initial");
              return;
            }

//            if(paired)
//            {
//              pairedListener.cancel();
//              return;
//            }
            bool isPaired = documentSnapshot.data["paired"];
            if( !(isPaired==null) && isPaired)
              setPairedToTrue();
            else
              setState(() {
                paired = false;
              });
          });

        }
        else
        {
          print("canceling pairedListener");
          pairedListener?.cancel();
          initialPairedFired = false;
        }
      });
    } else
      desktopAuthenticate();

    if (!Platform.isAndroid && !Platform.isIOS) {
      waitForAIToLoad();
//      hasValidInviteCodeSavedDesktop();
    }
  }


  Future<void> desktopAuthenticate({int timeout = 0, attempt = 0}) async {
    if(attempt == 4)
      desktopSignout();
    var result = await Fbfunctions.fb_call(methodName: 'authenticate');
    if (result == "unsuccessful") {
//      print("Auth unsuccessful. Trying again in $timeout seconds");
      //retry
      Future.delayed(Duration(seconds: timeout), () {
        desktopAuthenticate(timeout: 8, attempt: attempt + 1);
      });
    } else if (result == "files_missing") {
      setState(() {
        desktopAuthenticated = DesktopAuthState.AUTHERROR;
      });
//      print(
//          "Unable to authenticate user. Probably because uid and/or secret files are missing.");
    } else if (result == "successful") {
      setState(() {
        desktopAuthenticated = DesktopAuthState.AUTHENTICATED;
      });
      checkIfUserHasSubscription();
    }
  }

  Future<void> _playFullAnimation() async {
    try {
//      print("play full animation");
      mainController.reset();
      mainBodyController.reset();
      mainController.forward().orCancel;
      Future.delayed(const Duration(seconds: 1), () {
        _playListAnimation();
      });
    } on TickerCanceled {
      // the animation got canceled, probably because we were disposed
    }
  }

  Future<void> _playListAnimation() async {
    try {
//      print("play list animation");
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
    aiListener?.cancel();
    desktopUIDListener?.cancel();
    mainBodyController.dispose();
    mainController.dispose();
    super.dispose();
  }

  void updateRemaining(String remaining) {
    setState((){
      if(_remaining == "0" && remaining =="0") outOfPredictions = true;
      else outOfPredictions = false;
      _remaining = remaining;
    });
  }

//  void initFirebaseMessaging() {
////    print("init fb messaging in app");
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
//    getCheckNotificationPermStatus();
//    WidgetsBinding.instance.addObserver(this);
//    _firebaseMessaging.requestNotificationPermissions(
//        const IosNotificationSettings(sound: true, badge: true, alert: true));
////    _firebaseMessaging.onIosSettingsRegistered
////        .listen((IosNotificationSettings settings) {
//////      print("Settings registered: $settings");
////    });
//  }

//  /// When the application has a resumed status, check for the permission
//  /// status
//  @override
//  void didChangeAppLifecycleState(AppLifecycleState state) {
//    if (state == AppLifecycleState.resumed) {
//      setState(() {
//        getCheckNotificationPermStatus();
//      });
//    }
//  }

//  /// Checks the notification permission status
//  Future<void> getCheckNotificationPermStatus() {
//    return NotificationPermissions.getNotificationPermissionStatus()
//        .then((status) {
//      setState(() {
//        switch (status) {
//          case PermissionStatus.denied:
//            permissionStatus = permDenied;
//            break;
//          case PermissionStatus.granted:
//            permissionStatus = permGranted;
//            break;
//          case PermissionStatus.unknown:
//          default:
//            permissionStatus = permUnknown;
//        }
//
//      });
//
//    });
//  }

//  Future<void> _handleNewMessageIncoming(Map<String, dynamic> message) async {
////    print("got a message whoop whoop");
////    print(message);
//    String content;
//    if(Platform.isIOS) {
//      content = message['aps']['alert']['title'];
//    }
//    else if(Platform.isAndroid)
//    {
//      content = message['notification']['title'];
//    }
////    print(message);
//    //its the pairing confirmation message
//    if (content == "PAIRING SUCCESSFUL") {
//      showDialog<Null>(
//        context: context,
//        barrierDismissible: false, // user must tap button!
//        builder: (BuildContext context) => AlertDialog(
//          title: Text("Success"),
//          content: Column(
//            mainAxisSize: MainAxisSize.min,
//            children: [
//              Text("Pairing successful"),
//              SizedBox(
//                height: 15,
//              ),
//              RaisedButton(
//                child: Text("OK"),
//                onPressed: () {
//                  Navigator.pop(context);
//                  Navigator.pop(context);
//                  _playListAnimation();
//                },
//              ),
//            ],
//          ),
//        ),
//      );
//
//      setState(() {
//        paired = true;
//      });
//      _playFullAnimation();
//
//      return;
//    }
//  }

  void checkIfUserHasSubscription({int timeout = 0}) async {
//    print("Starting isValid");
    if (waitingOnIsValid || ((Platform.isIOS || Platform.isAndroid) && user == null)) {return;}
    setState(() {
      waitingOnIsValid = true;
    });
    dynamic resp;
    if (Platform.isIOS || Platform.isAndroid) {
//      String deviceID = await _firebaseMessaging.getToken();
//      print("Got device_id: $deviceID");
//      assert(deviceID != null);
      resp = CloudFunctions.instance
          .getHttpsCallable(functionName: 'isValid')
          .call(<String, dynamic>{
//        "device_id": deviceID,
        "current_version": Strings.version
      });
    } else
      resp = Fbfunctions.fb_call(
          methodName: 'isValid',
          args: <String, dynamic>{"current_version": Strings.version});

    resp.then((dynamic result) {
      if (Platform.isIOS || Platform.isAndroid) result = result.data;
     print("ISVALID: Got the result: $result");
      setState(() {
        if (result["paired"] == "true")
          paired = true;
        else
        {
          paired = false;
          if(!(Platform.isIOS || Platform.isAndroid))
            desktopSignout();

        }

        if (result["subscribed"] == "true")
        {
          hasSubscription = true;
          outOfPredictions = false;
        }
        else {
          hasSubscription = false;
          _remaining = result["remaining"];
          outOfPredictions = _remaining == "0";
        }
        waitingOnIsValid = false;
      });
      if (!Platform.isIOS && !Platform.isAndroid) if (result.containsKey(
          "latest_version")) promptUpdate(result["latest_version"]);
      _playListAnimation();
    }).catchError((e) {
      waitingOnIsValid = false;
      print("isvalid ERROR $e");
      print(e.message);
      print("Retrying in $timeout");
      Future.delayed(Duration(seconds: timeout), () {
        print("Retrying now");
        checkIfUserHasSubscription(timeout: 8);
      });
    });
  }

  void listenForUIDFile(String dirPath, String filePath) async {
    //UID not present. need to wait until file appears which contains it.
    print("in listenforuidfile");
    if (desktopUIDListener != null) return;
    Stream<FileSystemEvent> dirStream =
        Directory(dirPath).watch(events: FileSystemEvent.all);
    print("uid listener commenced");

    desktopUIDListener ??= dirStream.listen((event) async {
      if(filePath != event.path)
        return;
      if (FileSystemEntity.typeSync(filePath) != FileSystemEntityType.notFound) {
        print("File created: $filePath ${event.path}");
        if (desktopUIDFuture != null || filePath != event.path) return;

        File file = File.fromUri(Uri.file(filePath));
        await waitForFileToFinishLoading(file);

        await desktopAuthenticate();
        if (desktopAuthenticated == DesktopAuthState.AUTHENTICATED)
          // Fbfunctions.fb_call(methodName: 'completePairing');
          print("auth successfull");
        else
          throw AuthException(
              "FATAL: Unable to authenticate user. files are still missing");
        setState(() {
          desktopUIDFuture = file.readAsString();
          desktopUIDFuture.then((result){setState(() {desktopUID = result; });} );
        });
//        hasValidInviteCodeSavedDesktop();
      }
      else
      {
        
        print("File deleted: $filePath ${event.path}");
        desktopSignout();
      }
    
    });
  }

  Future<void> hasValidInviteCodeSavedDesktop() async {
    setState(() {
      waitingOnInviteCodeCheck = true;
    });
    String dirPath = Platform.environment['LOCALAPPDATA'] + "\\League AI";
    String inviteCodeFilePath = dirPath + "\\inviteCode";
    String uidFilePath = dirPath + "\\uid";
    if (FileSystemEntity.typeSync(inviteCodeFilePath) !=
            FileSystemEntityType.notFound &&
        FileSystemEntity.typeSync(uidFilePath) !=
            FileSystemEntityType.notFound) {
      File inviteCodeFile = File.fromUri(Uri.file(inviteCodeFilePath));
      File uidFile = File.fromUri(Uri.file(uidFilePath));
      await waitForFileToFinishLoading(inviteCodeFile);
      await waitForFileToFinishLoading(uidFile);
      String inviteCode = await inviteCodeFile.readAsString();
      String uid = await uidFile.readAsString();
      await Fbfunctions.fb_call(
          methodName: 'getInviteCode',
          args: <String, dynamic>{
            "invite_code": inviteCode,
            "uid": uid
          }).then((result) {
        setState(() {
          inviteCodeValid = result;
        });
      });
    }
    setState(() {
//      print("invite check complete");
      waitingOnInviteCodeCheck = false;
    });
  }

  Future<String> getUIDForDesktop() {
    print("in getuidfordesktop");
    String dirPath = Platform.environment['LOCALAPPDATA'] + "\\League AI";
    String filePath = dirPath + "\\uid";
    listenForUIDFile(dirPath, filePath);
//    print("dirPath: $dirPath filePath: $filePath");
    if (FileSystemEntity.typeSync(filePath) != FileSystemEntityType.notFound)
    {
      print("uid file present!d");
      var future =  File(filePath).readAsString();
      future.then((result){setState(() {desktopUID = result; });} );
      return future;
    }
    else {
      print("uid file not present");
      return null;
    }
  }

  Future<String> getUIDDBKeyForDesktop() async {
    String dirPath = Platform.environment['LOCALAPPDATA'] + "\\League AI";
    String filePath = dirPath + "\\db_key";
    while(FileSystemEntity.typeSync(filePath) == FileSystemEntityType.notFound)
        await Future.delayed(const Duration(seconds: 1)); 
    String result = await File(filePath).readAsString();
    return result;
  }

  Widget _myAppBar() {
    var choices;

    if (Platform.isIOS || Platform.isAndroid)
      choices = <Choice>[

        Choice(title: 'Pair with Computer', action: resetPairingPhone),
        // Choice(title: 'Version ' + Strings.version),
        Choice(title: 'Logout', action: FirebaseAuth.instance.signOut)

      ].where(notNull).toList();
    else
      choices = <Choice>[
        Choice(title: 'Pair New Phone', action: resetPairingDesktop)
      ].where(notNull).toList();

    return BasicAppBar(false, choices, false);
  }

  Future<void> resetPairingPhone() async
  {
    if(user == null)
      return;

    CloudFunctions.instance.getHttpsCallable(functionName: 'unpair').call();

    setState(() {
        paired = false;
      });
    
  }



  Future<void> resetPairingDesktop() async
  {

//    String dirPath = Platform.environment['LOCALAPPDATA'] + "\\League AI";
//    for(String path in ["\\uid", "\\secret"])
//    {
//
//      String filePath = dirPath + path;
//      if (FileSystemEntity.typeSync(filePath) !=
//            FileSystemEntityType.notFound)
//          await File.fromUri(Uri.file(filePath)).delete();
//    }
    if(desktopUID == null)
    {
      print("desktopuid is NULL");
          return;
    }
    print("desktopuid is NOT NULL");
    await Fbfunctions.fb_call(methodName: 'unpair');
    // desktopSignout();
  }

  void desktopSignout()
  {
    setState(() {
        desktopAuthenticated = DesktopAuthState.AUTHERROR;
        desktopUID = null;
        desktopUIDFuture = null;
      });


    Fbfunctions.fb_call(methodName: 'signout');
  }

  

  void _unsubscribe() {
//    print('unsubscribe');
    dynamic resp;
    if (Platform.isIOS || Platform.isAndroid) {
      resp =
          CloudFunctions.instance.getHttpsCallable(functionName: 'cancelSub').call();
    } else
      resp = Fbfunctions.fb_call(methodName: 'cancelSub');

    resp.then((dynamic result) {
      if (Platform.isIOS || Platform.isAndroid)
        result = result.data;
      setState(() {
//        print("Unsubscribe done: $result");
//        if (result is bool) print("It is a bool");
        hasSubscription = false;
      });
      checkIfUserHasSubscription();
    });
  }

  void promptUpdate(String updateURL) async {
    if (updateURL != null)
      showDialog<Null>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) => AlertDialog(
            title: Text("Update Available"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // CircularProgressIndicator(),
                // SizedBox(height: 15,),
                Text(
                    "A new update is available. To receive the best builds for the newest patch, please download the latest update."),
              ],
            ),
            actions: <Widget>[
              RaisedButton(
                  onPressed: () {
                    launchbrowser.launchbrowser(updateURL);
                    Navigator.pop(context);
                  },
                  child: Text("Download Now")),
              FlatButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("Not now"))
            ]),
      );
  }

  void waitForAIToLoad() async {
    String dirPath = Platform.environment['LOCALAPPDATA'] + "\\League AI";
    String filePath = dirPath + "\\ai_loaded";

    Stream<FileSystemEvent> dirStream =
        Directory(dirPath).watch(events: FileSystemEvent.create);

    if (aiListener != null) return;

    aiListener = dirStream.listen((event) async {
      if (aiLoaded || event.path != filePath) return;
//      print("Ai Loaded?!");
      if (FileSystemEntity.typeSync(filePath) !=
          FileSystemEntityType.notFound) {
//        print("Ai Loaded!!");
        File file = File.fromUri(Uri.file(filePath));
        file.delete();
        setState(() {
          aiLoaded = true;
          aiListener.cancel();
        });
      }
    });
  }

  Widget buildBody() {
    ThemeData theme = Theme.of(context);
//    print(
//        "waitingOnIsValid is $waitingOnIsValid, desktopauth is $desktopAuthenticated, waitingOnInviteCodeCheck is $waitingOnInviteCodeCheck");
    if (waitingOnIsValid ||
        (!(Platform.isIOS || Platform.isAndroid) &&
            (desktopAuthenticated == DesktopAuthState.WAITING ||
                waitingOnInviteCodeCheck))) {
//      print("piared is null");

      //return Container();
      //return MyDialog(modalText:"Loading...", spinner: true);



      return Stack(children:[Container(color:Colors.black.withOpacity(0.85)), Center(
        child: new Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(
              height: 15,
            ),
            Text("Loading user profile...", style: theme.textTheme.body1),
          ],
        ),
      )]);
    }

    if (Platform.isAndroid || Platform.isIOS) {
      if (paired == null || paired) {

        return HomePage(
            hasSubscription: hasSubscription,
            outOfPredictions: outOfPredictions,
            updateRemaining: updateRemaining,
            updateSubscription: checkIfUserHasSubscription,
            mainBodyController: mainBodyController,
            uid: user.uid,
          tickerProvider:this);
      }
      else {
        return MobilePairingPage(setPairedToTrue: setPairedToTrue);
      }
    }
    else
    {

      desktopUIDFuture ??= getUIDForDesktop();
      if (desktopUID != null && paired) {
        if (!inviteCodeValid) return _getInviteCodeWidget(context);
  //      print("rendering homepage");
        return HomePage(
            hasSubscription: hasSubscription,
            outOfPredictions: outOfPredictions,
            updateRemaining: updateRemaining,
            updateSubscription: checkIfUserHasSubscription,
            mainBodyController: mainBodyController,
            uid: desktopUID,
            tickerProvider:this);
      } else {
  //      print("returnin qrpage ");
        return QRPage(dataString: getUIDDBKeyForDesktop());
      }
    }
  }

  void setPairedToTrue()
  {
    print("in setptotrue");
    if(paired != null && paired)
      return;
    setState(() {
      paired = true;
    });
    showDialog<Null>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) =>
          AlertDialog(
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
                            _playListAnimation();

                  },
                ),
              ],
            ),
          ),
    );
  }

  Widget _getInviteCodeWidget(BuildContext context) {
    ThemeData theme = Theme.of(context);
    var codeController = TextEditingController();
    return Container(
      child: new Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
              "League AI is invite-only at this time. Please enter your invite code.",
              style: theme.textTheme.body2),
          SizedBox(
            height: 15,
          ),
          TextField(
              decoration: InputDecoration(
                filled: true,
                labelText: 'Invite code',
              ),
              controller: codeController,
              autofocus: true),
          SizedBox(
            height: 15,
          ),
          RaisedButton(
            child: Text('Submit'),
            onPressed: () async {
              String codeEntered = codeController.text;
              if (codeEntered == "") return;
              bool enteredValidInviteCode = await Fbfunctions.fb_call(
                  methodName: 'getInviteCode',
                  args: <String, dynamic>{
                    "invite_code": codeEntered,
                    "uid": await desktopUIDFuture
                  });
              print("code is ${enteredValidInviteCode}");
              if (enteredValidInviteCode) {
                homePageScaffoldKey.currentState.showSnackBar(SnackBar(
                    content: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      Text("Successful!", textAlign: TextAlign.center)
                    ])));
                setState(() {
                  inviteCodeValid = true;
                });
                String inviteCodeFilePath =
                    Platform.environment['LOCALAPPDATA'] +
                        "\\League AI" +
                        "\\inviteCode";
                File(inviteCodeFilePath).writeAsString(codeEntered);
              } else
                homePageScaffoldKey.currentState.showSnackBar(SnackBar(
                    content: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      Text("Invite code invalid", textAlign: TextAlign.center)
                    ])));
            },
          )
        ],
      ),
    );
  }

  Widget _getFooter(BuildContext context) {
    ThemeData theme = Theme.of(context);


    if ((hasSubscription != null && hasSubscription))
    {
      if(desktopUID != null)
        
        // return Stack(children:[Container(color:Colors.black.withOpacity(1.0)), Center(child:Container(
        //   margin: const EdgeInsets.symmetric(vertical: 20),
        //   child: Align(
        //       alignment: Alignment.center,
        //       child: Container(
        //         child:
                    
        //               RaisedButton(child: Text("Send test message"), onPressed: _testConnection,
        //             shape: RoundedRectangleBorder(
        //                 borderRadius: BorderRadius.circular(3.0),
        //                 side: BorderSide(color: Colors.white)
        //             )),
                  
        //       )),
        // ))]);
        return null;
      else
        return null;
    }
    else
      return null;
  }

  Widget aiLoadingWidget() {
    ThemeData theme = Theme.of(context);
    if (aiLoaded)
      return null;
    else
      return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text("Loading AI...", style: theme.textTheme.body2),
        SizedBox(width: 15),
        SizedBox(
            width: 15,
            height: 15,
            child: CircularProgressIndicator(strokeWidth: 2))
      ]);
  }

  @override
  Widget build(BuildContext context) {
    if (user == null && (Platform.isAndroid || Platform.isIOS))
      return LoginPage();
    else {
//      print("REBUILD APP WIDGET");
      var mainWidget = MainPageTemplateAnimator(
          mainController: mainController,
          appBar: _myAppBar(),
          body: buildBody(),
          mainBodyController: mainBodyController,
          footer: _getFooter(context),
          backdrop: background,
          bottomSheet:
              Platform.isAndroid || Platform.isIOS ? null : aiLoadingWidget(),
          scaffoldKey: homePageScaffoldKey);
      return mainWidget;
    }
  }
}
