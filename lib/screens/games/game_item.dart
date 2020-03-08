import 'package:flutter/material.dart';
import 'package:glitcher/models/game_model.dart';

class GameItem extends StatefulWidget {
  final Game game;

  GameItem(
      {Key key,
        @required this.game,})
      : super(key: key);

  @override
  _GameItemState createState() => _GameItemState();
}

class _GameItemState extends State<GameItem> {

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0),
      child: InkWell(
        child: _buildItem(widget.game),
        onTap: () {},
      ),
    );
  }

  _buildItem(Game game) {
    return Container(
      child: Container(
        padding: EdgeInsets.all(7),
        child: ListTile(
          contentPadding: EdgeInsets.all(0),
          leading: Image(
            image: NetworkImage(
              "${widget.game.image}",
            ),
          ),
          title: Text(
            "${widget.game.fullName}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text("${widget.game.description}"),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              SizedBox(height: 10),
              Text(
                "${widget.game.genre}"
                ,
                style: TextStyle(
                  fontWeight: FontWeight.w300,
                  fontSize: 11,
                ),
              ),
              SizedBox(height: 5),

            ],
          ),
          onTap: () {

          },
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }
}
