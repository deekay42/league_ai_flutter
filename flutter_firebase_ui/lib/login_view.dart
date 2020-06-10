import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:flutter_firebase_ui/password_view.dart';
import 'package:flutter_firebase_ui/sign_up_view.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:meta/meta.dart';
import 'package:apple_sign_in/apple_sign_in.dart';
import 'package:flutter_firebase_ui/flutter_firebase_ui.dart';
import 'package:flutter_twitter_login/flutter_twitter_login.dart';

import 'email_view.dart';
import 'utils.dart';

class LoginView extends StatefulWidget {
  final List<ProvidersTypes> providers;
  final bool passwordCheck;
  final String twitterConsumerKey;
  final String twitterConsumerSecret;

  LoginView({
    Key key,
    @required this.providers,
    this.passwordCheck,
    this.twitterConsumerKey,
    this.twitterConsumerSecret,
  }) : super(key: key);

  @override
  _LoginViewState createState() => new _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool appleSignInAvailable = false;

  Map<ProvidersTypes, ButtonDescription> _buttons;

  _handleEmailGeneral() async {
    await Navigator.of(context)
        .push(new MaterialPageRoute<bool>(builder: (BuildContext context) {

      return decideEmailSignInOrUp();
    }));
  }

  _handleEmailLogin() async {
    await Navigator.of(context)
        .push(new MaterialPageRoute<bool>(builder: (BuildContext context) {

      return PasswordView("");
    }));
  }

  _handleEmailCreate() async {
    await Navigator.of(context)
        .push(new MaterialPageRoute<bool>(builder: (BuildContext context) {

      return SignUpView("", widget.passwordCheck);
    }));
  }

  Widget decideEmailSignInOrUp()
  {

    return SignInScreen(
      color: Colors.grey[900],
      title: "Welcome",
      header: new Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: new Padding(
          padding: const EdgeInsets.all(16.0),
          child: new Text("New or Returning User?"),
        ),
      ),
      providers: [
        ProvidersTypes.emailSignIn,
        ProvidersTypes.emailSignUp
      ],
      twitterConsumerKey: "AUdn9voKiWbTzAfef4pucVnAk",
      twitterConsumerSecret: "XSb9f9pGBJ3Xm4VM3tUE3Vqamcsug8JEhBi0wqLG1kxWSshnt6",
    );
  }


  _handleGoogleSignIn() async {
    await FirebaseAuth.instance.signOut();
    final GoogleSignInAccount googleUser = await googleSignIn.signIn();
    if (googleUser != null) {
      GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken != null) {
        try {

          final AuthCredential credential = GoogleAuthProvider.getCredential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          final FirebaseUser user = (await _auth.signInWithCredential(credential)).user;
          print(user);
        } catch (e) {
          showErrorDialog(context, e.details);
        }
      }
    }
  }

  Future<FirebaseUser> _handleAppleSignIn() async {
    try {
      await FirebaseAuth.instance.signOut();
      final AuthorizationResult appleResult = await AppleSignIn.performRequests([
        AppleIdRequest(requestedScopes: [Scope.email, Scope.fullName])
      ]);

      if (appleResult.error != null) {
        // handle errors from Apple here
      }

      final AuthCredential credential = OAuthProvider(providerId: 'apple.com').getCredential(
        accessToken: String.fromCharCodes(appleResult.credential.authorizationCode),
        idToken: String.fromCharCodes(appleResult.credential.identityToken),
      );

      AuthResult firebaseResult = await _auth.signInWithCredential(credential);
      final FirebaseUser user = firebaseResult.user;


    } catch (error) {
      print(error);
      return null;
    }
  }

//  _handleGoogleSignIn() async {
//    GoogleSignInAccount googleUser = await googleSignIn.signIn();
//    if (googleUser != null) {
//      GoogleSignInAuthentication googleAuth = await googleUser.authentication;
//      if (googleAuth.accessToken != null) {
//        try {
//          FirebaseUser user = await _auth.signInWithGoogle(
//            accessToken: googleAuth.accessToken,
//            idToken: googleAuth.idToken,
//          );
//
//          print(user);
//        } catch (e) {
//          showErrorDialog(context, e.details);
//        }
//      }
//    }
//  }




  _handleFacebookSignin() async {
    await FirebaseAuth.instance.signOut();
    final facebookLogin = FacebookLogin();
    final facebookLoginResult = await facebookLogin.logIn(['email']);


    if (facebookLoginResult.accessToken != null) {
      try {
        FacebookAccessToken myToken = facebookLoginResult.accessToken;
        AuthCredential credential= FacebookAuthProvider.getCredential(accessToken: myToken.token);
        FirebaseUser user = (await FirebaseAuth.instance.signInWithCredential(credential)).user;
      } catch (e) {
        showErrorDialog(context, e.details);
      }
    }
  }



//  void _handleTwitterSignin() async {
//
//    var twitterLogin = new TwitterLogin(
//      consumerKey: widget.twitterConsumerKey,
//      consumerSecret: widget.twitterConsumerSecret,
//    );
//
//    final TwitterLoginResult result = await twitterLogin.authorize();
//
//    switch (result.status) {
//      case TwitterLoginStatus.loggedIn:
//        print("Twitter logged in");
//        break;
//      case TwitterLoginStatus.cancelledByUser:
//        showErrorDialog(context, "Cancelled by user");
//        break;
//      case TwitterLoginStatus.error:
//        showErrorDialog(context, "Error occured. Please try again later.");
//        break;
//    }
//  }

  _handleTwitterSignin() async {
    await FirebaseAuth.instance.signOut();
    var twitterLogin = new TwitterLogin(
      consumerKey: widget.twitterConsumerKey,
      consumerSecret: widget.twitterConsumerSecret,
    );

    final TwitterLoginResult result = await twitterLogin.authorize();

    switch (result.status) {
      case TwitterLoginStatus.loggedIn:


        final AuthCredential credential = TwitterAuthProvider.getCredential(
            authToken: result.session.token,
            authTokenSecret: result.session.secret);
        final FirebaseUser user = (await _auth.signInWithCredential(credential)).user;

        break;
      case TwitterLoginStatus.cancelledByUser:
        showErrorDialog(context, result.errorMessage);
        break;
      case TwitterLoginStatus.error:
        showErrorDialog(context, result.errorMessage);
        break;
    }
  }

  void initState()
  {
    super.initState();
    AppleSignIn.isAvailable().then((result)
    {
      setState(() {
      appleSignInAvailable = result;
    });});
  }

  @override
  Widget build(BuildContext context) {
    _buttons = {
      ProvidersTypes.facebook:
          providersDefinitions(context)[ProvidersTypes.facebook]
              .copyWith(onSelected: _handleFacebookSignin),
      ProvidersTypes.google:
          providersDefinitions(context)[ProvidersTypes.google]
              .copyWith(onSelected: _handleGoogleSignIn),
      ProvidersTypes.twitter:
          providersDefinitions(context)[ProvidersTypes.twitter]
              .copyWith(onSelected: _handleTwitterSignin),
      ProvidersTypes.email: providersDefinitions(context)[ProvidersTypes.email]
          .copyWith(onSelected: _handleEmailGeneral),
      ProvidersTypes.emailSignIn: providersDefinitions(context)[ProvidersTypes.emailSignIn]
          .copyWith(onSelected: _handleEmailLogin),
      ProvidersTypes.emailSignUp: providersDefinitions(context)[ProvidersTypes.emailSignUp]
          .copyWith(onSelected: _handleEmailCreate),
      ProvidersTypes.apple: appleSignInAvailable ? providersDefinitions(context)[ProvidersTypes.apple]
          .copyWith(onSelected: _handleAppleSignIn) : null,
    };

    return new Container(
        child: new ListView(
            children: widget.providers.map((p) {
      return new Container(
          padding: const EdgeInsets.symmetric(vertical: 0.0),
          child: _buttons[p] ?? new Container());
    }).toList()));
  }

  void _followProvider(String value) {
    ProvidersTypes provider = stringToProvidersType(value);
    if (provider == ProvidersTypes.facebook) {
      _handleFacebookSignin();
    } else if (provider == ProvidersTypes.google) {
      _handleGoogleSignIn();
    } else if (provider == ProvidersTypes.twitter) {
      _handleTwitterSignin();
    }
  }
}
