import 'package:flutter/material.dart';
import 'package:glitcher/root_page.dart';
import 'package:glitcher/screens/app_page.dart';
import 'package:glitcher/screens/games/game_screen.dart';
import 'package:glitcher/screens/games/new_game.dart';
import 'package:glitcher/screens/posts/add_comment.dart';
import 'package:glitcher/screens/posts/new_comment.dart';
import 'package:glitcher/screens/posts/new_post.dart';
import 'package:glitcher/screens/user_timeline/profile_screen.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Getting arguments passed in while calling Navigator.pushNamed
    final Map args = settings.arguments as Map;

    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => RootPage());
      case '/home':
        return MaterialPageRoute(builder: (_) => AppPage());
      case '/new-post':
        return MaterialPageRoute(builder: (_) => NewPost());
      case '/user-profile':
        return MaterialPageRoute(
          builder: (_) => ProfileScreen(
            args['userId'],
          ),
        );
      case '/post':
        // Validation of correct data type
        return MaterialPageRoute(
          builder: (_) => NewComment(
            postId: args['postId'],
            commentsNo: args['commentsNo'],
          ),
        );
        // If args is not of the correct type, return an error page.
        // You can also throw an exception while in development.
        return _errorRoute();

      case '/add-comment':
        // Validation of correct data type
        return MaterialPageRoute(
          builder: (_) => AddCommentScreen(
            username: args['username'],
            userId: args['userId'],
            postId: args['postId'],
            profileImageUrl: args['profileImageUrl'],
          ),
        );

      case '/game-screen':
        return MaterialPageRoute(
          builder: (_) => GameScreen(
            game: args['game'],
          ),
        );

      case '/new-game':
        return MaterialPageRoute(builder: (_) => NewGame());
      default:
        // If there is no such named route in the switch statement, e.g. /third
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Error'),
        ),
        body: Center(
          child: Text('ERROR'),
        ),
      );
    });
  }
}
