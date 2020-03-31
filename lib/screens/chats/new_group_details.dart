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
      appBar:AppBar(),
      body: Column(
        children: <Widget>[
          
        ],
      )
    );
  }

  @override
  bool get wantKeepAlive => true;
}
