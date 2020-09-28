import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/list_items/game_item.dart';
import 'package:glitcher/models/game_model.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/utils/app_util.dart';
import 'package:glitcher/widgets/custom_loader.dart';
import 'package:glitcher/widgets/gradient_appbar.dart';

class FollowedGames extends StatefulWidget {
  final String userId;

  const FollowedGames({Key key, this.userId}) : super(key: key);
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

  bool _isPageReady = false;

  @override
  Widget build(BuildContext context) {
    return _isPageReady
        ? Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              leading: Builder(
                  builder: (context) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          child: Icon(Icons.arrow_back),
                        ),
                      )),
              flexibleSpace: gradientAppBar(),
              centerTitle: true,
              title: TextField(
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
            body: _games.length > 0
                ? ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemCount:
                        !_searching ? _games.length : _filteredGames.length,
                    itemBuilder: (BuildContext context, int index) {
                      Game game =
                          !_searching ? _games[index] : _filteredGames[index];

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
                : Center(
                    child: Text(
                    'No games followed',
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                  )),
          )
        : Scaffold(
            appBar: AppBar(
              leading: Builder(
                  builder: (context) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          child: Icon(Icons.arrow_back),
                        ),
                      )),
              flexibleSpace: gradientAppBar(),
              centerTitle: true,
            ),
            body: Center(
                child: Image.asset(
              'assets/images/glitcher_loader.gif',
              height: 150,
              width: 150,
            )),
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
    //Navigator.of(context).push(CustomScreenLoader());

    List<Game> games = await DatabaseService.getAllFollowedGames(widget.userId);
    if (mounted) {
      setState(() {
        _games = games;
        _isPageReady = true;
      });
    }

    //Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();
    _setupFeed();
  }
}
