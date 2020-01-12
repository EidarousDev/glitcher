import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

final _firestore = Firestore.instance;
final storageRef = FirebaseStorage.instance.ref();
final postsRef = _firestore.collection('posts');
final usersRef = _firestore.collection('users');
final chatsRef = _firestore.collection('chats');

class Constants {
  static const categories = [
    'Uncategorized',
    'Brawl Stars',
    'COD Mobile',
    'Batman: Arkham Knight'
  ];
}
