import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';
import 'dart:async';

import 'package:btnonce/btnonce.dart' as btnonce;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fbfunctions/fbfunctions.dart' as fbfunctions;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../pages/main_page_template.dart';
import '../resources/Strings.dart';
import '../supplemental/utils.dart';
import '../widgets/appbar.dart';
import '../widgets/items_list.dart';

enum ConfirmResult { SUCCESS, CHANGING }

class ClientTokenException implements Exception {
  String cause;
  ClientTokenException(this.cause);
}

class NonceException implements Exception {
  String cause;
  NonceException(this.cause);
}

class CheckoutException implements Exception {
  String cause;
  CheckoutException(this.cause);
}

class PaymentException implements Exception {
  String cause;
  PaymentException(this.cause);
}

class SubscribePage extends StatefulWidget {
  SubscribePage();

  @override
  _SubscribePageState createState() => _SubscribePageState();
}

class _SubscribePageState extends State<SubscribePage>
    with TickerProviderStateMixin {
  static const platform = const MethodChannel('getPaymentNonce');
  Future<dynamic> _clientToken;
  var scaffoldKey;
  bool subButtonPressed = false;
  MyDialog myDialog;
  String background;

  AnimationController mainController;
  AnimationController mainBodyController;

  void initState() {
    super.initState();

    var list = [
      'assets/imgs/1.png',
      'assets/imgs/2.png',
      'assets/imgs/3.png',
      'assets/imgs/4.png'
    ];
    final _random = new Random();
    background = list[_random.nextInt(list.length)];

    if (Platform.isAndroid || Platform.isIOS)
      _clientToken = CloudFunctions.instance.getHttpsCallable(functionName: 'client_token').call();
    else {
      _clientToken = fbfunctions.fb_call(methodName: 'client_token');
    }

    mainController = AnimationController(
        duration: Duration(milliseconds: 3500), vsync: this);
    mainBodyController = AnimationController(
        duration: Duration(milliseconds: 2500), vsync: this);
    _playAnimation();
  }

  void dispose() {
    mainController.dispose();
    mainBodyController.dispose();
    super.dispose();
  }

  Future<void> _playAnimation() async {
    try {
      mainController.reset();
      mainBodyController.reset();
      mainController.forward().orCancel;
      Future.delayed(const Duration(seconds: 1), () {
        _playListAnimation();
      });
    } on TickerCanceled {
      // the animation got canceled, probably because we were disposed
    }
  }

  Future<void> _playListAnimation() async {
    try {
      mainBodyController.reset();
      await mainBodyController.forward().orCancel;
    } on TickerCanceled {
      // the animation got canceled, probably because we were disposed
    }
  }

  Future<List<String>> _getPaymentNonce() async {
    print("now getting the nonce");
    var clientTokenResult = await _clientToken;
    if (Platform.isAndroid || Platform.isIOS)
      clientTokenResult = clientTokenResult.data;
    dynamic result = await platform
        .invokeMethod('getPaymentNonce', {"clientToken": clientTokenResult});
    print("now got the the nonce");
    print(result.toString());
    if (result == null) return null;
    String nonce = result[0];
    String desc = result[1];

    return [nonce, desc];
  }

  Future<ConfirmResult> checkout(String nonce) async {
    print("now attempting checkout");
    var myFuture;
    if (Platform.isAndroid || Platform.isIOS)
      myFuture = CloudFunctions.instance.getHttpsCallable(
        functionName: 'subscribe').call(<String, dynamic>{
          'payment_method_nonce': nonce,
        },
      );
    else
      myFuture = fbfunctions.fb_call(
        methodName: 'subscribe',
        args: <String, dynamic>{
          'payment_method_nonce': nonce,
        },
      );

    dynamic resp = await myFuture;
    resp = resp.data;
    if (resp == "SUCCESS") {
      print("SUCCESS");
      return ConfirmResult.SUCCESS;
    } else {
      print("No success");
      print(resp);
      throw CheckoutException("Problem checking out");
    }
  }

  // Future<ConfirmResult> _getConfirmation(
  //     BuildContext context, String nonce, String desc) async {

  //   return await showModalBottomSheet<ConfirmResult>(
  //       context: context,
  //       builder: (BuildContext context) {
  //         return GestureDetector(
  //             behavior: HitTestBehavior.opaque,
  //             onTap: () {},
  //             child: ConfirmDialog(nonce: nonce, desc: desc));
  //       });
  // }

  Widget _buildBody(BuildContext context) {
    int counter = 0;
    ThemeData theme = Theme.of(context);

    return SlidingList(
        title: "",
        children: Strings.pitch
            .map((p) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p[0],
                    textAlign: TextAlign.start,
                    style: theme.textTheme.display1,
                  ),
                  SizedBox(
                    height: 4,
                  ),
                  Text(
                    p[1],
                    textAlign: TextAlign.start,
                    style: theme.textTheme.body2,
                  ),
                  ++counter == Strings.pitch.length
                      ? null
                      : SizedBox(
                          height: 42,
                        ),
                ].where(notNull).toList()))
            .toList(),
        animationController: mainBodyController,
        origin: Offset(10, 0));
  }

  Widget _buildAppBar(BuildContext context) {
    return BasicAppBar(false, null, true);
  }

  Future<String> getDesktopNonce() async {
    dynamic result =
        await btnonce.finishPayment(clientToken: await _clientToken);
    setState(() {});
    print("Dart: this is the result: $result");
    if (result != null) {
      var resultJson = jsonDecode(await result);
      return resultJson["nonce"];
    } else
      return null;
  }

  Future<void> runPaymentProcess(BuildContext context) async {
    try {
      await _clientToken;

    } catch (e) {
      throw ClientTokenException(e.toString());
    }
    ConfirmResult result = ConfirmResult.CHANGING;

    do {
      List<String> nonceDesc;

      try {
        if (Platform.isAndroid || Platform.isIOS)
          nonceDesc = await _getPaymentNonce();
        else {
          String nonce = await getDesktopNonce();
          if (nonce != null) {
            nonceDesc = List<String>();
            nonceDesc.add(nonce);
          }
        }
        //user tapped elsewhere on the screen dismissing the modal
        if (nonceDesc == null) {
          subButtonPressed = false;
          return;
        }
      } catch (e) {
        print(e.message);
        throw NonceException(e.toString());
      }
      print('got the payment nonce!');
      try {
        //result = await _getConfirmation(context, nonceDesc[0], nonceDesc[1]);
        displayFullScreenModal(
            context, MyDialog(modalText: "Loading...", spinner: true));

        result = await checkout(nonceDesc[0]);
        print("Got the result: $result");
      } catch (e) {
        throw CheckoutException(e.toString());
      }
    } while (result == ConfirmResult.CHANGING);

    if (result == ConfirmResult.SUCCESS) {
      Navigator.pop(context);
      displayFullScreenModal(
          context, MyDialog(modalText: "Success!", spinner: false));
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pop(context);
        Navigator.pop(context, true);
      });
    }
  }

  void showErrorSnackBar(var _scaffoldKey, String msg) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(msg),
      duration: Duration(seconds: 5),
    ));
  }

  Widget _buildFooter(BuildContext context) {
    return Column(children: [
      SizedBox(height: 12),
      RaisedButton(
        child: Text(Strings.sub_price),
        onPressed: () async {
          if (subButtonPressed)
            return;
          else
            subButtonPressed = true;
          try {
            await runPaymentProcess(context);
          } on NonceException catch (e) {
            print("NonceException");
            showErrorSnackBar(
                scaffoldKey, Strings.nonceError + " '${e.toString()}'");
          } on ClientTokenException catch (e) {
            print("ClientTokenException");
            showErrorSnackBar(
                scaffoldKey, Strings.clientTokenError + " '${e.toString()}'");
          } on CheckoutException catch (e) {
            print("CheckoutException");
            showErrorSnackBar(
                scaffoldKey, Strings.checkoutError + " '${e.toString()}'");
          } on Exception catch (e) {
            print("Exception");
            showErrorSnackBar(scaffoldKey,
                Strings.generalPaymentsError + " '${e.toString()}'");
          } finally {
            subButtonPressed = false;
          }
        },
      )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    var mainPage = MainPageTemplateAnimator(
      mainController: mainController,
      appBar: _buildAppBar(context),
      body: _buildBody(context),
      mainBodyController: mainBodyController,
      footer: _buildFooter(context),
      backdrop: background,
    );
    scaffoldKey = mainPage.scaffoldKey;
    return mainPage;
  }
}
