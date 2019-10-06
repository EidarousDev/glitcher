import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

class NewPost extends StatefulWidget {

  @override
  _NewPostState createState() => _NewPostState();

}

  class _NewPostState extends State<NewPost>{

    var _image;
    var _video;
    var _uploadedFileURL;


    Future chooseImage() async {
      await ImagePicker.pickImage(source: ImageSource.gallery).then((image) {
        setState(() {
          _image = image;
        });
      });
    }

    Future chooseVideo() async {
      await ImagePicker.pickVideo(source: ImageSource.gallery).then((video) {
        setState(() {
          _video = video;
        });
      });

      uploadFile('videos', _video);
    }


    Future uploadFile(String parentFolder, var fileName) async {

      if(fileName == null)
        return;

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
              minLines: 10,
              maxLines: 20,
              autocorrect: true,
              autofocus: true,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(child: Container( margin: EdgeInsets.symmetric(horizontal: 10),child: RaisedButton( child: Text('Add Video'), textColor: Colors.white, color: Colors.blue,
                    onPressed: (){
                  chooseVideo();
                  //uploadFile('videos', _video);
                }
                ),
                ),
                  flex: 1,),
                SizedBox(
                  width: 20,
                ),
                Expanded(child: Container( margin: EdgeInsets.symmetric(horizontal: 10),child: RaisedButton(child: Text('Add Image'), textColor: Colors.white, color: Colors.blue, onPressed: (){})),
                  flex: 1,),
              ],
            ),
            Container( margin: EdgeInsets.symmetric(horizontal: 10),child: RaisedButton(child: Text('Publish'), textColor: Colors.white, color: Colors.blue, onPressed: (){}))
          ],
        ),
      ),
    );
  }

  }
