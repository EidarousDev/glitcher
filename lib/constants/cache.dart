import 'package:glitcher/models/notification_model.dart';
import 'package:glitcher/models/post_model.dart';
import 'package:glitcher/models/user_model.dart';

class Cache {
  static Map<String, Post> posts;
  static Map<String, User> users;
  static Map<String, Notification> notifications;
}
