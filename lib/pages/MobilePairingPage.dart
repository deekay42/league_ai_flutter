import '../supplemental/utils.dart';
import 'package:flutter/material.dart';
import '../resources/Strings.dart';
import 'package:qrcode_reader/qrcode_reader.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'dart:async';

class MobilePairingPage extends StatefulWidget {
  @override
  _MobilePairingPageState createState() => _MobilePairingPageState();
}


class _MobilePairingPageState extends State<MobilePairingPage>  {

  PermissionStatus perm;
  Future<PermissionStatus> permFuture;
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
      SizedBox(height:55),
      Text(Strings.mobileWelcome, textAlign: TextAlign.center),
      SizedBox(height:55),
      RaisedButton(child: Text("Pair Now"), onPressed: ()=>triggerPairing(context))
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
    displayFullScreenModal(
        context, MyDialog(modalText: "", spinner: true));

    CloudFunctions.instance.getHttpsCallable(
      functionName: 'passUIDtoDesktop').call(
      <String, dynamic>{
        'realtimeDBID': realtimeDBID,
      },
    ).then((dynamic result) {
      result = result.data;
      
      if (result != "SUCCESS")
      {
        Navigator.pop(context);
        displayErrorDialog(context, "Pairing unsuccessful. Please try again");
      }
    }).catchError((e) {
      Navigator.pop(context);
      print("ERROR " + e.message);
      displayErrorDialog(context, "Pairing unsuccessful. Please try again");
    });
  }
}