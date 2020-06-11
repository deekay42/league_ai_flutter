import '../supplemental/utils.dart';
import 'package:flutter/material.dart';
import '../resources/Strings.dart';
import 'package:qrcode_reader/qrcode_reader.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MobilePairingPage extends StatefulWidget {
  final Function setPairedToTrue;
  MobilePairingPage({this.setPairedToTrue});
  
  @override
  _MobilePairingPageState createState() => _MobilePairingPageState();
}


class _MobilePairingPageState extends State<MobilePairingPage>  {

  PermissionStatus perm;
  Future<PermissionStatus> permFuture;
  bool buttonPressed = false;
  void initState() {
    super.initState();



//    Future.delayed(Duration(seconds: 10), () {
//      print("Now sending relaymessage");
//      CloudFunctions.instance
//          .getHttpsCallable(functionName: 'completePairing').call();
////      _handleNewMessageIncoming({'data':{'body':"1001,1001,1001,1001"}});
//    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(child:Container()),
      Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            RichText(
              text: TextSpan(
                text: '',
                style: DefaultTextStyle.of(context).style.copyWith(fontSize: 18),
                children: <TextSpan>[
                  TextSpan(text: '1. Download the '),
                  TextSpan(text: 'League IQ windows app', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: ' on your computer: '),
                  TextSpan(text: 'http://leagueiq.gg', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            SizedBox(height:35),
            RichText(
              text: TextSpan(
                text: '2. Scan the QR Code in the ',
                style: DefaultTextStyle.of(context).style.copyWith(fontSize: 18 ),
                children: <TextSpan>[
                  TextSpan(text: 'League IQ windows app', style: TextStyle(fontWeight: FontWeight.bold))
                ],
              ),
            )]),

      SizedBox(height:25),
      buttonPressed ?
          Column( children: [
          CircularProgressIndicator(),
          SizedBox(
            width: 15,
          ),
          Text("Please wait...")])
      :   RaisedButton(child: Text("Pair Now"), onPressed: ()=>triggerPairing(context)),
      Expanded(child:Container()),
    ]);
  }

  void triggerPairing(BuildContext context) async {

    print("Now trying to get camera permissions");
    permFuture = Permission.camera.request();
    perm = await permFuture;
    print("Future complete");
    print(perm);

    if(perm == PermissionStatus.denied || (Platform.isIOS && perm == PermissionStatus.restricted) || (Platform.isAndroid && perm == PermissionStatus.permanentlyDenied))
    {
      print("it's denied");
      await showDialog<Null>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) => AlertDialog(
          title: Text("Error"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Camera access is required to pair with the desktop app. Please grant camera permission."),
              SizedBox(
                height: 15,
              ),
              RaisedButton(
                child: Text("OK"),
                onPressed: () async {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      );
      openAppSettings();
      return;
    }


    String realtimeDBID = await QRCodeReader()
        .setAutoFocusIntervalInMs(200)
        .setForceAutoFocus(true)
        .setTorchEnabled(true)
        .setHandlePermissions(true)
        .setExecuteAfterPermissionGranted(true)
        .scan();
    if(realtimeDBID == null)
      return;
    print("Obtained the realtimeDBID: $realtimeDBID");
//    displayFullScreenModal(
//        context, MyDialog(modalText: "", spinner: true));
    setState(() {
      buttonPressed = true;
    });
    CloudFunctions.instance.getHttpsCallable(
      functionName: 'passUIDtoDesktop').call(
      <String, dynamic>{
        'realtimeDBID': realtimeDBID,
      },
    ).then((dynamic result) {
      result = result.data;
      
      if (result != "SUCCESS")
      {
        print("this didnt work1");
        print(result);

        displayErrorDialog(context, "Pairing unsuccessful. Please try again");
        setState(() {
          buttonPressed = false;
        });
      }
      else
      {
        DatabaseReference desktopUIDSubmittedRef = FirebaseDatabase.instance.reference().child('uids').child(realtimeDBID);
        StreamSubscription<Event> desktopUIDSubmittedListener;
        desktopUIDSubmittedListener = desktopUIDSubmittedRef.onValue.listen((Event event) async {

          String uid = (await FirebaseAuth.instance.currentUser()).uid;
          if(event.snapshot.value.containsKey("uid")) {
            if (event.snapshot.value["uid"] == uid)
              return;
            if (event.snapshot.value["uid"] == "submitted") {
              print("GOTIT");
              desktopUIDSubmittedListener.cancel();
              FirebaseDatabase.instance
                  .reference()
                  .child('uids')
                  .child(realtimeDBID).remove();
              widget.setPairedToTrue();
              return;
            }
          }
          print("this didnt work2");
          print(event.snapshot.value);

          displayErrorDialog(context, "Pairing unsuccessful. Please try again");
          desktopUIDSubmittedListener.cancel();
          setState(() {
            buttonPressed = false;
          });
        }, onError: (Object o) {
          print("this didnt work3");
          print(o);

            displayErrorDialog(context, "Pairing unsuccessful. Please try again");
            desktopUIDSubmittedListener.cancel();
          setState(() {
            buttonPressed = false;
          });
          });


          
      }
    }).catchError((e) {

      print("ERROR " + e.message);
      displayErrorDialog(context, "Pairing unsuccessful. Please try again");
    });
  }
}