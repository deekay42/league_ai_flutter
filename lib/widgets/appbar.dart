import 'package:flutter/material.dart';
import '../resources/Strings.dart';

class BasicAppBar extends StatelessWidget implements PreferredSizeWidget{
  final bool subscribed;
  final List<Choice> choices;

  BasicAppBar(this.subscribed, this.choices);

  final Size preferredSize = const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {

    return AppBar(
      leading: IconButton(
        icon: Icon(
          Icons.menu,
          semanticLabel: 'menu',
        ),
        onPressed: () {

          print('Menu button');
        },
      ),
      title: Text(Strings.name),
      actions: <Widget>[
        IconButton(
          icon: Icon(
            Icons.search,
            semanticLabel: 'search',
          ),
          onPressed: () {
            print('Search button');
          },
        ),
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