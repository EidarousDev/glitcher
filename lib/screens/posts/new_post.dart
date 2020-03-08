import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/services/permissions_service.dart';
import 'package:glitcher/utils/functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:glitcher/utils/Loader.dart';
import 'package:glitcher/services/auth.dart';
import 'package:glitcher/utils/constants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:video_player/video_player.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:random_string/random_string.dart';
import 'package:chewie/chewie.dart';
import 'package:autocomplete_textfield/autocomplete_textfield.dart';

class NewPost extends StatefulWidget {
  @override
  _NewPostState createState() => _NewPostState();
}

class _NewPostState extends State<NewPost> {
  var _image;
  var _video;
  var _uploadedFileURL;
  bool _isPlaying;
  VideoPlayerController videoPlayerController;
  ChewieController chewieController;
  Chewie playerWidget;

  var $ranFileName; // Random File Name

  //YoutubePlayer
  bool _showYoutubeUrl = false;
  String _youtubeId;
  //TODO: Fix YouTube Player
  //YoutubePlayerController _youtubeController = YoutubePlayerController();
  final uTubeTextController = TextEditingController();
  final mainTextController = TextEditingController();

  bool _loading = false;

  String selectedCategory = "";
  GlobalKey<AutoCompleteTextFieldState<String>> autocompleteKey =
      new GlobalKey();

  @override
  void initState() {
    super.initState();
    DatabaseService.getGameNames();
  }

  void playVideo() {
    videoPlayerController = VideoPlayerController.file(_video);
    chewieController = ChewieController(
      videoPlayerController: videoPlayerController,
      aspectRatio: videoPlayerController.value.aspectRatio,
      autoPlay: true,
      looping: false,
    );

    playerWidget = Chewie(
      controller: chewieController,
    );
    videoPlayerController
      ..addListener(() {
        final bool isPlaying = videoPlayerController.value.isPlaying;
        if (isPlaying != _isPlaying) {
          setState(() {
            _isPlaying = isPlaying;
          });
        }
      });
    videoPlayerController
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {});
      });
  }

  void listener() {
//    if (_youtubeController.value.playerState == PlayerState.ENDED) {
//      //_showThankYouDialog();
//    }
    if (mounted) {
      setState(() {
        //_playerStatus = _youtubeController.value.playerState.toString();
        //_errorCode = _youtubeController.value.errorCode.toString();
      });
    }
  }

  @override
  void dispose() {
    videoPlayerController.dispose();
    chewieController.dispose();
    super.dispose();
  }

  void clearVars() {
    setState(() {
      _video = null;
      _image = null;
      _youtubeId = null;
    });
  }

  Future chooseVideo() async {
    clearVars();
    await ImagePicker.pickVideo(source: ImageSource.gallery).then((video) {
      setState(() {
        _video = video;
        playVideo();
      });
    });
  }

  Future chooseImage() async {
    clearVars();
    await ImagePicker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 52,
            maxHeight: 400,
            maxWidth: 600)
        .then((image) {
      setState(() {
        _image = image;
      });
    });
  }

  Future uploadFile(String parentFolder, var fileName) async {
    if (fileName == null) return;

    setState(() {
      this.$ranFileName =
          randomAlphaNumeric(5) + '_' + p.basename(fileName.path);
    });
    print((fileName));
    print('fileNameRandomized = ' + this.$ranFileName);

    StorageReference storageReference = FirebaseStorage.instance
        .ref()
        .child('$parentFolder/' + this.$ranFileName);
    StorageUploadTask uploadTask = storageReference.putFile(fileName);
    await uploadTask.onComplete;
    print('File Uploaded');
    await storageReference.getDownloadURL().then((fileURL) {
      setState(() {
        _uploadedFileURL = fileURL;
      });
    });
  }

  Future uploadPost(String text) async {
    setState(() {
      _loading = true;
    });

    if (_video != null) {
      await uploadFile('videos', _video);
    } else if (_image != null) {
      //await compressAndUploadFile(_image, 'glitchertemp.jpg');
      await uploadFile('images', _image);
    }

    await firestore.collection('posts').add({
      'owner': Constants.currentUserID,
      'text': text,
      'youtubeId': _youtubeId,
      'video': _video != null ? _uploadedFileURL : null,
      'image': _image != null ? _uploadedFileURL : null,
      'likes': 0,
      'dislikes': 0,
      'comments': 0,
      'timestamp': FieldValue.serverTimestamp(),
      'category': selectedCategory
    }).then((_) {
      setState(() {
        _loading = false;
        //Navigator.pop(context);
      });
      pushHomeScreen(context);
    });
  }


  Widget _buildWidget() {
    return WillPopScope(
      onWillPop: () {
        pushHomeScreen(context);
        return;
      },
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: mainTextController,
                  decoration: new InputDecoration.collapsed(
                      hintText: 'What\'s in your mind?'),
                  minLines: 1,
                  maxLines: 5,
                  autocorrect: true,
                  autofocus: true,
                ),
              ),
              SizedBox(
                height: 15,
              ),
              _showYoutubeUrl
                  ? Row(
                      children: <Widget>[
                        Expanded(
                          flex: 11,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              controller: uTubeTextController,
                              decoration: new InputDecoration.collapsed(
                                  hintText: 'Paste YOUTUBE Url here'),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Container(
                            margin: EdgeInsets.only(right: 3),
                            child: RaisedButton(
                                child: Text('OK'),
                                textColor: Colors.white,
                                color: Colors.blue,
                                onPressed: () {
                                  setState(() {
                                    _youtubeId = YoutubePlayer.convertUrlToId(
                                        uTubeTextController.text);
                                    _showYoutubeUrl = false;
                                    _video = null;
                                    _image = null;
                                  });
                                }),
                          ),
                        )
                      ],
                    )
                  : Container(),
              _video != null ? playerWidget : Container(),
              //TODO: Fix the YouTube Player
              Container(),
//            _youtubeId != null
//                ? YoutubePlayer(
//                    context: context,
//                    videoId: _youtubeId,
//                    flags: YoutubePlayerFlags(
//                      autoPlay: false,
//                      showVideoProgressIndicator: true,
//                    ),
//                    videoProgressIndicatorColor: Colors.red,
//                    progressColors: ProgressColors(
//                      playedColor: Colors.red,
//                      handleColor: Colors.redAccent,
//                    ),
//                    onPlayerInitialized: (controller) {
//                      _youtubeController = controller;
//                      _youtubeController.addListener(listener);
//                    },
//                  )
//                : Container(),
              _image != null ? Image.file(_image) : Container(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 10),
                      child: RaisedButton(
                          child: Icon(FontAwesome.getIconData("file-video-o")),
                          textColor: Colors.white,
                          color: Colors.blue,
                          onPressed: () {
                            chooseVideo();
                          }),
                    ),
                    flex: 1,
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 10),
                      child: RaisedButton(
                          child: Icon(FontAwesome.getIconData("youtube")),
                          textColor: Colors.white,
                          color: Colors.blue,
                          onPressed: () {
                            setState(() {
                              _showYoutubeUrl = true;
                            });
                          }),
                    ),
                    flex: 1,
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  Expanded(
                    child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 10),
                        child: RaisedButton(
                            child: Icon(FontAwesome.getIconData("image")),
                            textColor: Colors.white,
                            color: Colors.blue,
                            onPressed: () {
                              PermissionsService().requestStoragePermission(
                                  onPermissionDenied: () {
                                print('Permission has been denied');
                              });
                              chooseImage();
                            })),
                    flex: 1,
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: AutoCompleteTextField<String>(
                  clearOnSubmit: false,
                  key: autocompleteKey,
                  suggestions: Constants.games,
                  decoration: InputDecoration(
                      icon: Icon(Icons.videogame_asset), hintText: "Game"),
                  itemFilter: (item, query) {
                    return item.toLowerCase().startsWith(query.toLowerCase());
                  },
                  itemSorter: (a, b) {
                    return a.compareTo(b);
                  },
                  itemSubmitted: (item) {
                    selectedCategory = item;
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
//            DropDownField(
//                value: selectedCategory,
//                strict: true,
//                icon: Icon(Icons.category),
//                items: categories,
//                setter: (dynamic newValue) {
//                  setState(() {
//                    selectedCategory = newValue;
//                  });
//                }
//            ),

              Container(
                margin: EdgeInsets.symmetric(horizontal: 10),
                child: RaisedButton(
                    child: Text('Publish'),
                    textColor: Colors.white,
                    color: Colors.blue,
                    onPressed: () {
                      uploadPost(mainTextController.text);
                    }),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text('New Post'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => pushHomeScreen(context),
        ),
      ),
      body: Stack(
        alignment: Alignment(0, 0),
        children: <Widget>[
          _buildWidget(),
          _loading
              ? LoaderTwo()
              : Container(
                  width: 0,
                  height: 0,
                ),
        ],
      ),
    );
  }

//  // 2. compress file and get file.
//  compressAndUploadFile(File file, String targetPath) async {
//    var result = await FlutterImageCompress.compressAndGetFile(
//      file.absolute.path,
//      targetPath,
//      quality: 50,
//      rotate: 270,
//    );
//
//    print((result));
//
//    setState(() {
//      this.$ranFileName = randomAlphaNumeric(5) + p.basename(file.path);
//    });
//    print((file));
//    print('fileNameRandomized = ' + this.$ranFileName);
//
//    StorageReference storageReference = FirebaseStorage.instance
//        .ref()
//        .child('compressed_images/' + this.$ranFileName);
//
//    StorageUploadTask uploadTask = storageReference.putFile(result);
//    await uploadTask.onComplete;
//    print('Compressed File Uploaded');
//
//    print(file.lengthSync());
//    return result;
//  }
}
