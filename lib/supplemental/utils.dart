import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_firebase_ui/l10n/localization.dart';

void waitForFileToFinishLoading(File file) async
{
  int oldsize = -1;
  while(true)
  {
      int size = await file.length();
      if(size == oldsize)
          break;
      else
      {
        //print("File is still loading...: size is $size and oldsize is $oldsize");
        oldsize = size;
        sleep(Duration(milliseconds:50));
      }
  }
  //print("File is fully loaded now");
}

Future<Null> displayErrorDialog(BuildContext context, String message,
    {String title}) {
  return showDialog<Null>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) => new AlertDialog(
      title: title != null ? new Text(title) : null,
      content: new SingleChildScrollView(
        child: new ListBody(
          children: <Widget>[
            new Text(message ?? FFULocalizations.of(context).errorOccurred),
          ],
        ),
      ),
      actions: <Widget>[
        new FlatButton(
          child: new Row(
            children: <Widget>[
              new Text(FFULocalizations.of(context).cancelButtonLabel),
            ],
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    ),
  );
}

Future<Null> displayWaitingModal(BuildContext context, String message,
    {String title}) {
  return showDialog<Null>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) =>  AlertDialog(
      title: title != null ?  Text(title) : null,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 15,),
          Text(message),
        ],
      ),

    ),
  );
}

void displayFullScreenModal(BuildContext context, MyDialog dialog) {
      
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => dialog,
  );
}

class MyDialog extends StatefulWidget {

  final String modalText;
  final bool spinner;
  MyDialog({this.modalText, this.spinner});

  @override
  _MyDialogState createState() => _MyDialogState();
}

class _MyDialogState extends State<MyDialog> {
  Widget build(BuildContext context)
  {
    final ThemeData theme = Theme.of(context);
    return Container(
          color: Colors.black.withOpacity(0.5),
          child: new Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.spinner ? [
              CircularProgressIndicator(),
              SizedBox(
                width: 15,
              ),
              Text(widget.modalText, style: theme.textTheme.body1),
            ] : [Text(widget.modalText, style: theme.textTheme.body1)],
          ),
        );
  }
}




