import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String imageUrl;
  final String game;
  final String text;
  int likesCount;
  int disLikesCount;
  final int commentsCount;
  final String authorId;
  var video;
  final String youtubeId;
  final Timestamp timestamp;

  Post({
    this.id,
    this.game,
    this.imageUrl,
    this.text,
    this.likesCount,
    this.disLikesCount,
    this.commentsCount,
    this.authorId,
    this.video,
    this.youtubeId,
    this.timestamp,
  });

  factory Post.fromDoc(DocumentSnapshot doc) {
    return Post(
      id: doc.documentID,
      game: doc['game'],
      imageUrl: doc['image'],
      text: doc['text'],
      likesCount: doc['likes'],
      disLikesCount: doc['dislikes'],
      commentsCount: doc['comments'],
      authorId: doc['author'],
      video: doc['video'],
      youtubeId: doc['youtubeId'],
      timestamp: doc['timestamp'],
    );
  }
}
