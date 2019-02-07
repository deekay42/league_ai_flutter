import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../pages/main_page_template.dart';
import '../resources/Strings.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/items_list.dart';

class SubscribePage extends StatefulWidget {
  @override
  _SubscribePageState createState() => _SubscribePageState();
}

class _SubscribePageState extends State<SubscribePage> with TickerProviderStateMixin {

  static const platform = const MethodChannel('getPaymentNonce');
  final Future<dynamic> _clientToken;

  AnimationController mainController;
  AnimationController mainBodyController;

  void initState()
  {
    super.initState();
    mainController = AnimationController(duration: Duration(seconds: 10), vsync: this);
    mainBodyController = AnimationController(duration: Duration(seconds: 10), vsync: this);
    _playAnimation();
  }

  void dispose()
  {
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
    try {
      print("In getpaymentnonce");
      dynamic result = await platform
          .invokeMethod('getPaymentNonce', {"clientToken": await _clientToken});
      print("This is the result: ");
      print(result.toString());
      String nonce = result[0];
      print('Obtained nonce: $nonce');
      String desc = result[1];
      print('Obtained desc: $desc');
      return [nonce, desc];
    } on PlatformException catch (e) {
      print("Failed to get payment nonce: '${e.message}'.");
      return null;
    }
  }

  Future<ConfirmResult> _getConfirmation(
      BuildContext context, String nonce, String desc) async {
    return await showModalBottomSheet<ConfirmResult>(
        context: context,
        builder: (BuildContext context) {
          return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: ConfirmDialog(nonce: nonce, desc: desc)
          );

        });
  }

  Widget _buildBody(BuildContext context) {
    int counter = 0;
    ThemeData theme = Theme.of(context);

    return Container(
        margin: EdgeInsets.symmetric(horizontal: 20), child: SlidingList(
        title: "",
        children: Strings.pitch
            .map((p) =>
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                ].where(notNull)
                    .toList()))


            .toList(), animationController: mainBodyController,
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

  Widget _buildFooter(BuildContext context) {
    return RaisedButton(
      child: Text(Strings.sub_price),
      onPressed: () async {
        await _clientToken;

        ConfirmResult result = ConfirmResult.CHANGING;
        do {
          List<String> nonce_desc = await _getPaymentNonce();
          print('got the payment nonce!');
          result =
              await _getConfirmation(context, nonce_desc[0], nonce_desc[1]);
          print('This is the result from the confirmation: $result');

        } while (result == ConfirmResult.CHANGING);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {


    return MainPageTemplateAnimator(
      mainController: mainController,
      appBar: _buildAppBar(context),
      body: _buildBody(context),
      mainBodyController: mainBodyController,
      footer: _buildFooter(context),
      backdrop: 'assets/subscribe_backdrop.png',
    );
  }
}
