import 'package:cloud_firestore/cloud_firestore.dart';

class Hashtag {
  final String id;
  final String text;
  final Timestamp timestamp;

  Hashtag({
    this.id,
    this.text,
    this.timestamp,
  });

  factory Hashtag.fromDoc(DocumentSnapshot doc) {
    return Hashtag(
      id: doc.documentID,
      text: doc['text'],
      timestamp: doc['timestamp'],
    );
  }
}
