import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../model/item.dart';
import '../model/champion.dart';
import '../resources/Colors.dart';

bool notNull(Object o) => o != null;

class SlidingList extends StatefulWidget {
  final List<Widget> children;
  final String title;
  final Offset origin;
  final Animation<double> animationController;
  final Axis scrollDir;
  final bool showLines;

  SlidingList(
      {@required this.title,
      @required this.children,
      @required this.animationController,
      this.scrollDir = Axis.vertical,
      this.showLines = true,
      this.origin = const Offset(0.0, 20.0)});

  @override
  _SlidingListState createState() => _SlidingListState();
}

class _SlidingListState extends State<SlidingList>
    with TickerProviderStateMixin {
  GlobalKey listKey;
  GlobalKey builderKey;

  GlobalKey key1 = GlobalKey(),
      key2 = GlobalKey(),
      key3 = GlobalKey(),
      key4 = GlobalKey();
  SlidingListAnimations animations;
  bool dimsObtained;

  @override
  void initState() {
    super.initState();
    animations = SlidingListAnimations(
        controller: widget.animationController,
        origin: widget.origin,
        listLength: widget.children.length);
    listKey = GlobalKey();
    builderKey = GlobalKey();
    dimsObtained = false;
    WidgetsBinding.instance.addPostFrameCallback(_afterLayout);
  }

  @override
  void didUpdateWidget(SlidingList oldWidget) {
    super.didUpdateWidget(oldWidget);

    animations = SlidingListAnimations(
        controller: widget.animationController,
        origin: widget.origin,
        listLength: widget.children.length);
    dimsObtained = false;
    listKey = GlobalKey();
    builderKey = GlobalKey();
    WidgetsBinding.instance.addPostFrameCallback(_afterLayout);
  }

  void _afterLayout(_) {
    if (!dimsObtained) {
      final RenderBox renderBoxList = listKey.currentContext.findRenderObject();
      final sizeList = renderBoxList.size;
      //final RenderBox renderBoxBuilder = listKey.currentContext.findRenderObject();
      //final sizeBuilder = renderBoxBuilder.size;

      setState(() {
        animations.setDivDy(sizeList.height / 2);
        animations.setDivLength(sizeList.width);
        dimsObtained = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        key: builderKey,
        animation: animations.controller,
        builder: (BuildContext context, Widget child) => _buildContent());
  }

  void printSize(var key) {
    final RenderBox renderBoxList = key.currentContext.findRenderObject();
    final size = renderBoxList.size;
    print(size);
  }

  Widget _buildContent() {
    if (widget.children == null || widget.children.isEmpty) {
      return Container();
    }

    final ThemeData theme = Theme.of(context);
    int count = 0;
    ListView mainList = ListView(
        scrollDirection: widget.scrollDir,
        key: listKey,
        shrinkWrap: true,
//        padding: EdgeInsets.all(8.0),
        children: widget.children.map((child) {
          return SlidingListItem(
              slider: animations.sliders[count++],
              child: child,
              last: count >= animations.sliders.length);
        }).toList());

    return LayoutBuilder(builder: (context, constraints) {
      animations.setDivLength(constraints.maxWidth);
      return Column(
          key: key2,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.title,
              style: theme.textTheme.subtitle,
              maxLines: 1,
            ),
            SizedBox(
              height: 4,
            ),
            SlideTransition(
                position: animations.upperDivDy,
                child: Container(
                  color: Colors.white.withOpacity(widget.showLines ? 1.0 : 0.0),
                  width: animations.dividerLength.value,
                  height: 1.0,
                )),
            Flexible(fit: FlexFit.loose, child: mainList),
            SlideTransition(
                position: animations.lowerDivDy,
                child: Container(
                  color: Colors.white.withOpacity(widget.showLines ? 1.0 : 0.0),
                  width: animations.dividerLength.value,
                  height: 1.0,
                )),
          ]);
    });
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

//class MyItemListItem extends MyListItem {
//  final Item item;
//
//  MyItemListItem({this.item, bool last = false}) : super(last: last);
//
//  Widget build(BuildContext context) {
//    var theme = Theme.of(context);
//    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
//
//      Column(
//        crossAxisAlignment: CrossAxisAlignment.center,
//        children: [
//          Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
//            ClipRRect(
//                borderRadius: BorderRadius.all(
//                  Radius.circular(10.0),
//                ),
//                child: Image.asset(
//                  item.img,
//                  height: 50,
//                  width: 50,
//                  fit: BoxFit.contain,
//                )),
//            SizedBox(width: 20),
//            Container(width:150, child:Text(
//                  item.name,
//                  style: theme.textTheme.body1
//                )),
//          ]),
//          last
//              ? null
//              : Column(children: [
//                  SizedBox(
//                    height: 5,
//                  ),
//                  Row(children: [
//                    SizedBox(
//                      width: 10,
//                    ),
//                    Text("V",
//                        style: TextStyle(
//                            fontWeight: FontWeight.w200,
//                            fontSize: 12.0,
//                            color: secondaryText)),
//                  ]),
//                  SizedBox(
//                    height: 5,
//                  ),
//                ]),
//        ].where(notNull).toList(),
//      )
//    ]);
//  }
//}

class ItemListItem extends MyListItem {
  final Item item;

  ItemListItem({this.item, bool last = false}) : super(last: last);

  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Expanded(child:Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
            ClipRRect(
                borderRadius: BorderRadius.all(
                  Radius.circular(10.0),
                ),
                child: Image.asset(
                  item.img,
                  fit: BoxFit.fitHeight,
                )),
            last
              ? Container()
            : SizedBox(width: 20),
          ]),
//          last
//              ? null
//              : Column(children: [
//            SizedBox(
//              height: 5,
//            ),
//            Row(children: [
//              SizedBox(
//                width: 10,
//              ),
//              Text("V",
//                  style: TextStyle(
//                      fontWeight: FontWeight.w200,
//                      fontSize: 12.0,
//                      color: secondaryText)),
//            ]),
//            SizedBox(
//              height: 5,
//            ),
//          ]),
        ].where(notNull).toList(),
      ))
    ]);
  }
}

class ChampListItem extends MyListItem {
  final Champion champ1, champ2;
  final int kills1, kills2;
  final int deaths1, deaths2;
  final int assists1, assists2;
  final int level1, level2;
//  final int currentGold;
//  final List<Item> champItems;
  final bool isMyChamp;

  ChampListItem(
      {this.champ1,
      this.champ2,
      this.kills1,
      this.kills2,
      this.deaths1,
      this.deaths2,
      this.assists1,
      this.assists2,
      this.level1,
      this.level2,
//      this.currentGold,
//      this.champItems,
      this.isMyChamp,
      bool last = false})
      : super(last: last);

//  List<Widget> buildItemsList() {
//    List<Widget> row = [];
//
//    for (var item in champItems)
//      row.add(ClipRRect(
//          borderRadius: BorderRadius.all(
//            Radius.circular(10.0),
//          ),
//          child: Image.asset(
//            item.img,
//            height: 25,
//            width: 25,
//            fit: BoxFit.contain,
//          )));
//    return row;
//  }

  Widget build(BuildContext context) {
    var theme = Theme.of(context);

//    var itemsList = buildItemsList();
//  itemsList.insert(0, SizedBox(width: 10,));

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [

      Column(children: [
        SizedBox(height:5),
        Row(children: [
          Column(children: [
            ClipRRect(
                borderRadius: BorderRadius.all(
                  Radius.circular(10.0),
                ),
                child: Image.asset(
                  champ1.img,
                  height: isMyChamp ? 50 : 30,
                  width: isMyChamp ? 50 : 30,
                  fit: BoxFit.contain,
                )),
          ]),
          Row(children:[
            SizedBox(width:isMyChamp? 10 : 30),
            Text(level1.toString(), style:theme.textTheme.subtitle),
            SizedBox(width:level1 > 9 ? 10 : 16),
            Text(kills1.toString() + "/"+ deaths1.toString() + "/" + assists1.toString(), style:theme.textTheme.body2),

          ])

//                  isMyChamp ? Column(crossAxisAlignment: CrossAxisAlignment.start,
//                      children:[
//                        Row(children:itemsList),
//                        SizedBox(height:5),
//                        Text(currentGold.toString() + " g"),
//
//                      ]) : Container()
        ]),
      last?SizedBox(height:5):Container()]),
      Expanded(child: Container()),
      Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
            Row(children:[
              Text(kills2.toString() + "/"+ deaths2.toString() + "/" + assists2.toString(), style:theme.textTheme.body2),
              SizedBox(width:level2 > 9 ? 10 : 16),
              Text(level2.toString(), style:theme.textTheme.subtitle),
              SizedBox(width:isMyChamp? 10 : 30),
            ]),
            ClipRRect(
                borderRadius: BorderRadius.all(
                  Radius.circular(10.0),
                ),
                child: Image.asset(
                  champ2.img,
                  height: isMyChamp ? 50 : 30,
                  width: isMyChamp ? 50 : 30,
                  fit: BoxFit.contain,
                )),
          ]),
          last
              ? null
              : Column(children: [
//            SizedBox(
//              height: 5,
//            ),
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
                0.55,
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
        ),
        dividerLength = new Tween(begin: 0.0, end: 200.0).animate(
          new CurvedAnimation(
            parent: controller,
            curve: new Interval(
              0.0,
              0.25,
              curve: Curves.linear,
            ),
          ),
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

  static double calcLenForInterval(double overlap, int totalElements) {
    return 1.0 / (1 + (1 - overlap) * (totalElements - 1));
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
          0.5,
          0.55,
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
            0.55,
            0.65,
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
            0.55,
            0.65,
            curve: Curves.ease,
          )),
    );
  }

  final Animation<double> controller;
  final int listLength;
  List<Animation<Offset>> sliders;
  Animation<double> dividerLength;
  Animation<Offset> upperDivDy;
  Animation<Offset> lowerDivDy;
  final Animation<double> listCurve;
  final Offset origin;
}
