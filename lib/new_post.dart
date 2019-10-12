import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:video_player/video_player.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toast/toast.dart';

class NewPost extends StatefulWidget {
  @override
  _NewPostState createState() => _NewPostState();
}

class _NewPostState extends State<NewPost> {
  var _image;
  var _video;
  var _uploadedFileURL;
  bool _isPlaying;
  VideoPlayerController _controller;

  //YoutubePlayer
  bool _showYoutubeUrl = false;
  String _youtubeId;
  //String _playerStatus = "";
  //String _errorCode = '0';
  YoutubePlayerController _youtubeController = YoutubePlayerController();
  final uTubeTextController = TextEditingController();
  final mainTextController = TextEditingController();


  var _firestore = Firestore.instance;

  @override
  void initState() {
    super.initState();
  }
  void listener() {
    if (_youtubeController.value.playerState == PlayerState.ENDED) {
      //_showThankYouDialog();
    }
    if (mounted) {
      setState(() {
        //_playerStatus = _youtubeController.value.playerState.toString();
        //_errorCode = _youtubeController.value.errorCode.toString();
      });
    }
  }

  void playVideo() {
    _controller = VideoPlayerController.file(_video) ;
    _controller..addListener(() {
        final bool isPlaying = _controller.value.isPlaying;
        if (isPlaying != _isPlaying) {
          setState(() {
            _isPlaying = isPlaying;
          });
        }
      });
      _controller..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {
        });
      });
  }

  void _pause() {
    setState(() {
      _controller.pause();
    });
  }

  void _play() {
    setState(() {
      if (!_controller.value.initialized) {
        _controller.initialize().then((_) {
          _controller.play();
        }).catchError((dynamic error) => print('Video player error: $error'));
      } else {
        if (_controller.value.position >= _controller.value.duration) {
          _controller.seekTo(Duration(seconds: 0));
        }
        _controller.play();
      }
    });
  }

  Future chooseImage() async {
    _video = null;
    _image = null;
    _youtubeId = null;
    await ImagePicker.pickImage(source: ImageSource.gallery).then((image) {
      setState(() {
        _image = image;
      });
    });
  }

  Future chooseVideo() async {
    _video = null;
    _image = null;
    _youtubeId = null;
    await ImagePicker.pickVideo(source: ImageSource.gallery).then((video) {
      setState(() {
        _video = video;
      });
    });

    playVideo();
  }

  Future uploadFile(String parentFolder, var fileName) async {
    if (fileName == null) return;

    print((fileName));

    StorageReference storageReference = FirebaseStorage.instance
        .ref()
        .child('$parentFolder/${p.basename(fileName.path)}');
    StorageUploadTask uploadTask = storageReference.putFile(fileName);
    await uploadTask.onComplete;
    print('File Uploaded');
    storageReference.getDownloadURL().then((fileURL) {
      setState(() {
        _uploadedFileURL = fileURL;
      });
      uploadPost(mainTextController.text);
      print(_uploadedFileURL);
    });
  }

  Future uploadPost(String text) async {
    await _firestore.collection('posts').add({
      'text' : text,
      'youtubeId' : _youtubeId,
      'video' : _video != null ? _uploadedFileURL : null,
      'image' : _image != null ? _uploadedFileURL : null,
    });

    print('post uploaded');
    Toast.show('Post uploaded', context, duration: Toast.LENGTH_LONG, gravity:  Toast.BOTTOM);

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Post'),
      ),
      body: SafeArea(
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
                                  _youtubeId = YoutubePlayer.convertUrlToId(uTubeTextController.text);
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

            _video != null
                ? Stack(alignment: const Alignment(0, 0), children: <Widget>[
                    AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                    Center(
                      child: FloatingActionButton(
                        backgroundColor: Colors.blue,
                        onPressed: () {
                          setState(() {
                            _isPlaying ? _pause() : _play();
                          });
                        },
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                        ),
                      ),
                    ),
                  ])
                : Container(),

            _youtubeId != null
                ? YoutubePlayer(
              context: context,
              videoId: _youtubeId,
              flags: YoutubePlayerFlags(
                autoPlay: true,
                showVideoProgressIndicator: true,
              ),
              videoProgressIndicatorColor: Colors.red,
              progressColors: ProgressColors(
                playedColor: Colors.red,
                handleColor: Colors.redAccent,
              ),
              onPlayerInitialized: (controller) {
                _youtubeController = controller;
                _youtubeController.addListener(listener);
              },
            ): Container(),

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
                            chooseImage();
                          })),
                  flex: 1,
                ),
              ],
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 10),
              child: RaisedButton(
                  child: Text('Publish'),
                  textColor: Colors.white,
                  color: Colors.blue,
                  onPressed: () {
                    if (_video != null) {
                      uploadFile('videos', _video);
                    } else if (_image != null) {
                      uploadFile('images', _image);
                    }
                    else{
                      uploadPost(mainTextController.text);
                    }
                  }),
            )
          ],
        ),
      ),
    );
  }
}
