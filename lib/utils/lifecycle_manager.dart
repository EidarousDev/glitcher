import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import '../services/auth.dart';

class LifecycleManager extends StatefulWidget {
  @override
  _LifecycleManagerState createState() => _LifecycleManagerState();

  final Widget child;

  LifecycleManager({Key key, this.child}) : super(key: key);
}

class _LifecycleManagerState extends State<LifecycleManager>
    with WidgetsBindingObserver {
  AppLifecycleState _lastLifecycleState;

  Firestore _firestore = Firestore.instance;

  FirebaseUser currentUser;

  void getCurrentUser() async {
    this.currentUser = await Auth().getCurrentUser();
  }

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _lastLifecycleState = state;
    });

    updateOnlineUserState();
  }

  void updateOnlineUserState() async {
    if (_lastLifecycleState == AppLifecycleState.inactive ||
        _lastLifecycleState == AppLifecycleState.paused) {
      await _firestore
          .collection('users')
          .document(currentUser.uid)
          .updateData({'online': FieldValue.serverTimestamp()});
    } else if (_lastLifecycleState == AppLifecycleState.resumed) {
      await _firestore
          .collection('users')
          .document(currentUser.uid)
          .updateData({'online': 'online'});
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

void main() {
  runApp(Center(child: LifecycleManager()));
}
