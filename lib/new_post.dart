import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:video_player/video_player.dart';

class NewPost extends StatefulWidget {
  @override
  _NewPostState createState() => _NewPostState();
}

class _NewPostState extends State<NewPost> {
  var _image;
  var _video;
  var _uploadedFileURL;
  VideoPlayerController _controller;
  bool _isPlaying;

  @override
  void initState() {
    super.initState();
  }

  void playVideo(){
    _controller = VideoPlayerController.file(_video)
      ..addListener(() {
        final bool isPlaying = _controller.value.isPlaying;
        if (isPlaying != _isPlaying) {
          setState(() {
            _isPlaying = isPlaying;
          });
        }
      })
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {
          //Play video on load
//          _controller.value.isPlaying
//              ? _controller.pause()
//              : _controller.play();
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
    await ImagePicker.pickImage(source: ImageSource.gallery).then((image) {
      setState(() {
        _image = image;
      });
    });
  }

  Future chooseVideo() async {
    _video = null;
    _image = null;
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
      print(_uploadedFileURL);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              minLines: 2,
              maxLines: 5,
              autocorrect: true,
              autofocus: true,
            ),

            _controller != null
                ? Stack(
              children:<Widget>[ AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),

                Center(
                  child: FloatingActionButton(
                    onPressed: () {
                      setState(() {
                        _isPlaying
                            ? _pause()
                            : _play();
                      });
                    },
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                  ),
                ),

              ]
            ): Container(),


            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 10),
                    child: RaisedButton(
                        child: Text('Add Video'),
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
                          child: Text('Add Image'),
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
                  }),
            )
          ],
        ),
      ),
    );
  }
}
