import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRPage extends StatefulWidget {
  final Future<String> dataString;

  QRPage({this.dataString});

  @override
  _QRPageState createState() => _QRPageState();
}

class _QRPageState extends State<QRPage>  with SingleTickerProviderStateMixin{

  AnimationController mainController;

 @override
 
  Widget build(BuildContext context)
  {
    return Column(children: [
      Text("Please scan the QR Code using your League IQ app on your phone to complete the pairing."),
      Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: FutureBuilder<String>(
          future: widget.dataString,
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            print("Got the data!:");
            if (snapshot.hasData) {
               print("Got the data2!: "+snapshot.data);
              if (snapshot.data!=null) {
                return Container(color:Colors.white, child:QrImage(
                    data: snapshot.data,
                    gapless: false,
                    //foregroundColor: const Color(0xFF111111),
                    onError: (dynamic ex) {
                      print('[QR] ERROR - $ex');
                    },
                  ));
              } else {
                return new CircularProgressIndicator();
              }
            }
          }
        )
                  
                  
                  
                  
                ),
              ),
            )]);
    }
}