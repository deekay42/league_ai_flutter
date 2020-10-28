import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import '../resources/Strings.dart';

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
    return Stack(children:[Container(color:Colors.black.withOpacity(0.65)), Column(children: [
      SizedBox(height:25),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
      RichText(
        text: TextSpan( 
          text: '',
          style: DefaultTextStyle.of(context).style.copyWith(fontSize: 18),
          children: <TextSpan>[
            TextSpan(text: '1. Download the '),
            TextSpan(text: 'League AI app', style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: ' on your phone.'),
          ],
        ),
      ),
      SizedBox(height:15),
      RichText(
        text: TextSpan(
          text: '2. Scan the QR Code with your ',
          style: DefaultTextStyle.of(context).style.copyWith(fontSize: 18 ),
          children: <TextSpan>[
            TextSpan(text: 'League AI app', style: TextStyle(fontWeight: FontWeight.bold))
          ],
        ),
      )]),
      SizedBox(height:25),
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
            )])]);
    }
}