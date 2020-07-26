import 'package:flutter/material.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/list_items/game_item.dart';
import 'package:glitcher/models/game_model.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/utils/functions.dart';
import 'package:glitcher/widgets/gradient_appbar.dart';

class GamesScreen extends StatefulWidget {
  @override
  _GamesScreenState createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  List<Game> _games = [];
  List<Game> _filteredGames = [];

  bool _searching = false;
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
          Navigator.of(context).pushNamed('/suggestion', arguments: {
            'initial_title': 'New game suggestion',
            'initial_details':
                'I (${Constants.loggedInUser.username}) suggest adding the following game: '
          });
          Functions.showInSnackBar(context, _scaffoldKey, "Suggestion sent ");
        },
      ),
      appBar: AppBar(
        leading: Builder(
            builder: (context) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Icons.arrow_back),
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
                suffixIcon: _searching
                    ? IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          _typeAheadController.clear();
                          setState(() {
                            _games = [];
                            _filteredGames = [];
                            _searching = false;
                          });
                          _setupFeed();
                        })
                    : null,
              ),
              controller: _typeAheadController,
              onChanged: (text) {
                _filteredGames = [];
                if (text.isEmpty) {
                  _setupFeed();
                  setState(() {
                    _filteredGames = [];
                    _searching = false;
                  });
                } else {
                  setState(() {
                    _searching = true;
                  });
                  _searchGames(text);
                }
              },
            ),
          ),
          Expanded(
            child: !_searching
                ? ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemCount: _games.length,
                    itemBuilder: (BuildContext context, int index) {
                      Game game = _games[index];

                      return StreamBuilder(builder:
                          (BuildContext context, AsyncSnapshot snapshot) {
                        return Column(
                          children: <Widget>[
                            GameItem(key: ValueKey(game.id), game: game),
                            Divider(height: .5, color: Colors.grey)
                          ],
                        );
                      });
                    },
                  )
                : ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemCount: _filteredGames.length,
                    itemBuilder: (BuildContext context, int index) {
                      Game game = _filteredGames[index];

                      return StreamBuilder(builder:
                          (BuildContext context, AsyncSnapshot snapshot) {
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
      _filteredGames = games;
      this.lastVisibleGameSnapShot = games.last.fullName;
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
        !_searching ? nextGames() : nextSearchGames(_typeAheadController.text);
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
      print('lastVisibleGameSnapShot: $lastVisibleGameSnapShot');
    }
  }

  nextSearchGames(String text) async {
    var games =
        await DatabaseService.nextSearchGames(lastVisibleGameSnapShot, text);
    if (games.length > 0) {
      setState(() {
        games.forEach((element) => _filteredGames.add(element));
        this.lastVisibleGameSnapShot = games.last.fullName;
      });
    }
  }
}
