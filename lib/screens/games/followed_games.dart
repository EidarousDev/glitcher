import 'package:flutter/material.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/list_items/game_item.dart';
import 'package:glitcher/models/game_model.dart';
import 'package:glitcher/utils/app_util.dart';
import 'package:glitcher/widgets/gradient_appbar.dart';

class FollowedGames extends StatefulWidget {
  @override
  _FollowedGamesState createState() => _FollowedGamesState();
}

class _FollowedGamesState extends State<FollowedGames> {
  GlobalKey<ScaffoldState> _scaffoldKey;
  List<Game> _games = [];
  List<Game> _filteredGames = [];

  bool _searching = false;
  TextEditingController _typeAheadController = TextEditingController();
  ScrollController _scrollController = ScrollController();

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
                'I (${Constants.currentUser.username}) suggest adding the following game: '
          });
          AppUtil.showSnackBar(context, _scaffoldKey, "Suggestion sent ");
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
        title: Text("Followed Games"),
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

  _searchGames(String text) async {
    List<Game> games = _games
        .where((element) =>
            element.fullName.toLowerCase().contains(text.toLowerCase()))
        .toList();
    setState(() {
      _filteredGames = games;
    });
  }

  _setupFeed() async {
    setState(() {
      _games = Constants.followedGames;
    });
  }

  @override
  void initState() {
    _setupFeed();
    super.initState();
  }
}
