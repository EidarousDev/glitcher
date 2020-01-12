import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String sender;
  final String text;
  final String image;
  final dynamic timestamp;
  final String type;

  Message({
    this.id,
    this.sender,
    this.text,
    this.image,
    this.timestamp,
    this.type
  });

  factory Message.fromDoc(DocumentSnapshot doc) {
    return Message(
      id: doc.documentID,
      sender: doc['sender'],
      text: doc['text'],
      image: doc['image'],
      timestamp: doc['timestamp'],
      type: doc['type'],
    );
  }
}
