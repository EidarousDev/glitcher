import 'package:cloud_firestore/cloud_firestore.dart';

class Game {
  final String id;
  final String fullName;
  final String shortName;
  final String description;
  final String image;
  final List genres;
  final List<dynamic> search;
  final dynamic timestamp;

  Game({
    this.id,
    this.fullName,
    this.shortName,
    this.description,
    this.image,
    this.genres,
    this.search,
    this.timestamp,
  });

  factory Game.fromDoc(DocumentSnapshot doc) {
    return Game(
      id: doc.documentID,
      fullName: doc['fullName'],
      shortName: doc['shortName'],
      description: doc['description'],
      image: doc['image'],
      genres: doc['genres'],
      search: doc['search'],
      timestamp: doc['timestamp'],
    );
  }
}
