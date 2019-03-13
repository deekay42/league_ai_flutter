import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../resources/Strings.dart';

enum ConfirmResult { SUCCESS, CHANGING }

class ConfirmDialog extends StatelessWidget {
  final String nonce, desc;
  ConfirmDialog({@required this.nonce, @required this.desc});

  Future<ConfirmResult> checkout() async {
    return CloudFunctions.instance.call(
      functionName: 'subscribe',
      parameters: <String, dynamic>{
        'payment_method_nonce': nonce,
      },
    ).then((dynamic resp) {
      if (resp == "SUCCESS") {
        print("SUCCESS");
        return ConfirmResult.SUCCESS;
      } else {
        print("No success");
        print(resp);
        return ConfirmResult.CHANGING;
      }
    }).catchError((e) {
      print(e);
      return null;
    });
  }

  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return new Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: [
            SizedBox(
              width: 15,
            ),
            Padding(
                padding: EdgeInsets.only(top: 16, bottom: 8),
                child: Container(
                    height: 60,
                    child: Image.asset(
                      'assets/ic_launcher_foreground.png',
                      fit: BoxFit.fitHeight,
                    ))),
            SizedBox(
              width: 20,
            ),
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Strings.name,
                    style: theme.textTheme.body1,
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Text(
                    Strings.membership_title,
                    style: theme.textTheme.body2,
                  )
                ]),
            Expanded(child: Container()),
            Text(
              Strings.price,
              style: theme.textTheme.subtitle,
            ),
            SizedBox(
              width: 15,
            )
          ],
        ),
        Divider(
          color: Colors.white,
        ),
        Padding(
            padding: EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              SizedBox(
                width: 15,
              ),
              Text(
                desc,
                style: theme.textTheme.subtitle,
              ),
              Expanded(child: Container()),
              InkWell(
                child: Container(
                    height: 30,
                    width: 100,
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            Strings.change,
                            style: theme.textTheme.body2,
                          )
                        ])),
                onTap: () async {
                  print("Now returning ConfirmResult.CHANGING");
                  Navigator.pop(context, ConfirmResult.CHANGING);
                },
              ),
              SizedBox(
                width: 15,
              )
            ])),
        Divider(
          color: Colors.white,
        ),
        Padding(
            padding: EdgeInsets.symmetric(vertical: 5),
            child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
              SizedBox(width: 15),
              Text(
                Strings.fineprint,
                style: theme.textTheme.overline,
              )
            ])),
        Row(children: [
          Expanded(
            child: RaisedButton(
              child: Text(Strings.sub),
              onPressed: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) => Container(
                        color: Colors.black.withOpacity(0.5),
                        child: new Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(
                              width: 15,
                            ),
                            Text("Loading", style: theme.textTheme.body1),
                          ],
                        ),
                      ),
                );

                ConfirmResult result = await checkout();
                Navigator.pop(context);
                Navigator.pop(context, result);
              },
            ),
          )
        ]),
        SizedBox(
          height: 40,
        ),
      ],
    );
  }
}
