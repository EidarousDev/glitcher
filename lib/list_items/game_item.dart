import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/models/game_model.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/utils/app_util.dart';

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

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
        title: Flex(
          direction: Axis.horizontal,
          children: [
            Expanded(
              child: Text(
                widget.game.fullName,
                maxLines: 2,
                overflow: TextOverflow.fade,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: widget.game.genres.length > 0
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                    SizedBox(
                      height: 3,
                    ),
                    Text(
                      "${widget.game.genres} - ${widget.game.id}",
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        fontSize: 11,
                      ),
                    ),
                  ])
            : null,
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
                color: MyColors.badgeColor,
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
      });
      AppUtil.showSnackBar(context, _scaffoldKey, 'Game unfollowed');
    } else {
      DatabaseService.followGame(widget.game.id);
      setState(() {
        followBtnText = 'Unfollow';
      });
      AppUtil.showSnackBar(context, _scaffoldKey, 'Game followed');
    }
    DatabaseService.getFollowedGames();
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
      if (mounted) {
        setState(() {
          followBtnText = 'Follow';
        });
      }
    }
  }

  @override
  void initState() {
    checkStates();
    super.initState();
  }
}
