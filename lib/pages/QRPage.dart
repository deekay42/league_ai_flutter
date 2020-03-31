import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';

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
      SizedBox(height:15),
      Text("Welcome to League IQ! Please pair your phone by scanning the QR Code below with your League IQ app"),
      Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: FutureBuilder<String>(
          future: widget.dataString,
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            print("Got the data!: $snapshot");
            if (snapshot.hasData && snapshot.data!=null) {
            
                return Container(color:Colors.white, child:QrImage(
                    data: snapshot.data,
                    gapless: false,
                    //foregroundColor: const Color(0xFF111111),
                    // onError: (dynamic ex) {
                    //   print('[QR] ERROR - $ex');
                    // },
                  ));
            } else {
              return new CircularProgressIndicator();
            }
            
          }
        )
                  
                  
                  
                  
                ),
              ),
            )]);
    }
}