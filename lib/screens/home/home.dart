import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/screens/chats.dart';
import 'package:glitcher/screens/home/home_body.dart';
import 'package:glitcher/utils/auth.dart';
import 'package:glitcher/screens/new_post.dart';
import 'package:glitcher/screens/profile_screen.dart';
import 'package:glitcher/utils/statics.dart';

class HomePage extends StatefulWidget {
  static const String id = 'home_page';
  HomePage({Key key, this.auth, this.userId, this.onSignedOut})
      : super(key: key);

  final BaseAuth auth;
  final VoidCallback onSignedOut;
  final String userId;

  @override
  State<StatefulWidget> createState() => _HomePageState(auth);
}

class _HomePageState extends State<HomePage> {
  final _auth = FirebaseAuth.instance;
  Firestore _firestore = Firestore.instance;

  String username;

  String profileImageUrl;

  dynamic body = HomeBody();

  void loadUserData(String uid) async {
    await _firestore.collection('users').document(uid).get().then((onValue) {
      setState(() {
        username = onValue.data['username'];
        profileImageUrl = onValue.data['profile_url'];
      });
    });
  }

  FirebaseUser currentUser;

  _HomePageState(auth);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //AppBar
      appBar: AppBar(
        leading: Builder(
            builder: (context) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () => Scaffold.of(context).openDrawer(),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      fit: BoxFit.fill,
                      image: profileImageUrl != null
                          ? NetworkImage(profileImageUrl)
                          : AssetImage('assets/images/default_profile.png'),
                    ),
                  ),
                ),
              ),
            )),
        backgroundColor: Theme.of(context).primaryColorDark,
        title: Text('Home'),
        actions: <Widget>[
          body == HomeBody()
              ? IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              setState(() {
                Statics.filterPanel = !Statics.filterPanel;
              });
            },
          )
              : Container(),
        ],
      ),
      //MainBody

      body: body,

      drawer: Drawer(
        // The sidebar/Drawer
        child: SingleChildScrollView(
          child: Container(
              color: Theme.of(context).primaryColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 40.0, 0.0, 8.0),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ProfileScreen(
                                    userId: this.currentUser.uid)));
                      },
                      child: Container(
                        width: 75.0,
                        height: 75.0,
                        decoration: new BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            fit: BoxFit.fitHeight,
                            image: profileImageUrl != null
                                ? NetworkImage(profileImageUrl)
                                : AssetImage(
                                'assets/images/default_profile.png'),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Text(
                            username != null ? username : '',
                            style: TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.bold,
                                fontSize: 20),
                          ),
                        ),
                        Icon(Icons.arrow_drop_down)
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    color: Colors.grey,
                    height: 0.5,
                  ),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                      child: Column(
                        children: <Widget>[
                          ListTile(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ProfileScreen(
                                          userId: this.currentUser.uid)));
                            },
                            title: Text(
                              'Profile',
                              style: TextStyle(color: Colors.black54),
                            ),
                            leading: Icon(
                              Icons.person,
                              color: Colors.grey,
                            ),
                          ),
                          ListTile(
                            title: Text(
                              'Lists',
                              style: TextStyle(color: Colors.black54),
                            ),
                            leading: Icon(
                              Icons.list,
                              color: Colors.grey,
                            ),
                          ),
                          ListTile(
                            title: Text(
                              'Bookmarks',
                              style: TextStyle(color: Colors.black54),
                            ),
                            leading: Icon(
                              Icons.bookmark_border,
                              color: Colors.grey,
                            ),
                          ),
                          ListTile(
                            title: Text(
                              'Moments',
                              style: TextStyle(color: Colors.black54),
                            ),
                            leading: Icon(
                              Icons.apps,
                              color: Colors.grey,
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            color: Colors.grey,
                            height: 0.5,
                          ),
                          ListTile(
                            title: Text(
                              'Settings and Privacy',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                          ListTile(
                            title: Text(
                              'Help center',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),

                          ListTile(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => Chats()));
                            },
                            title: Text(
                              'Chats',
                              style: TextStyle(color: Colors.black54),
                            ),
                            leading: Icon(
                              Icons.chat_bubble,
                              color: Colors.grey,
                            ),
                          ),

                          ListTile(
                            onTap: () async {
                              try {
                                await widget.auth.signOut();
                                widget.onSignedOut();
                              } catch (e) {
                                print(e);
                              }
                            },
                            title: Text(
                              'Chats',
                              style: TextStyle(color: Colors.black54),
                            ),
                            leading: Icon(
                              Icons.chat_bubble,
                              color: Colors.grey,
                            ),
                          ),

//                        FlatButton(
//                          child: ListTile(
//                            title: Text(
//                              'Log Out',
//                              style: TextStyle(color: Colors.black54),
//                            ),
//                          ),
//                          onPressed: () async {
//                            try {
//                              await widget.auth.signOut();
//                              widget.onSignedOut();
//                            } catch (e) {
//                              print(e);
//                            }
//                          },
//                        ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    color: Colors.grey,
                    height: 0.5,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        SizedBox(
                          height: 30.0,
                          width: 30.0,
                          child: IconButton(
                            padding: new EdgeInsets.all(0.0),
                            icon: Icon(
                              Icons.wb_sunny,
                              size: 32.0,
                            ),
                            onPressed: () {},
                          ),
                        ),
                        SizedBox(
                          height: 30.0,
                          width: 30.0,
                          child: IconButton(
                            padding: new EdgeInsets.all(0.0),
                            icon: Icon(
                              Icons.camera_alt,
                              size: 32.0,
                            ),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              )),
        ),
      ),

      floatingActionButton: body == HomeBody()
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => NewPost(
                    currentUser: currentUser,
                  )));
        },
        child: Icon(Icons.edit),
        backgroundColor: Theme.of(context).accentColor,
      )
          : null,

      //BottomnavBar
      bottomNavigationBar: Container(
        height: 50.0,
        color: Theme.of(context).primaryColorDark,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.home),
              onPressed: () {
                setState(() {
                  body = HomeBody();
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.search),
              onPressed: null,
            ),
            IconButton(
              icon: Icon(Icons.notifications),
              onPressed: null,
            ),
            IconButton(
              color: Colors.grey,
              icon: Icon(Icons.chat_bubble),
              onPressed: () {
                setState(() {
                  body = Chats();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    this.currentUser = await Auth().getCurrentUser();
    loadUserData(currentUser.uid);
  }

  void moveUserTo({Widget widget, String routeId, FirebaseUser currentUser}) {
    Navigator.of(context).push<String>(
      new MaterialPageRoute(
        settings: RouteSettings(name: '/$routeId'),
        builder: (context) => widget,
      ),
    );
  }
}