import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Game {
  final String id;
  final String fullName;
  final String shortName;
  final String description;
  final String image;
  final String genre;
  final List<dynamic> search;
  final dynamic timestamp;

  Game({
    this.id,
    this.fullName,
    this.shortName,
    this.description,
    this.image,
    this.genre,
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
      genre: doc['genre'],
      search: doc['search'],
      timestamp: doc['timestamp'],
    );
  }
}