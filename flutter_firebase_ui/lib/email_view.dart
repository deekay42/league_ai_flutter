import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'l10n/localization.dart';
import 'password_view.dart';
import 'sign_up_view.dart';
import 'utils.dart';
import 'package:flutter/services.dart';

class EmailView extends StatefulWidget {
  final bool passwordCheck;

  EmailView(this.passwordCheck, {Key key}) : super(key: key);

  @override
  _EmailViewState createState() => new _EmailViewState();
}

class _EmailViewState extends State<EmailView> {
  final TextEditingController _controllerEmail = new TextEditingController();
  bool alreadySubmitted;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void initState() {
    super.initState();
    alreadySubmitted = false;

  }

  @override
  Widget build(BuildContext context) => new Scaffold(key:_scaffoldKey,
        appBar: new AppBar(
          title: new Text(FFULocalizations.of(context).welcome),
          elevation: 4.0,
        ),
        body: new Builder(
          builder: (BuildContext context) {
            return new Padding(
              padding: const EdgeInsets.all(16.0),
              child: new Column(
                children: <Widget>[
                  new TextField(
                    controller: _controllerEmail,
                    autofocus: true,
                    onSubmitted: _submit,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: new InputDecoration(
                        labelText: FFULocalizations.of(context).emailLabel),
                  ),
                ],
              ),
            );
          },
        ),
        persistentFooterButtons: <Widget>[
          new ButtonBar(
            alignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              FlatButton(
                  onPressed: () {

                    return _connexion(context);
                  },
                  child: new Row(
                    children: <Widget>[
                      new Text(FFULocalizations.of(context).nextButtonLabel),
                    ],
                  )),
            ],
          )
        ],
      );

  _submit(String submitted) {
    _connexion(context);
  }

  _connexion(BuildContext context) async {

    if (!alreadySubmitted) {
      alreadySubmitted = true;
    } else
      return;
    try {
      await FirebaseAuth.instance.signOut();
      final FirebaseAuth auth = FirebaseAuth.instance;

      List<String> providers =
          await auth.fetchSignInMethodsForEmail(email: _controllerEmail.text);


      if (providers == null || providers.isEmpty) {
        bool connected = await Navigator.of(context)
            .push(new MaterialPageRoute<bool>(builder: (BuildContext context) {
          return new SignUpView(_controllerEmail.text, widget.passwordCheck);
        }));

        if (connected) {
          Navigator.pop(context);
        }
        else
          {
            setState(() {
              alreadySubmitted = false;
            });
          }
      } else if (providers.contains('password')) {
        bool connected = await Navigator.of(context)
            .push(new MaterialPageRoute<bool>(builder: (BuildContext context) {
          return new PasswordView(_controllerEmail.text);
        }));

        if (connected) {
          Navigator.pop(context);
        }
        else
        {
          setState(() {
            alreadySubmitted = false;
          });
        }
      } else {
        String provider = await _showDialogSelectOtherProvider(
            _controllerEmail.text, providers);
        if (provider.isNotEmpty) {
          Navigator.pop(context, provider);
        }
      }
    }
    on PlatformException catch (e)
    {
      alreadySubmitted = false;
      var mySnack = SnackBar(duration:const Duration(seconds:5), content: Row(mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center, children:[Text(e.message, textAlign: TextAlign.center)]));
      _scaffoldKey.currentState.showSnackBar(mySnack);

    }
    catch (exception) {
      alreadySubmitted = false;
      print(exception);
    }
  }

  _showDialogSelectOtherProvider(String email, List<String> providers) {
    var providerName = _providersToString(providers);
    return showDialog<String>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) => new AlertDialog(
            content: new SingleChildScrollView(
                child: new ListBody(
              children: <Widget>[
                new Text(FFULocalizations.of(context)
                    .allReadyEmailMessage(email, providerName)),
                new SizedBox(
                  height: 16.0,
                ),
                new Column(
                  children: providers.map((String p) {
                    return new RaisedButton(
                      child: new Row(
                        children: <Widget>[
                          new Text(_providerStringToButton(p)),
                        ],
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(p);
                      },
                    );
                  }).toList(),
                )
              ],
            )),
            actions: <Widget>[
              new FlatButton(
                child: new Row(
                  children: <Widget>[
                    new Text(FFULocalizations.of(context).cancelButtonLabel),
                  ],
                ),
                onPressed: () {
                  Navigator.of(context).pop('');
                },
              ),
            ],
          ),
    );
  }

  String _providersToString(List<String> providers) {
    return providers.map((String provider) {
      ProvidersTypes type = stringToProvidersType(provider);
      return providersDefinitions(context)[type]?.name;
    }).join(", ");
  }

  String _providerStringToButton(String provider) {
    ProvidersTypes type = stringToProvidersType(provider);
    return providersDefinitions(context)[type]?.label;
  }
}
