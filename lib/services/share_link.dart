import 'dart:async';

import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:glitcher/constants/strings.dart';

class DynamicLinks {
  static String _urlPrefix = 'https://m.gl1tch3r.com/';

  static Future<Uri> createPostDynamicLink(Map<String, String> args) async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      // This should match firebase but without the username query param
      uriPrefix: _urlPrefix,
      // This can be whatever you want for the uri, https://yourapp.com/groupinvite?username=$userName
      link: Uri.parse('$_urlPrefix/posts/${args["postId"]}'),
      socialMetaTagParameters: SocialMetaTagParameters(
        title: '${args["text"]}'.length > 25
            ? '${args["text"]}'.replaceRange(25, args["text"].length, '...')
            : '${args["text"]}',
        description: '${args["text"]}',
        imageUrl: Uri.parse('${args["imageUrl"]}'),
      ),
      androidParameters: AndroidParameters(
        packageName: Strings.packageName,
      ),
    );
    final link = await parameters.buildUrl();
    final ShortDynamicLink shortenedLink =
        await DynamicLinkParameters.shortenUrl(
      link,
      DynamicLinkParametersOptions(
          shortDynamicLinkPathLength: ShortDynamicLinkPathLength.unguessable),
    );
    return shortenedLink.shortUrl;
  }

  static Future<Uri> createProfileDynamicLink(Map<String, String> args) async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      // This should match firebase but without the username query param
      uriPrefix: _urlPrefix,
      // This can be whatever you want for the uri, https://yourapp.com/groupinvite?username=$userName
      link: Uri.parse('$_urlPrefix/users/${args["userId"]}'),
      socialMetaTagParameters: SocialMetaTagParameters(
        title: '${args["text"]}'.length > 25
            ? '${args["text"]}'.replaceRange(25, args["text"].length, '...')
            : '${args["text"]}',
        description: '${args["text"]}',
        imageUrl: Uri.parse('${args["imageUrl"]}'),
      ),
      androidParameters: AndroidParameters(
        packageName: Strings.packageName,
      ),
    );
    final link = await parameters.buildUrl();
    final ShortDynamicLink shortenedLink =
        await DynamicLinkParameters.shortenUrl(
      link,
      DynamicLinkParametersOptions(
          shortDynamicLinkPathLength: ShortDynamicLinkPathLength.unguessable),
    );
    return shortenedLink.shortUrl;
  }

  static Future<Uri> createGameDynamicLink(Map<String, String> args) async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      // This should match firebase but without the username query param
      uriPrefix: _urlPrefix,
      // This can be whatever you want for the uri, https://yourapp.com/groupinvite?username=$userName
      link: Uri.parse('$_urlPrefix/games/${args["gameId"]}'),
      socialMetaTagParameters: SocialMetaTagParameters(
        title: '${args["text"]}'.length > 25
            ? '${args["text"]}'.replaceRange(25, args["text"].length, '...')
            : '${args["text"]}',
        description: '${args["text"]}',
        imageUrl: Uri.parse('${args["imageUrl"]}'),
      ),
      androidParameters: AndroidParameters(
        packageName: Strings.packageName,
      ),
    );
    final link = await parameters.buildUrl();
    final ShortDynamicLink shortenedLink =
        await DynamicLinkParameters.shortenUrl(
      link,
      DynamicLinkParametersOptions(
          shortDynamicLinkPathLength: ShortDynamicLinkPathLength.unguessable),
    );
    return shortenedLink.shortUrl;
  }
}
