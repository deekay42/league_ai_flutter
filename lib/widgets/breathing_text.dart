import 'package:flutter/material.dart';
import '../resources/Strings.dart';
import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:fbfunctions/fbfunctions.dart';

class BreathingImage extends StatefulWidget {
  @override
  BreathingImageState createState() => BreathingImageState();
}

class BreathingImageState extends State<BreathingImage>
    with TickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> animation;

  AnimationController brainController;
  Animation<double> brainAnimation;
  Color color = Colors.transparent;
  bool ai_loaded = false;
  bool ai_loading = false;

  @override
  void initState() {
    _controller = AnimationController(
        duration: const Duration(milliseconds: 2500), vsync: this);

    brainController = AnimationController(
        duration: const Duration(milliseconds: 2500), vsync: this);

    animation = Tween(begin: 250.0, end: 0.0).animate(
      new CurvedAnimation(
          parent: _controller, curve: Curves.elasticOut.flipped),
    );

    brainAnimation = Tween(begin: 100.0, end: 90.0).animate(
      new CurvedAnimation(parent: brainController, curve: Curves.linear),
    );

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed && !ai_loaded) {
        Future.delayed(Duration(seconds: 2), () {
          _controller.reverse();
          setState(() {
            color = Colors.red;
            brainController.forward();
            ai_loaded = true;
          });
        });
      } else if (status == AnimationStatus.dismissed) {
        setState(() {

          ai_loading = false;
        });
      }
    });

    brainAnimation.addStatusListener((status) {
      if (status == AnimationStatus.completed)
        brainController.reverse();
      else if (status == AnimationStatus.dismissed) {
        brainController.forward();
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    brainController.dispose();
    super.dispose();
  }

  void _testConnection()
  {
    print("test oco66nnection!");
    Fbfunctions.fb_call(
                  methodName: 'newRecommendation',
                  args: <String, dynamic>{"items": [-1]});
    showDialog<Null>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) =>
          AlertDialog(
            title: Text("Test message sent"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("If you didn't see a notification on your phone, try to pair again."),
                SizedBox(
                  height: 15,
                ),
                RaisedButton(
                  child: Text("Cancel"),
                  onPressed: () {
                            Navigator.pop(context);

                  },
                ),
              ],
            ),
          ),
    );              
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Opacity(opacity:ai_loaded ? 1.0 : 0.85, child:Container(
          color: Colors.black,
          child: Column(children: [
            Flexible(
                flex: 1,
                child: Container()),
            Flexible(
                flex: 4,
                child: Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      AnimatedBuilder(
                          animation: animation,
                          builder: (BuildContext context, Widget child) =>
                              Stack(
                                  fit: StackFit.loose,
                                  alignment: AlignmentDirectional.center,
                                  children: [
                                    Center(
                                        child: ClipOval(
                                            child: ColorFiltered(
                                                child: Image.asset(
                                                  "assets/imgs/ai.gif",
                                                  height: animation.value,
                                                  width: animation.value,
                                                ),
                                                colorFilter: ColorFilter.mode(
                                                    color, BlendMode.color)))),
                                    ai_loaded
                                        ? Container(
                                            height: 100,
                                            child: AnimatedBuilder(
                                                animation: brainAnimation,
                                                builder:
                                                    (BuildContext context,
                                                            Widget child) =>
                                                        Center(
                                                            child: Column(
                                                                children: [
                                                              Container(
                                                                  height:
                                                                      brainAnimation
                                                                          .value,
                                                                  child: ClipOval(
                                                                      child: ColorFiltered(
                                                                          child: Image.asset(
                                                                            "assets/imgs/brain2.png",
                                                                          ),
                                                                          colorFilter: ColorFilter.mode(color, BlendMode.color)))),
                                                              SizedBox(
                                                                  height: 0)
                                                            ]))))
                                        : Container()
                                  ]))
                    ]))),
            Flexible(
              flex: 1,
              child: Container(),
            )
          ]))),
      Column(children: [
        Flexible(
            flex: 1,
            child: Center(
                child: !ai_loading
                    ? BreathingText(text: Strings.marketing)
                    : Container())),
        Flexible(
            flex: 4,
            child: Container()),
        Flexible(
          flex: 1,
          child: Center(
              child: Column(children:[ai_loaded
                  ? TypeEffect(strings:(Platform.isAndroid || Platform.isIOS) ? Strings.instructions : Strings.instructionsDesktop)
                  : (!ai_loading
                      ? RaisedButton(
                          child: Text(
                            'Load AI',
                            style: TextStyle(color: Colors.white),
                          ),
                          color: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5)),
                              side: BorderSide(color: Colors.white)),
                          onPressed: () {
                            setState(() {
                              ai_loading = true;
                            });

                            _controller.forward();
                          },
                        )
                      : Container()),
                      
                      (Platform.isAndroid || Platform.isIOS || ai_loading) ? Container() : Center(child:Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: Align(
              alignment: Alignment.center,
              child: Container(
                child:
                    
                      RaisedButton(child: Text("Send test message"), onPressed: _testConnection,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3.0),
                        side: BorderSide(color: Colors.white)
                    )),
                  
              )),
        ))])),
        )
      ])
    ]);
  }
}

class BreathingText extends StatefulWidget {
  final List<String> text;

  BreathingText({this.text});

  @override
  BreathingTextState createState() => BreathingTextState();
}

class BreathingTextState extends State<BreathingText>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> animation;
  int index = 0;

  @override
  void initState() {
    _controller = AnimationController(
        duration: const Duration(milliseconds: 3500), vsync: this);

    animation = Tween(begin: 1.0, end: 0.0).animate(
      new CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ),
    );

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        ++index;
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _controller.forward();
      }
    });

    _controller.forward();

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget child) => Text(
              widget.text[index % widget.text.length],
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(animation.value)),
              textAlign: TextAlign.center,
            ));
  }
}

class TypeEffect extends StatefulWidget {
  @override
  State createState() => new TypeEffectState();

  TypeEffect({this.strings});

  final List<String> strings;
}

class TypeEffectState extends State<TypeEffect> with TickerProviderStateMixin {
  Animation<int> _characterCount;
  int _stringIndex = 0;

  String get _currentString =>
      widget.strings[_stringIndex % widget.strings.length];

  void initState() {
    super.initState();
    playAnimation();
  }

  void playAnimation() async {
    for (int i = 0; i < widget.strings.length; ++i) {
      AnimationController controller = new AnimationController(
        duration: const Duration(milliseconds: 4000),
        vsync: this,
      );
      setState(() {
        _stringIndex = i;
        _characterCount = new StepTween(begin: 0, end: _currentString.length)
            .animate(
                new CurvedAnimation(parent: controller, curve: Curves.easeIn));

      });
      await controller.forward();
      controller.dispose();
      sleep(const Duration(seconds: 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    TextStyle textStyle = theme.textTheme.title
        .copyWith(fontFamily: 'Courier New', color: Colors.white, fontSize: 16);

    return AnimatedBuilder(
      animation: _characterCount,
      builder: (BuildContext context, Widget child) {
        List<Text> texts = List<Text>();
        for (int i = 0; i < max(_stringIndex, 0); ++i)
          texts.add(Text(
            widget.strings[i],
            style: textStyle,
            textAlign: TextAlign.start,
          ));
        texts.add(Text(
          _currentString.substring(0, _characterCount.value),
          style: textStyle,
          textAlign: TextAlign.start,
        ));
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: texts);
      },
    );
  }
}
