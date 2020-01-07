import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String imageUrl;
  final String category;
  final String text;
  final int likesCount;
  final int disLikesCount;
  final int commentsCount;
  final String authorId;
  final String video;
  final String youtubeId;
  final Timestamp timestamp;

  Post({
    this.id,
    this.category,
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
      category: doc['category'],
      imageUrl: doc['image'],
      text: doc['text'],
      likesCount: doc['likes'],
      disLikesCount: doc['dislikes'],
      commentsCount: doc['comments'],
      authorId: doc['owner'],
      video: doc['video'],
      youtubeId: doc['youtubeId'],
      timestamp: doc['timestamp'],
    );
  }
}
