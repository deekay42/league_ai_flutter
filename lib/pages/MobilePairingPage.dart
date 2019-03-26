import '../supplemental/utils.dart';
import 'package:flutter/material.dart';
import '../resources/Strings.dart';
import 'package:qrcode_reader/qrcode_reader.dart';
import 'package:cloud_functions/cloud_functions.dart';

class MobilePairingPage extends StatelessWidget
{
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(Strings.pairingInstructions),
      RaisedButton(child: Text("Pair Now"), onPressed: ()=>triggerPairing(context))
    ]);
  }

  void triggerPairing(BuildContext context) async {
    String realtimeDBID = await QRCodeReader()
        .setAutoFocusIntervalInMs(200)
        .setForceAutoFocus(true)
        .setTorchEnabled(true)
        .setHandlePermissions(true)
        .setExecuteAfterPermissionGranted(true)
        .scan();

    print("Obtained the realtimeDBID: " + realtimeDBID);

    CloudFunctions.instance.call(
      functionName: 'passUIDtoDesktop',
      parameters: <String, dynamic>{
        'realtimeDBID': realtimeDBID,
      },
    ).then((dynamic result) {
      if (result != "SUCCESS")
        displayErrorDialog(context, "Pairing unsuccessful1. Please try again");
      else
        displayWaitingModal(context, "Trying to reach desktop app now...");
    }).catchError((e) {
      print("ERROR " + e.message);
      displayErrorDialog(context, "Pairing unsuccessful2. Please try again");
    });
  }
}