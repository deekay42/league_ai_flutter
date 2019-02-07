import 'package:flutter/material.dart';

import '../model/item.dart';
import '../resources/Colors.dart';

bool notNull(Object o) => o != null;

class SlidingList extends StatefulWidget {
  final List<Widget> children;
  final String title;
  final Offset origin;
  final AnimationController animationController;

  SlidingList(
      {@required this.title,
      @required this.children,
      @required this.animationController,
      this.origin = const Offset(0.0, 20.0)});

  @override
  _SlidingListState createState() => _SlidingListState();
}

class _SlidingListState extends State<SlidingList>
    with TickerProviderStateMixin {
  GlobalKey listKey = GlobalKey();
  SlidingListAnimations animations;
  bool dimsObtained = false;

  @override
  void initState() {
    super.initState();

    animations = SlidingListAnimations(
        controller: widget.animationController,
        origin: widget.origin,
        listLength: widget.children.length);

    WidgetsBinding.instance.addPostFrameCallback(_afterLayout);
  }

  void _afterLayout(_) {
    if (!dimsObtained) {
      final RenderBox renderBoxList = listKey.currentContext.findRenderObject();
      final sizeList = renderBoxList.size;

      setState(() {
        animations.setDivDy(sizeList.height / 2);
        dimsObtained = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: animations.controller,
        builder: (BuildContext context, Widget child) => _buildContent());
  }

  Widget _buildContent() {
    if (widget.children == null || widget.children.isEmpty) {
      return Container();
    }

    final ThemeData theme = Theme.of(context);
    int count = 0;

    ListView mainList = ListView(
        key: listKey,
        shrinkWrap: true,
        padding: EdgeInsets.all(8.0),
        children: widget.children.map((child) {
          return SlidingListItem(
              slider: animations.sliders[count++],
              child: child,
              last: count >= animations.sliders.length);
        }).toList());
    return Column(children: [
      SizedBox(
        height: 12,
      ),
      Text(
        widget.title,
        style: theme.textTheme.subtitle,
        maxLines: 1,
      ),
      SizedBox(
        height: 12,
      ),
      LayoutBuilder(builder: (context, constraints) {
        animations.setDivLength(constraints.maxWidth);
        return Container(
            child: Column(children: [
          SlideTransition(
              position: animations.upperDivDy,
              child: Container(
                color: Colors.white,
//          margin: const EdgeInsets.symmetric(vertical: 16.0),
                width: animations.dividerLength.value,
                height: 1.0,
              )),
          mainList,
          SlideTransition(
              position: animations.lowerDivDy,
              child: Container(
                color: Colors.white,
//          margin: const EdgeInsets.symmetric(vertical: 16.0),
                width: animations.dividerLength.value,
                height: 1.0,
              )),
        ]));
      })
    ]);
  }
}

class SlidingListItem extends StatelessWidget {
  final Animation<Offset> slider;
  final Widget child;

  final bool last;

  SlidingListItem({@required this.slider, @required this.child, this.last});

  @override
  Widget build(BuildContext context) {
    return SlideTransition(position: slider, child: child);
  }
}

abstract class MyListItem extends StatelessWidget {
  final bool last;
  MyListItem({this.last = false});
}

class MyItemListItem extends MyListItem {
  final Item item;

  MyItemListItem({this.item, bool last = false}) : super(last: last);

  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
            Image.asset(
              item.img,
              height: 50,
              width: 50,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 20),
            Container(
                width: 100,
                child: Text(
                  item.name,
                  style: theme.textTheme.caption,
                  maxLines: 1,
                )),
          ]),
          last
              ? null
              : Column(children: [
                  SizedBox(
                    height: 5,
                  ),
                  Row(children: [
                    SizedBox(
                      width: 10,
                    ),
                    Text("V",
                        style: TextStyle(
                            fontWeight: FontWeight.w200,
                            fontSize: 12.0,
                            color: secondaryText)),
                  ]),
                  SizedBox(
                    height: 5,
                  ),
                ]),
        ].where(notNull).toList(),
      )
    ]);
  }
}

class SlidingListAnimations {
  SlidingListAnimations(
      {@required this.controller,
      @required this.origin,
      @required this.listLength})
      : listCurve = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
              parent: controller,
              curve: Interval(
                0.5,
                1.0,
                curve: Curves.ease,
              )),
        ),
        upperDivDy = Tween<Offset>(
          begin: Offset.zero,
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
              parent: controller,
              curve: Interval(
                0.25,
                0.5,
                curve: Curves.ease,
              )),
        ),
        lowerDivDy = Tween<Offset>(
          begin: Offset.zero,
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
              parent: controller,
              curve: Interval(
                0.25,
                0.5,
                curve: Curves.ease,
              )),
        ) {
    this.sliders = List.generate(
      listLength,
      (i) => Tween<Offset>(
            begin: origin,
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: listCurve,
              curve: Interval(
                calcStartingPointForInterval(
                    i, calcLenForInterval(0.8, listLength), 0.8),
                calcStartingPointForInterval(
                        i, calcLenForInterval(0.8, listLength), 0.8) +
                    calcLenForInterval(0.8, listLength),
                curve: Curves.ease,
              ),
            ),
          ),
    );
  }

  static double calcLenForInterval(double overlap, int total_elements) {
    return 1.0 / (1 + (1 - overlap) * (total_elements - 1));
  }

  static double calcStartingPointForInterval(
      int i, double len, double overlap) {
    return i * len * (1 - overlap);
  }

  void setDivLength(double maxLength) {
    dividerLength = new Tween(begin: 0.0, end: maxLength).animate(
      new CurvedAnimation(
        parent: controller,
        curve: new Interval(
          0.0,
          0.25,
          curve: Curves.linear,
        ),
      ),
    );
  }

  void setDivDy(double dy) {
    upperDivDy = Tween<Offset>(
      begin: Offset(0, dy),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
          parent: controller,
          curve: Interval(
            0.25,
            0.5,
            curve: Curves.ease,
          )),
    );
    lowerDivDy = Tween<Offset>(
      begin: Offset(0, -dy),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
          parent: controller,
          curve: Interval(
            0.25,
            0.5,
            curve: Curves.ease,
          )),
    );
  }

  final AnimationController controller;
  final int listLength;
  List<Animation<Offset>> sliders;
  Animation<double> dividerLength;
  Animation<Offset> upperDivDy;
  Animation<Offset> lowerDivDy;
  final Animation<double> listCurve;
  final Offset origin;
}
