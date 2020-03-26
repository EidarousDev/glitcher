import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/services/auth.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/utils/functions.dart';
import 'package:glitcher/widgets/chat_item.dart';
import 'package:glitcher/utils/data.dart';
import 'package:glitcher/widgets/user_item.dart';

class NewGroupDetails extends StatefulWidget {
  @override
  _NewGroupDetailsState createState() => _NewGroupDetailsState();
}

class _NewGroupDetailsState extends State<NewGroupDetails>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  List<User> friendsData;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: Icon(
          FontAwesome.getIconData('arrow-right'),
        ),
        onPressed: (){

        },
      ),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Constants.darkCardBG, Constants.darkBG])),
        ),
//        elevation: 4,
        leading: IconButton(
          icon: Icon(
            Icons.keyboard_backspace,
          ),
          onPressed: () {},
        ),
        title: TextField(
          decoration: InputDecoration.collapsed(
            hintText: 'Search',
          ),
        ),
      ),
      body: ListView.separated(
        padding: EdgeInsets.all(10),
        separatorBuilder: (BuildContext context, int index) {
          return Align(
            alignment: Alignment.centerRight,
            child: Container(
              height: 0.5,
              width: MediaQuery.of(context).size.width / 1.3,
              child: Divider(),
            ),
          );
        },
        itemCount: friendsData.length,
        itemBuilder: (BuildContext context, int index) {
          //User user = groups[index];
          return ListTile(
            contentPadding: EdgeInsets.all(0),
            leading: Stack(
              children: <Widget>[
                CircleAvatar(
                  backgroundImage: NetworkImage(
                    friendsData.elementAt(index).profileImageUrl,
                  ),
                  radius: 25,
                ),
                Positioned(
                  bottom: 0.0,
                  left: 6.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    height: 11,
                    width: 11,
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: friendsData.elementAt(index).online == 'online'
                              ? Colors.greenAccent
                              : Colors.grey,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        height: 7,
                        width: 7,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              friendsData.elementAt(index).username,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(friendsData.elementAt(index).description),
          );
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
