import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/screens/home/home_body.dart';
import 'package:glitcher/screens/login_page.dart';
import 'package:glitcher/screens/new_post.dart';
import 'package:glitcher/screens/profile_screen.dart';

class HomePage extends StatefulWidget {
  static const String id = 'home_page';

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _auth = FirebaseAuth.instance;

  FirebaseUser currentUser;
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
                          image: AssetImage('assets/images/face1.jpeg'),
                        ),
                      ),
                    ),
                  ),
                )),
        backgroundColor: Theme.of(context).primaryColorDark,
        title: Text('Home'),
      ),
      //MainBody
      body: TwitterBody(),
      drawer: Drawer(
        // The sidebar/Drawer
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
                              builder: (context) => ProfileScreen(currentUser: currentUser,)));
                    },
                    child: Container(
                      width: 75.0,
                      height: 75.0,
                      decoration: new BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          fit: BoxFit.fitHeight,
                          image: AssetImage('assets/images/face1.jpeg'),
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
                      Text(
                        'carol Danvers',
                        style: TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 20),
                      ),
                      Icon(Icons.arrow_drop_down)
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    '@dan_carol',
                    style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
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
                        FlatButton(
                          child: ListTile(
                            title: Text(
                              'Profile',
                              style: TextStyle(color: Colors.black54),
                            ),
                            leading: Icon(
                              Icons.person,
                              color: Colors.grey,
                            ),
                          ),
                          onPressed: (){
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ProfileScreen(currentUser: currentUser,)));

                          },
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
                        FlatButton(
                          child: ListTile(
                            title: Text(
                              'Log Out',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _auth.signOut();
                              getCurrentUser();
                            });
                          },
                        ),
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

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => NewPost(currentUser: currentUser,)));

        },
        child: Icon(Icons.edit),
        backgroundColor: Theme.of(context).accentColor,
      ),
      //BottomnavBar
      bottomNavigationBar: Container(
        height: 50.0,
        color: Theme.of(context).primaryColorDark,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.home),
              onPressed: () {},
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
              icon: Icon(Icons.mail),
              onPressed: null,
            ),
          ],
        ),
      ),
    );
  }

  void getCurrentUser() async {
    try {
      currentUser = await _auth.currentUser();
      if (currentUser != null) {
        //Navigator.pushNamed(context, HomePage.id);
        print("User logged: " + currentUser.email);
      } else {
        moveUserTo(widget: LoginPage(), routeId: HomePage.id);
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    getCurrentUser();
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
