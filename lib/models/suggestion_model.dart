import 'package:cloud_firestore/cloud_firestore.dart';

class Suggestion {
  final String id;
  final String title;
  final String details;
  final String submitter;
  final String gameId;
  final bool dealt;
  final Timestamp timestamp;

  Suggestion({
    this.id,
    this.title,
    this.details,
    this.submitter,
    this.gameId,
    this.dealt,
    this.timestamp,
  });

  factory Suggestion.fromDoc(DocumentSnapshot doc) {
    return Suggestion(
      id: doc.id,
      title: doc['title'],
      details: doc['details'],
      submitter: doc['submitter'],
      gameId: doc['game_id'],
      dealt: doc['dealt'],
      timestamp: doc['timestamp'],
    );
  }
}
