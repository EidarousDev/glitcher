import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/models/game_model.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/utils/constants.dart';

class GameItem extends StatefulWidget {
  final Game game;

  GameItem({
    Key key,
    @required this.game,
  }) : super(key: key);

  @override
  _GameItemState createState() => _GameItemState();
}

class _GameItemState extends State<GameItem> {
  String followBtnText;

  String snackbarText;

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
      padding: EdgeInsets.all(7),
      child: ListTile(
        contentPadding: EdgeInsets.all(0),
        leading: Image(
          width: 50,
          height: 50,
          image: NetworkImage(
            "${widget.game.image}",
          ),
        ),
        title: Row(
          children: <Widget>[
            Text(
              "${widget.game.fullName}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        subtitle: Text(
          "${widget.game.genre}",
          style: TextStyle(
            fontWeight: FontWeight.w300,
            fontSize: 11,
          ),
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            ButtonTheme(
              height: 20,
              minWidth: 40,
              child: MaterialButton(
                height: 30,
                onPressed: () {
                  DatabaseService.followGame(widget.game.id);
                  followUnfollow();
                },
                textColor: Colors.white,
                color: Constants.badgeColor,
                child: Text(followBtnText == null ? '' : followBtnText),
              ),
            )
          ],
        ),
        onTap: () {
          Navigator.of(context).pushNamed('/game-screen', arguments: {
            'game': widget.game,
          });
        },
      ),
    );
  }

  followUnfollow() async {
    DocumentSnapshot game = await usersRef
        .document(Constants.currentUserID)
        .collection('followedGames')
        .document(widget.game.id)
        .get();
    if (game.exists) {
      DatabaseService.unFollowGame(widget.game.id);
      setState(() {
        followBtnText = 'Follow';
        final SnackBar snackBar = SnackBar(
          duration: Duration(seconds: 1),
          content: Text(
            'Game unfollowed',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blue,
        );
        Scaffold.of(context).showSnackBar(snackBar);
      });
    } else {
      DatabaseService.followGame(widget.game.id);
      setState(() {
        followBtnText = 'Unfollow';
        final SnackBar snackBar = SnackBar(
          duration: Duration(seconds: 1),
          content: Text(
            'Game followed',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blue,
        );
        Scaffold.of(context).showSnackBar(snackBar);
      });
    }
  }

  checkStates() async {
    DocumentSnapshot game = await usersRef
        .document(Constants.currentUserID)
        .collection('followedGames')
        .document(widget.game.id)
        .get();
    if (game.exists) {
      setState(() {
        followBtnText = 'Unfollow';
      });
    } else {
      setState(() {
        followBtnText = 'Follow';
      });
    }
  }

  @override
  void initState() {
    checkStates();
    super.initState();
  }
}
