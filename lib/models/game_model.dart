import 'package:cloud_firestore/cloud_firestore.dart';

class Game {
  final String id;
  final String fullName;
  final String shortName;
  final String description;
  final String image;
  final String releaseDate;
  final String esrbRating;
  final String website;
  final int metacritic;
  final bool tba;
  final List genres;
  final List platforms;
  final List stores;
  final List developers;
  final List<dynamic> search;
  final int frequency;
  final dynamic timestamp;

  Game({
    this.id,
    this.fullName,
    this.shortName,
    this.description,
    this.image,
    this.releaseDate,
    this.esrbRating,
    this.website,
    this.metacritic,
    this.tba,
    this.genres,
    this.platforms,
    this.stores,
    this.developers,
    this.search,
    this.frequency,
    this.timestamp,
  });

  factory Game.fromDoc(DocumentSnapshot doc) {
    return Game(
      id: doc.id,
      fullName: doc['fullName'],
      shortName: doc['shortName'],
      description: doc['description'],
      image: doc['image'],
      releaseDate: doc['release_date'],
      esrbRating: doc['esrb_rating'],
      website: doc['website'],
      metacritic: doc['metacritic'],
      tba: doc['tba'],
      genres: doc['genres'],
      platforms: doc['platforms'],
      stores: doc['stores'],
      developers: doc['developers'],
      search: doc['search'],
      frequency: doc['frequency'],
      timestamp: doc['timestamp'],
    );
  }
}
