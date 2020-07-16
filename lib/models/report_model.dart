import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String id;
  final String reason;
  final String details;
  final String postAuthor;
  final String postId;
  final String submitter;
  final bool dealt;
  final Timestamp timestamp;

  Report({
    this.id,
    this.reason,
    this.details,
    this.postAuthor,
    this.postId,
    this.submitter,
    this.dealt,
    this.timestamp,
  });

  factory Report.fromDoc(DocumentSnapshot doc) {
    return Report(
      id: doc.documentID,
      reason: doc['reason'],
      details: doc['details'],
      postAuthor: doc['post_author'],
      postId: doc['post_id'],
      submitter: doc['submitter'],
      dealt: doc['dealt'],
      timestamp: doc['timestamp'],
    );
  }
}
