import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:glitcher/common_widgets/gradient_appbar.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/models/game_model.dart';
import 'package:glitcher/screens/games/game_item.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/utils/functions.dart';

class GamesScreen extends StatefulWidget {
  @override
  _GamesScreenState createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  List<Game> _games = [];
  ScrollController _scrollController = ScrollController();

  TextEditingController _typeAheadController = TextEditingController();

  String lastVisibleGameSnapShot;

  GlobalKey<ScaffoldState> _scaffoldKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      floatingActionButton: FloatingActionButton(
        child: Icon(
          Icons.email,
        ),
        onPressed: () async {
          //Navigator.of(context).pushNamed('/new-game');
//
//          final Email email = Email(
//            body: 'ARK Survival evolved.',
//            subject: 'Game suggestion',
//            recipients: ['ahmednab93@gmail.com'],
//            isHTML: false,
//          );

//          await FlutterEmailSender.send(email);

        Navigator.of(context).pushNamed('/suggestion', arguments: {'initial_title': 'New game suggestion', 'initial_details': 'I (${Constants.loggedInUser.username}) suggest adding the following game: '});
          Functions.showInSnackBar(context, _scaffoldKey, "Suggestion sent ");
        },
      ),
      appBar: AppBar(
        leading: Builder(
            builder: (context) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InkWell(
                    onTap: () => Scaffold.of(context).openDrawer(),
                    child: Icon(IconData(58311, fontFamily: 'MaterialIcons')),
                  ),
                )),
        title: Text("Games"),
        flexibleSpace: gradientAppBar(),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search games',
                filled: false,
                prefixIcon: Icon(
                  Icons.search,
                  size: 28.0,
                ),
                suffixIcon: IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      _typeAheadController.clear();
                      _setupFeed();
                    }),
              ),
              controller: _typeAheadController,
              onChanged: (text) {
                if (text.isEmpty) {
                  _setupFeed();
                } else {
                  _searchGames(text);
                }
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              itemCount: _games.length,
              itemBuilder: (BuildContext context, int index) {
                Game game = _games[index];

                return StreamBuilder(
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                  return Column(
                    children: <Widget>[
                      GameItem(key: ValueKey(game.id), game: game),
                      Divider(height: .5, color: Colors.grey)
                    ],
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  _setupFeed() async {
    List<Game> games = await DatabaseService.getGames();
    //await DatabaseService.getGameNames();
    setState(() {
      _games = games;
      this.lastVisibleGameSnapShot = games.last.fullName;
    });
  }

  _searchGames(String text) async {
    List<Game> games = await DatabaseService.searchGames(text.toLowerCase());
    setState(() {
      _games = games;
    });
  }

  @override
  void initState() {
    super.initState();

    ///Set up listener here
    _scrollController.addListener(() {
      if (_scrollController.offset >=
              _scrollController.position.maxScrollExtent &&
          !_scrollController.position.outOfRange) {
        print('reached the bottom');
        nextGames();
      } else if (_scrollController.offset <=
              _scrollController.position.minScrollExtent &&
          !_scrollController.position.outOfRange) {
        print("reached the top");
      } else {}
    });
    _setupFeed();
  }

  nextGames() async {
    var games = await DatabaseService.getNextGames(lastVisibleGameSnapShot);
    if (games.length > 0) {
      setState(() {
        games.forEach((element) => _games.add(element));
        this.lastVisibleGameSnapShot = games.last.fullName;
      });
    }
  }
}
