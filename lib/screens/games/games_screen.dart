import 'package:flutter/material.dart';
import 'package:glitcher/screens/games/game_item.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/models/game_model.dart';

class GamesScreen extends StatefulWidget {
  @override
  _GamesScreenState createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  List<Game> _games = [];
  ScrollController _scrollController = ScrollController();

  TextEditingController _typeAheadController = TextEditingController();

  String lastVisibleGameSnapShot;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: Icon(
          Icons.add,
        ),
        onPressed: () {
          Navigator.of(context).pushNamed('/new-game');
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
