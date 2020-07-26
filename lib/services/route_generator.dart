import 'package:flutter/material.dart';
import 'package:glitcher/root_page.dart';
import 'package:glitcher/screens/about/about_us.dart';
import 'package:glitcher/screens/about/cookie_use.dart';
import 'package:glitcher/screens/about/help_center.dart';
import 'package:glitcher/screens/about/legal_notices.dart';
import 'package:glitcher/screens/about/privacy_policy.dart';
import 'package:glitcher/screens/about/terms_of_service.dart';
import 'package:glitcher/screens/app_page.dart';
import 'package:glitcher/screens/bookmarks.dart';
import 'package:glitcher/screens/chats/add_members_to_group.dart';
import 'package:glitcher/screens/chats/chats.dart';
import 'package:glitcher/screens/chats/conversation.dart';
import 'package:glitcher/screens/chats/group_conversation.dart';
import 'package:glitcher/screens/chats/group_details.dart';
import 'package:glitcher/screens/chats/group_members.dart';
import 'package:glitcher/screens/chats/new_group.dart';
import 'package:glitcher/screens/welcome/login_page.dart';
import 'package:glitcher/screens/users/users_screen.dart';
import 'package:glitcher/screens/games/game_screen.dart';
import 'package:glitcher/screens/games/new_game.dart';
import 'package:glitcher/screens/hashtag_posts_screen.dart';
import 'package:glitcher/screens/posts/comments/add_comment.dart';
import 'package:glitcher/screens/posts/comments/add_reply.dart';
import 'package:glitcher/screens/posts/comments/edit_comment.dart';
import 'package:glitcher/screens/posts/comments/edit_reply.dart';
import 'package:glitcher/screens/posts/new_post/create_post.dart';
import 'package:glitcher/screens/posts/new_post/edit_post.dart';
import 'package:glitcher/screens/posts/post_preview.dart';
import 'package:glitcher/screens/profile/profile_screen.dart';
import 'package:glitcher/screens/report_post_screen.dart';
import 'package:glitcher/screens/settings.dart';
import 'package:glitcher/screens/suggestion_screen.dart';
import 'package:glitcher/screens/web_browser/in_app_browser.dart';
import 'package:glitcher/screens/welcome/password_reset.dart';
import 'package:glitcher/screens/welcome/signup_page.dart';
import 'package:page_transition/page_transition.dart';

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
        return MaterialPageRoute(builder: (_) => CreatePost());

      case '/edit-post':
        return MaterialPageRoute(builder: (_) => EditPost(post: args['post']));

      case '/user-profile':
        return MaterialPageRoute(
          builder: (_) => ProfileScreen(
            args['userId'],
          ),
        );

      case '/post':
        // Validation of correct data type
        return PageTransition(
            child: PostPreview(
              post: args['post'],
            ),
            type: PageTransitionType.scale);
        // If args is not of the correct type, return an error page.
        // You can also throw an exception while in development.
        return _errorRoute();

      case '/add-comment':
        // Validation of correct data type
        return MaterialPageRoute(
          builder: (_) => AddComment(
            post: args['post'],
            user: args['user'],
          ),
        );

      case '/edit-comment':
        // Validation of correct data type
        return MaterialPageRoute(
          builder: (_) => EditComment(
            post: args['post'],
            user: args['user'],
            comment: args['comment'],
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

      case '/conversation':
        return MaterialPageRoute(
            builder: (_) => Conversation(
                  otherUid: args['otherUid'],
                ));

      case '/group-conversation':
        return MaterialPageRoute(
            builder: (_) => GroupConversation(
                  groupId: args['groupId'],
                ));

      case '/group-members':
        return MaterialPageRoute(
            builder: (_) => GroupMembers(
                  groupId: args['groupId'],
                ));

      case '/add-members-to-group':
        return MaterialPageRoute(
            builder: (_) => AddMembersToGroup(
                  args['groupId'],
                ));

      case '/new-group':
        return MaterialPageRoute(builder: (_) => NewGroup());

      case '/group-details':
        return MaterialPageRoute(builder: (_) => GroupDetails(args['groupId']));

      case '/chats':
        return MaterialPageRoute(builder: (_) => Chats());

      case '/about-us':
        return MaterialPageRoute(builder: (_) => AboutUs());
      case '/cookie-use':
        return MaterialPageRoute(builder: (_) => CookieUse());
      case '/help-center':
        return MaterialPageRoute(builder: (_) => HelpCenter());
      case '/legal-notices':
        return MaterialPageRoute(builder: (_) => LegalNotices());
      case '/terms-of-service':
        return MaterialPageRoute(builder: (_) => TermsOfService());
      case '/privacy-policy':
        return MaterialPageRoute(builder: (_) => PrivacyPolicy());
      case '/browser':
        return MaterialPageRoute(builder: (_) => InAppBrowser(args['url']));
      case '/hashtag-posts':
        return MaterialPageRoute(
            builder: (_) => HashtagPostsScreen(args['hashtag']));
      case '/settings':
        return MaterialPageRoute(builder: (_) => SettingsScreen());

      case '/add-reply':
        // Validation of correct data type
        return MaterialPageRoute(
          builder: (_) => AddReply(
            post: args['post'],
            comment: args['comment'],
            user: args['user'],
            mention: args['mention'],
          ),
        );

        case '/edit-reply':
        // Validation of correct data type
        return MaterialPageRoute(
          builder: (_) => EditReply(
            post: args['post'],
            comment: args['comment'],
            reply: args['reply'],
            user: args['user'],
          ),
        );


      case '/bookmarks':
        return MaterialPageRoute(builder: (_) => BookmarksScreen());

      case '/users':
        return MaterialPageRoute(
            builder: (_) => UsersScreen(
                  screenType: args['screen_type'],
                ));

      case '/report-post':
        return MaterialPageRoute(builder: (_) => ReportPostScreen(postAuthor: args['post_author'], postId: args['post_id'],));

      case '/suggestion':
        return MaterialPageRoute(builder: (_) => SuggestionScreen(initialTitle: args['initial_title'], initialDetails: args['initial_details'], gameId: args['game_id'],));

      case 'sign-up':
        return MaterialPageRoute(builder: (_) => SignUpPage());

      case 'login':
        return MaterialPageRoute(builder: (_) => LoginPage());

      case 'password-reset':
        return MaterialPageRoute(builder: (_) => PasswordResetScreen());


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
