import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart' as prefix0;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_icons/flutter_icons.dart';

enum ScreenState { to_edit, viewing, to_save }

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  var _coverImage;
  var _profileImage;
  var _uploadedFileURL;
  var _screenState = ScreenState.to_edit;
  double _coverHeight = 200;

  String _descText = 'Description here';
  String _nameText = 'Ahmed Nabil';
  var _descEditingController = TextEditingController()..text = 'Description here';
  var _nameEditingController = TextEditingController()..text = 'Ahmed Nabil';

  Future chooseImage(int whichImage) async {
    await ImagePicker.pickImage(source: ImageSource.gallery).then((image) {
      setState(() {
        if (whichImage == 1) {
          setState(() {
            _coverImage = image;
          });
        } else {
          setState(() {
            _profileImage = image;
          });
        }
        //print(_profileImage.toString());
      });
    });
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

  void edit() {
    setState(() {
      _screenState = ScreenState.to_save;
    });
  }

  void save() {
    setState(() {
      _screenState = ScreenState.to_edit;
      _descText = _descEditingController.text;
      _nameText = _nameEditingController.text;
    });
  }

  Widget profileOverlay(Widget child, double size) {
    return Stack(
      alignment: Alignment(0, 0),
      children: <Widget>[
        child,
        Container(
          child: Icon(FontAwesome.getIconData('camera')),
          height: size,
          width: size,
          decoration: new BoxDecoration(
            color: const Color(0x000000).withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        )
      ],
    );
  }

  Widget coverOverlay(Widget child, double size) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: <Widget>[
        child,
        Container(
          margin: EdgeInsets.all(10),
          child: Icon(FontAwesome.getIconData('camera')),
          height: size,
          width: size,
          decoration: new BoxDecoration(
            color: const Color(0x000000).withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        )
      ],
    );
  }

  Widget _build() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          _profileAndCover(),
          SizedBox(
            height: 10,
          ),
          _screenState == ScreenState.to_edit
              ? Text(
                  _nameText,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                )
              : Container(
                  height: 30,
                  width: 200,
                  child: TextField(
                    textAlign: TextAlign.center,
                    controller: _nameEditingController,
                    onChanged: (text) => {},
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
          SizedBox(
            height: 8,
          ),
          _screenState == ScreenState.to_edit
              ? Text(
                  _descText,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                )
              : Container(
                  height: 30,
                  width: 200,
                  child: TextField(
                    textAlign: TextAlign.center,
                    controller: _descEditingController,
                    onChanged: (text) => {},
                    style: TextStyle(fontSize: 16),
                  ),
                ),
          SizedBox(
            height: 8,
          ),
          Divider(
            color: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }

  Stack _profileAndCover() {
    return Stack(
      alignment: Alignment(0, 0),
      children: <Widget>[
        _coverImage == null
            ? _screenState == ScreenState.to_save
                ? coverOverlay(
                    Container(
                      width: MediaQuery.of(context).size.width,
                      height: _coverHeight,
                      child: GestureDetector(
                        onTap: _screenState == ScreenState.to_save
                            ? () {
                                chooseImage(1);
                              }
                            : () {},
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: Image(
                            image: AssetImage('images/default_cover.jpg'),
                          ),
                        ),
                      ),
                    ),
                    50)
                : Container(
                    width: MediaQuery.of(context).size.width,
                    height: _coverHeight,
                    child: GestureDetector(
                      onTap: _screenState == ScreenState.to_save
                          ? () {
                              chooseImage(1);
                            }
                          : () {},
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: Image(
                          width: MediaQuery.of(context).size.width,
                          image: AssetImage('images/default_cover.jpg'),
                        ),
                      ),
                    ),
                  )
            : Container(
                child: _screenState == ScreenState.viewing
                    ? Image.network('')
                    : Image(
                        key: Key('s'),
                        width: MediaQuery.of(context).size.width,
                        height: _coverHeight,
                        image: FileImage(_coverImage)),
              ),
        GestureDetector(
          onTap: _screenState == ScreenState.to_save
              ? () {
                  chooseImage(2);
                }
              : () {},
          child: _profileImage == null
              ? _screenState == ScreenState.to_save
                  ? profileOverlay(
                      CircleAvatar(
                        radius: 50,
                        backgroundImage:
                            AssetImage('images/default_profile.png'),
                      ),
                      100)
                  : CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage('images/default_profile.png'),
                    )
              : CircleAvatar(
                  radius: 50,
                  backgroundImage: _screenState == ScreenState.viewing
                      ? NetworkImage('')
                      : FileImage(_profileImage),
                ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: _build(),
      floatingActionButton: FloatingActionButton(
        child: _screenState == ScreenState.to_edit
            ? Icon(MaterialIcons.getIconData('edit'))
            : _screenState == ScreenState.to_save
                ? Icon(MaterialIcons.getIconData('save'))
                : Icon(FontAwesome.getIconData('user-plus')),
        onPressed: _screenState == ScreenState.to_edit
            ? () {
                edit();
              }
            : () {
                save();
              },
      ),
    );
  }
}
