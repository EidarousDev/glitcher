import 'package:flutter/material.dart';
import 'package:glitcher/root_page.dart';
import 'package:glitcher/screens/posts/new_comment.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Getting arguments passed in while calling Navigator.pushNamed
    final Map args = settings.arguments as Map;

    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => RootPage());
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
