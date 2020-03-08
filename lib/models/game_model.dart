import 'package:cloud_firestore/cloud_firestore.dart';

class Game {
  final String id;
  final String fullName;
  final String shortName;
  final String description;
  final String image;
  final String genre;
  final dynamic timestamp;

  Game({
    this.id,
    this.fullName,
    this.shortName,
    this.description,
    this.image,
    this.timestamp,
    this.genre
  });

  factory Game.fromDoc(DocumentSnapshot doc) {
    return Game(
      id: doc.documentID,
      fullName: doc['fullName'],
      shortName: doc['shortName'],
      description: doc['description'],
      image: doc['image'],
      genre: doc['genre'],
      timestamp: doc['timestamp'],
    );
  }
}