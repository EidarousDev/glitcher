import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/screens/games/game_item.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/models/game_model.dart';
import 'package:glitcher/utils/constants.dart';

class GamesScreen extends StatefulWidget {
  @override
  _GamesScreenState createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  List<Game> _games = [];
  ScrollController _scrollController = ScrollController();
  GlobalKey<AutoCompleteTextFieldState<String>> autocompleteKey =
  new GlobalKey();

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
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: AutoCompleteTextField<String>(
                clearOnSubmit: false,
                key: autocompleteKey,
                suggestions: Constants.games,
                decoration: InputDecoration(
                    icon: Icon(Icons.videogame_asset), hintText: "Game full name"),
                itemFilter: (item, query) {
                  return item.toLowerCase().startsWith(query.toLowerCase());
                },
                itemSorter: (a, b) {
                  return a.compareTo(b);
                },
                itemSubmitted: (item) {

                },
                onFocusChanged: (hasFocus) {},
                itemBuilder: (context, item) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(item),
                  );
                },
              ),
            ),
            ListView.builder(
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
          ],
        ),
      ),
    );
  }

  _setupFeed() async {
    List<Game> games = await DatabaseService.getGames();
    await DatabaseService.getGameNames();
    setState(() {
      _games = games;
    });
  }

  @override
  void initState() {
    super.initState();
    _setupFeed();
  }
}
