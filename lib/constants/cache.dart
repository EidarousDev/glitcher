import 'package:glitcher/models/notification_model.dart';
import 'package:glitcher/models/post_model.dart';
import 'package:glitcher/models/user_model.dart';

class Cache {
  static Map<String, Post> postsMap;
  static Map<String, User> usersMap;
  static Map<String, Notification> notificationsMap;
  static List<Notification> notifications;
}
