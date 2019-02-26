import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../pages/main_page_template.dart';
import '../resources/Strings.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/items_list.dart';

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
  @override
  _SubscribePageState createState() => _SubscribePageState();
}

class _SubscribePageState extends State<SubscribePage>
    with TickerProviderStateMixin {
  static const platform = const MethodChannel('getPaymentNonce');
  final Future<dynamic> _clientToken;
  var scaffoldKey;

  AnimationController mainController;
  AnimationController mainBodyController;

  void initState() {
    super.initState();
    mainController =
        AnimationController(duration: Duration(seconds: 10), vsync: this);
    mainBodyController =
        AnimationController(duration: Duration(seconds: 10), vsync: this);
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
      await mainController.forward().orCancel;
    } on TickerCanceled {
      // the animation got canceled, probably because we were disposed
    }
  }

  _SubscribePageState()
      : _clientToken =
            CloudFunctions.instance.call(functionName: 'client_token');



  Future<List<String>> _getPaymentNonce() async {
    print("now getting the nonce");
    dynamic result = await platform
        .invokeMethod('getPaymentNonce', {"clientToken": await _clientToken});
    print("now got the the nonce");
    print(result.toString());
    String nonce = result[0];
    String desc = result[1];

    return [nonce, desc];
  }

  Future<ConfirmResult> _getConfirmation(
      BuildContext context, String nonce, String desc) async {

    return await showModalBottomSheet<ConfirmResult>(
        context: context,
        builder: (BuildContext context) {
          return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: ConfirmDialog(nonce: nonce, desc: desc));
        });
  }

  Widget _buildBody(BuildContext context) {
    int counter = 0;
    ThemeData theme = Theme.of(context);

    return Container(
        margin: EdgeInsets.symmetric(horizontal: 20),
        child: SlidingList(
            title: "",
            children: Strings.pitch
                .map((p) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p,
                        textAlign: TextAlign.start,
                        style: theme.textTheme.body1,
                      ),
                      ++counter == Strings.instructions.length
                          ? null
                          : SizedBox(
                              height: 36,
                            ),
                    ].where(notNull).toList()))
                .toList(),
            animationController: mainBodyController,
            origin: Offset(10, 0)));
  }

  Widget _buildAppBar(BuildContext context) {
    return AppBar(
      leading: new IconButton(
          icon: new Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          }),
    );
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
        nonceDesc = await _getPaymentNonce();
      } catch (e) {
        print(e.message);
        throw NonceException(e.toString());
      }
      print('got the payment nonce!');
      try {
        result = await _getConfirmation(context, nonceDesc[0], nonceDesc[1]);
      } catch (e) {
        throw CheckoutException(e.toString());
      }
    } while (result == ConfirmResult.CHANGING);
    if (result == ConfirmResult.SUCCESS) Navigator.pop(context);
  }

  void showErrorSnackBar(var _scaffoldKey, String msg) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(msg),
      duration: Duration(seconds: 5),
    ));
  }

  Widget _buildFooter(BuildContext context)
  {
    return RaisedButton(
      child: Text(Strings.sub_price),
      onPressed: () async {
        try {
          await runPaymentProcess(context);
        } on NonceException catch (e) {
          print("NonceException");
          showErrorSnackBar(
              scaffoldKey, Strings.nonceError + "'${e.toString()}'");
        } on ClientTokenException catch (e) {
          print("ClientTokenException");
          showErrorSnackBar(
              scaffoldKey, Strings.clientTokenError + "'${e.toString()}'");
        } on CheckoutException catch (e) {
          print("CheckoutException");
          showErrorSnackBar(
              scaffoldKey, Strings.checkoutError + "'${e.toString()}'");
        } on Exception catch (e) {
          print("Exception");
          showErrorSnackBar(
              scaffoldKey, Strings.generalPaymentsError + "'${e.toString()}'");
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var mainPage = MainPageTemplateAnimator(
      mainController: mainController,
      appBar: _buildAppBar(context),
      body: _buildBody(context),
      mainBodyController: mainBodyController,
      footer: _buildFooter(context),
      backdrop: 'assets/subscribe_backdrop.png',
    );
    scaffoldKey = mainPage.scaffoldKey;
    return mainPage;
  }
}
