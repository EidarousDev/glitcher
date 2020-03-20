import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String commenterID;
  final String text;
  int likesCount;
  int disLikesCount;
  final Timestamp timestamp;

  Comment({
    this.id,
    this.commenterID,
    this.text,
    this.likesCount,
    this.disLikesCount,
    this.timestamp,
  });

  factory Comment.fromDoc(DocumentSnapshot doc) {
    return Comment(
      id: doc.documentID,
      commenterID: doc['commenter'],
      text: doc['text'],
      likesCount: doc['likes'],
      disLikesCount: doc['dislikes'],
      timestamp: doc['timestamp'],
    );
  }
}
