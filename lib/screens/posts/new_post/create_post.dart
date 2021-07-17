import 'dart:io';

import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/constants/sizes.dart';
import 'package:glitcher/constants/strings.dart';
import 'package:glitcher/models/game_model.dart';
import 'package:glitcher/models/post_model.dart';
import 'package:glitcher/screens/posts/new_post/widget/create_bottom_icon.dart';
import 'package:glitcher/screens/posts/new_post/widget/create_post_image.dart';
import 'package:glitcher/screens/posts/new_post/widget/create_post_video.dart';
import 'package:glitcher/screens/posts/new_post/widget/widget_view.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/utils/app_util.dart';
import 'package:glitcher/utils/functions.dart';
import 'package:glitcher/widgets/caching_image.dart';
import 'package:glitcher/widgets/custom_loader.dart';
import 'package:glitcher/widgets/custom_widgets.dart';
import 'package:glitcher/widgets/gradient_appbar.dart';
import 'package:path/path.dart' as path;
import 'package:random_string/random_string.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class CreatePost extends StatefulWidget {
  String selectedGame;
  CreatePost({Key key, this.selectedGame}) : super(key: key);
  _CreatePostReplyPageState createState() => _CreatePostReplyPageState();
}

class _CreatePostReplyPageState extends State<CreatePost> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isScrollingDown = false;
  ScrollController scrollController;

  File _image;
  File _video;
  var _uploadedFileURL;
  GlobalKey<AutoCompleteTextFieldState<String>> autocompleteKey = GlobalKey();
  TextEditingController _textEditingController;
  var _typeAheadController = TextEditingController();
  VideoPlayerController videoPlayerController;
  //YoutubePlayer
  //bool _showYoutubeUrl = false;
  String _youtubeId;
  YoutubePlayerController _youtubeController =
      YoutubePlayerController(initialVideoId: 'youtube');

  bool canSubmit = false;

  String _mentionText = '';
  String _hashtagText = '';
  bool _isNewHashtag = true;

  var words = [];

  CreatePostVideo createPostVideo;

  @override
  void dispose() {
    scrollController.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    if (Constants.userFriends.length == 0) {
      DatabaseService.getAllMyFriends();
    }

    scrollController = ScrollController();

    // createPostVideo = CreatePostVideo(
    //   video: _video,
    //   onCrossIconPressed: _onCrossIconPressed,
    // );

    _textEditingController = TextEditingController();
    _typeAheadController.text = widget.selectedGame;
    scrollController..addListener(_scrollListener);
    //DatabaseService.getGameNames();
    super.initState();
  }

  _scrollListener() {
    if (scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {}
  }

  void _onCrossIconPressed() {
    setState(() {
      _image = null;
      _video = null;
    });
  }

  void _onImageIconSelected(File file) {
    print('File size: ${file.lengthSync()}');
    if (file.lengthSync() / (1024 * 1024) == 3) {
      AppUtil.showSnackBar(
          context, _scaffoldKey, 'Image exceeded 3 Megabytes limit.');
    } else {
      setState(() {
        _image = file;
      });
    }
  }

  void _onVideoIconSelected(File file) async {
    print('File size: ${file.lengthSync()}');
    if (file.lengthSync() / (1024 * 1024) == 10) {
      customSnackBar(_scaffoldKey, 'Video exceeded 10 Megabytes limit.');
    } else {
      setState(() {
        print('File xx: ${file.path}');
        _video = file;
      });
      videoPlayerController = VideoPlayerController.file(File(_video.path))
        ..initialize().then((value) {
          ChewieController chewieController = ChewieController(
            aspectRatio: videoPlayerController.value.aspectRatio,
            videoPlayerController: videoPlayerController,
            autoPlay: false,
            looping: false,
          );
          Widget playerWidget = Container(
            child: AspectRatio(
              aspectRatio: videoPlayerController.value.aspectRatio,
              child: Chewie(
                controller: chewieController,
              ),
            ),
          );
          setState(() {
            createPostVideo = CreatePostVideo(
              video: _video,
              playerWidget: playerWidget,
              onCrossIconPressed: _onCrossIconPressed,
            );
          });
        });
    }
  }

  /// Submit tweet to save in firebase database
  void _submitButton() async {
    if (!AppUtil.englishOnly(_textEditingController.text)) {
      AppUtil.showSnackBar(context, _scaffoldKey, 'Only English is allowed.');
      return;
    }

    if (widget.selectedGame.isEmpty) {
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
        widget.selectedGame.isEmpty) {
      return;
    }

    if (_youtubeId == null) {
      words = _textEditingController.text.split(' ');
      for (String word in words) {
        String trimmed = word.trim().split(RegExp(r'[\n\r\s]+')).last;
        _youtubeId = (word.contains('www.youtube.com') ||
                word.contains('https://youtu.be'))
            ? YoutubePlayer.convertUrlToId(trimmed)
            : null;
      }
    }

    Navigator.of(context).push(CustomScreenLoader());

    /// If tweet contain image
    /// First image is uploaded on firebase storage
    /// After successful image upload to firebase storage it returns image path
    /// Add this image path to tweet model and save to firebase database
    String postId = randomAlphaNumeric(20);

    await AppUtil.checkIfContainsMention(_textEditingController.text, postId);

    if (_video != null) {
      // MediaInfo mediaInfo = await VideoCompress.compressVideo(
      //   _video.path,
      //   quality: VideoQuality.LowQuality, includeAudio: true,
      //   deleteOrigin: false, // It's false by default
      // );
      // print('Compressed sized ${mediaInfo.filesize}');
      _uploadedFileURL = await AppUtil.uploadFile(
          _video, context, 'posts_videos/${Constants.currentUserID}/' + postId);
    } else if (_image != null) {
      await AppUtil.createAppDirectory();
      File result = await FlutterImageCompress.compressAndGetFile(
        _image.absolute.path,
        '$appTempDirectoryPath/${path.basename(_image.absolute.path)}',
        quality: 75,
      );

      _uploadedFileURL = await AppUtil.uploadFile(
          result, context, 'posts_images/${Constants.currentUserID}/' + postId);
      await AppUtil.deleteAppDirectoryFiles();
    } else {}

    print(_youtubeId);

    var postData = {
      'author': Constants.currentUserID,
      'text': _textEditingController.text,
      'youtubeId': _youtubeId,
      'video': _video != null ? _uploadedFileURL : null,
      'image': _image != null ? _uploadedFileURL : null,
      'likes': 0,
      'dislikes': 0,
      'comments': 0,
      'timestamp': FieldValue.serverTimestamp(),
      'game': widget.selectedGame
    };

    int coolDownMinutes = 10;
    Post lastPost =
        await DatabaseService.getUserLastPost(Constants.currentUserID);

    if (lastPost == null) {
      print('First time to post');
    } else if (lastPost != null &&
        DateTime.now().millisecondsSinceEpoch -
                lastPost.timestamp.millisecondsSinceEpoch <
            coolDownMinutes * 60000) {
      AppUtil.showSnackBar(context, _scaffoldKey,
          'Must wait $coolDownMinutes minutes to upload another post');
      Navigator.of(context).pop();
      return;
    }

    await postsRef.doc(postId).set(postData);

    await AppUtil.checkIfContainsHashtag(
        _textEditingController.text, postId, _isNewHashtag);

    await gamesRef
        .doc(
            (await DatabaseService.getGameWithGameName(widget.selectedGame)).id)
        .update({'frequency': FieldValue.increment(1)});

    /// Checks for username in tweet description
    /// If found sends notification to all tagged user
    /// If no user found or not compost tweet screen is closed and redirect back to home page.

    /// Hide running loader on screen
    Navigator.of(context).pop();

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
                controller: scrollController,
                child: _ComposeTweet(this),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: CreateBottomIcon(
                  isComment: false,
                  textEditingController: _textEditingController,
                  onImageIconSelected: _onImageIconSelected,
                  onVideoIconSelected: _onVideoIconSelected,
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
                  onTap: () {
                    Navigator.of(context).pop(false);
                    Navigator.of(context).pop();
                  },
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
      padding: EdgeInsets.only(left: 10, right: 10, bottom: 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox.shrink(),
          Stack(
            children: [
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
                    child: TextFormField(
                      cursorColor: MyColors.darkPrimary,
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
                        viewState.setState(() {
                          viewState.words = text.split(' ');
                          viewState._mentionText = viewState.words.length > 0 &&
                                  viewState.words[viewState.words.length - 1]
                                      .startsWith('@')
                              ? viewState.words[viewState.words.length - 1]
                              : '';

                          //Hashtag
                          viewState._hashtagText = viewState.words.length > 0 &&
                                  viewState.words[viewState.words.length - 1]
                                      .startsWith('#')
                              ? viewState.words[viewState.words.length - 1]
                              : '';
                        });

                        print(viewState.words[viewState.words.length - 1]);
                        print('yotubeId: ${viewState._youtubeId}');
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
                          hintText: 'Any thoughts?'),
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              viewState._mentionText.length > 1
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 55),
                      child: ListView.builder(
                        itemCount: Constants.userFriends.length,
                        itemBuilder: (context, index) {
                          String friendUsername =
                              Constants.userFriends[index].username;
                          print('username:' + friendUsername);
                          if (('@' + friendUsername.toLowerCase())
                              .contains(viewState._mentionText.toLowerCase()))
                            return ListTile(
                              leading: CacheThisImage(
                                imageUrl: Constants
                                    .userFriends[index].profileImageUrl,
                                imageShape: BoxShape.circle,
                                width: 40.0,
                                height: 40.0,
                                defaultAssetImage:
                                    Strings.default_profile_image,
                              ),
                              title:
                                  Text(Constants.userFriends[index].username),
                              onTap: () {
                                if (viewState._textEditingController.text
                                    .contains('@$friendUsername')) {
                                  AppUtil.showSnackBar(
                                      context,
                                      viewState._scaffoldKey,
                                      'User already mentioned!');
                                  return;
                                }
                                viewState.setState(() {
                                  viewState._mentionText = '';

                                  String s = viewState
                                      ._textEditingController.text
                                      .replaceFirst(
                                          RegExp(r'\B\@\w+'),
                                          '@$friendUsername',
                                          viewState._textEditingController.text
                                                      .length <
                                                  8
                                              ? 0
                                              : viewState._textEditingController
                                                      .selection.baseOffset -
                                                  8);
                                  viewState._textEditingController.text = s;

                                  viewState._textEditingController.selection =
                                      TextSelection.collapsed(
                                          offset: viewState
                                              ._textEditingController
                                              .text
                                              .length);
                                });
                              },
                            );

                          return SizedBox();
                        },
                        shrinkWrap: true,
                      ),
                    )
                  : SizedBox(),
              viewState._hashtagText.length > 1
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 55),
                      child: ListView.builder(
                        itemCount: Constants.hashtags.length,
                        itemBuilder: (context, index) {
                          String hashtag = Constants.hashtags[index].text;
                          print('hashtag:' + hashtag);
                          if (('#' + hashtag.toLowerCase())
                              .contains(viewState._hashtagText.toLowerCase()))
                            return ListTile(
                              title: Text(Constants.hashtags[index].text),
                              onTap: () {
                                viewState._isNewHashtag = false;

                                if (viewState._textEditingController.text
                                    .contains('#$hashtag')) {
                                  AppUtil.showSnackBar(
                                      context,
                                      viewState._scaffoldKey,
                                      'Post already contains this hashtag!');
                                  return;
                                }
                                viewState.setState(() {
                                  viewState._hashtagText = '';

                                  String s = viewState
                                      ._textEditingController.text
                                      .replaceFirst(
                                          RegExp(r'\B\#\w+'),
                                          '$hashtag',
                                          viewState._textEditingController.text
                                                      .length <
                                                  8
                                              ? 0
                                              : viewState._textEditingController
                                                      .selection.baseOffset -
                                                  8);
                                  viewState._textEditingController.text = s;

                                  viewState._textEditingController.selection =
                                      TextSelection.collapsed(
                                          offset: viewState
                                              ._textEditingController
                                              .text
                                              .length);
                                });

//                          String tmp = viewState._hashtagText
//                              .substring(1, viewState._hashtagText.length);
//                          viewState.setState(() {
//                            viewState._hashtagText = '';
//                            viewState._textEditingController.text += hashtag
//                                .substring(hashtag.indexOf(tmp) + tmp.length,
//                                    hashtag.length)
//                                .replaceAll(' ', '_');
//                          });
                              },
                            );

                          return SizedBox();
                        },
                        shrinkWrap: true,
                      ),
                    )
                  : SizedBox(),
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
                return DatabaseService.searchGames(pattern.toLowerCase());
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
                  viewState.widget.selectedGame =
                      viewState._typeAheadController.text;
                });
              },
              validator: (value) {
                if (value.isEmpty) {
                  return 'Please select a game';
                }
                return '';
              },
              onSaved: (value) => viewState.widget.selectedGame = value,
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
          viewState._video != null ? viewState.createPostVideo : Container(),
        ],
      ),
    );
  }
}
