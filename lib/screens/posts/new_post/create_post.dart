import 'dart:io';
import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:glitcher/common_widgets/gradient_appbar.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/constants/sizes.dart';
import 'package:glitcher/constants/strings.dart';
import 'package:glitcher/models/game_model.dart';
import 'package:glitcher/screens/home/home_screen.dart';
import 'package:glitcher/screens/posts/new_post/widget/create_bottom_icon.dart';
import 'package:glitcher/screens/posts/new_post/widget/create_post_image.dart';
import 'package:glitcher/screens/posts/new_post/widget/widget_view.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/utils/app_util.dart';
import 'package:glitcher/utils/functions.dart';
import 'package:glitcher/widgets/caching_image.dart';
import 'package:provider/provider.dart';
import 'package:random_string/random_string.dart';

class CreatePost extends StatefulWidget {
  CreatePost({Key key}) : super(key: key);
  _CreatePostReplyPageState createState() => _CreatePostReplyPageState();
}

class _CreatePostReplyPageState extends State<CreatePost> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isScrollingDown = false;
  ScrollController scrollcontroller;

  File _image;
  var _video;
  var _uploadedFileURL;
  String selectedGame = "";
  GlobalKey<AutoCompleteTextFieldState<String>> autocompleteKey = GlobalKey();
  TextEditingController _textEditingController;
  var _typeAheadController = TextEditingController();

  //YoutubePlayer
  bool _showYoutubeUrl = false;
  String _youtubeId;

  bool canSubmit = false;

  @override
  void dispose() {
    scrollcontroller.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    scrollcontroller = ScrollController();
    _textEditingController = TextEditingController();
    scrollcontroller..addListener(_scrollListener);
    DatabaseService.getGameNames();
    super.initState();
  }

  _scrollListener() {
    if (scrollcontroller.position.userScrollDirection ==
        ScrollDirection.reverse) {}
  }

  void _onCrossIconPressed() {
    setState(() {
      _image = null;
    });
  }

  void _onImageIconSelcted(File file) {
    setState(() {
      _image = file;
    });
  }

  /// Submit tweet to save in firebase database
  void _submitButton() async {
    if (selectedGame.isEmpty) {
      AppUtil().customSnackBar(_scaffoldKey, 'You must choose a game category');
      return;
    }

    if (_textEditingController.text.isEmpty) {
      AppUtil().customSnackBar(_scaffoldKey, 'Post can\'t be empty');
      return;
    }

    if (_textEditingController.text == null ||
        _textEditingController.text.isEmpty ||
        _textEditingController.text.length > Sizes.maxPostChars ||
        selectedGame.isEmpty) {
      return;
    }
    glitcherLoader.showLoader(context);

    /// If tweet contain image
    /// First image is uploaded on firebase storage
    /// After sucessfull image upload to firebase storage it returns image path
    /// Add this image path to tweet model and save to firebase database
    String postId = randomAlphaNumeric(20);

    if (_video != null) {
      _uploadedFileURL =
          await AppUtil.uploadFile(_video, context, 'posts_videos/' + postId);
    } else if (_image != null) {
      //await compressAndUploadFile(_image, 'glitchertemp.jpg');
      _uploadedFileURL =
          await AppUtil.uploadFile(_image, context, 'posts_images/' + postId);
    } else {}

    await postsRef.document(postId).setData({
      'owner': Constants.currentUserID,
      'text': _textEditingController.text,
      'youtubeId': _youtubeId,
      'video': _video != null ? _uploadedFileURL : null,
      'image': _image != null ? _uploadedFileURL : null,
      'likes': 0,
      'dislikes': 0,
      'comments': 0,
      'timestamp': FieldValue.serverTimestamp(),
      'game': selectedGame
    });

    /// Checks for username in tweet description
    /// If foud sends notification to all tagged user
    /// If no user found or not compost tweet screen is closed and redirect back to home page.

    /// Hide running loader on screen
    glitcherLoader.hideLoader();

    /// Navigate back to home page
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          flexibleSpace: gradientAppBar(),
          title: Text('New Post'),
          actions: <Widget>[
            IconButton(
              onPressed: () {
                if (canSubmit) {
                  _submitButton();
                } else {
                  print('can\'t submit = $canSubmit');
                }
              },
              icon: Icon(
                Icons.send,
                color: canSubmit
                    ? switchColor(MyColors.lightPrimary, MyColors.darkPrimary)
                    : MyColors.darkGrey,
              ),
            )
          ],
          leading: new IconButton(
            icon: new Icon(Icons.arrow_back),
            onPressed: () {
              _onBackPressed();
            },
          ),
        ),
        backgroundColor: Theme.of(context).backgroundColor,
        body: Container(
          child: Stack(
            children: <Widget>[
              SingleChildScrollView(
                controller: scrollcontroller,
                child: _ComposeTweet(this),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: CreatePostBottomIconWidget(
                  textEditingController: _textEditingController,
                  onImageIconSelcted: _onImageIconSelcted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _onBackPressed() {
    return showDialog(
          context: context,
          builder: (context) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: new AlertDialog(
              title: new Text('Are you sure?'),
              content: new Text('Do you want to discard this post?'),
              actions: <Widget>[
                new GestureDetector(
                  onTap: () => Navigator.of(context).pop(false),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text("NO"),
                  ),
                ),
                SizedBox(height: 16),
                new GestureDetector(
                  onTap: () =>
                      Navigator.of(context).pushReplacementNamed('/home'),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text("YES"),
                  ),
                ),
              ],
            ),
          ),
        ) ??
        false;
  }
}

class _ComposeTweet extends WidgetView<CreatePost, _CreatePostReplyPageState> {
  _ComposeTweet(this.viewState) : super(viewState);

  final _CreatePostReplyPageState viewState;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Sizes.fullHeight(context),
      padding: EdgeInsets.only(left: 10, right: 10, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox.shrink(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CacheThisImage(
                    imageUrl: loggedInProfileImageURL,
                    imageShape: BoxShape.circle,
                    width: Sizes.sm_profile_image_w,
                    height: Sizes.sm_profile_image_h,
                    defaultAssetImage: Strings.default_profile_image,
                  )),
              SizedBox(
                width: 10,
              ),
              Expanded(
                child: TextField(
                  onChanged: (text) {
                    if (text.length > Sizes.maxPostChars) {
                      viewState.setState(() {
                        viewState.canSubmit = false;
                      });
                    } else {
                      viewState.setState(() {
                        viewState.canSubmit = true;
                      });
                    }
                    // Mention Users
                  },
                  maxLength: Sizes.maxPostChars,
                  minLines: 5,
                  maxLines: 15,
                  autofocus: true,
                  maxLengthEnforced: true,
                  controller: viewState._textEditingController,
                  decoration: InputDecoration(
                      counterText: "",
                      border: InputBorder.none,
                      hintText: 'What\'s in your mind?'),
                  style: TextStyle(fontSize: 18),
                ),
              )
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: TypeAheadFormField(
              textFieldConfiguration: TextFieldConfiguration(
                  controller: viewState._typeAheadController,
                  decoration: InputDecoration(
                      icon: Icon(Icons.videogame_asset),
                      hintStyle: TextStyle(
                        color: MyColors.darkGrey,
                      ),
                      hintText: 'Enter Game name')),
              suggestionsCallback: (pattern) {
                return DatabaseService.searchGames(pattern);
              },
              itemBuilder: (context, suggestion) {
                Game game = suggestion as Game;

                return ListTile(
                  title: Text(game.fullName),
                );
              },
              onSuggestionSelected: (suggestion) {
                viewState._typeAheadController.text =
                    (suggestion as Game).fullName;
                viewState.setState(() {
                  viewState.selectedGame = viewState._typeAheadController.text;
                });
              },
              validator: (value) {
                if (value.isEmpty) {
                  return 'Please select a game';
                }
                return '';
              },
              onSaved: (value) => viewState.selectedGame = value,
            ),
          ),
          Flexible(
            child: Stack(
              children: <Widget>[
                CreatePostImage(
                  image: viewState._image,
                  onCrossIconPressed: viewState._onCrossIconPressed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}