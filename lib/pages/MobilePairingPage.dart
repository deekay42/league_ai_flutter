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
      SizedBox(height:15),
      Text(Strings.pairingInstructions),
      SizedBox(height:5),
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
    displayFullScreenModal(
        context, MyDialog(modalText: "", spinner: true));

    CloudFunctions.instance.getHttpsCallable(
      functionName: 'passUIDtoDesktop').call(
      <String, dynamic>{
        'realtimeDBID': realtimeDBID,
      },
    ).then((dynamic result) {
      result = result.data;
      Navigator.pop(context);
      if (result != "SUCCESS")
        displayErrorDialog(context, "Pairing unsuccessful. Please try again");
      else
        displayWaitingModal(context, "Trying to reach desktop app now...");
    }).catchError((e) {
      Navigator.pop(context);
      print("ERROR " + e.message);
      displayErrorDialog(context, "Pairing unsuccessful. Please try again");
    });
  }
}