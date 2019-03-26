import 'package:flutter/material.dart';
import '../resources/Strings.dart';

class BasicAppBar extends StatelessWidget implements PreferredSizeWidget{
  final bool subscribed;
  final List<Choice> choices;
  final bool backArrow;

  BasicAppBar(this.subscribed, this.choices, this.backArrow);

  final Size preferredSize = const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
ThemeData theme = Theme.of(context);
    return AppBar(
      leading: backArrow ? IconButton(
          icon: new Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          }) : Container(),
      centerTitle: true,
      title: Text(Strings.name, style: theme.textTheme.headline),
      actions:  choices == null || choices.isEmpty ? [Container()] : <Widget>[
        PopupMenuButton<Choice>(
          onSelected: (Choice choice) {choice.action();},
          itemBuilder: (BuildContext context) {
            return choices.map((Choice choice) {
              return PopupMenuItem<Choice>(
                value: choice,
                child: Text(choice.title),
              );
            }).toList();
          },
        ),
      ],
    );
  }
}

class Choice {
  const Choice({this.title, this.icon, this.action});

  final String title;
  final IconData icon;
  final void Function() action;
}