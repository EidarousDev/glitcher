import 'dart:async';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:glitcher/constants/strings.dart';

class DynamicLinks {
  static Future<Uri> createDynamicLink(Map<String, String> args) async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      // This should match firebase but without the username query param
      uriPrefix: 'https://glitcher.page.link',
      // This can be whatever you want for the uri, https://yourapp.com/groupinvite?username=$userName
      link: Uri.parse('https://glitcher.page.link/post=$args["postId"]'),
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
//
//final DynamicLinkParameters parameters = DynamicLinkParameters(
//  uriPrefix: 'https://glitcher.page.link',
//  link: Uri.parse('https://glitcher.ninja/'),
//  androidParameters: AndroidParameters(
//    packageName: Strings.packageName,
//    minimumVersion: 25,
//  ),
//  googleAnalyticsParameters: GoogleAnalyticsParameters(
//    campaign: 'example-promo',
//    medium: 'social',
//    source: 'orkut',
//  ),
//  itunesConnectAnalyticsParameters: ItunesConnectAnalyticsParameters(
//    providerToken: '123456',
//    campaignToken: 'example-promo',
//  ),
//  socialMetaTagParameters: SocialMetaTagParameters(
//    title: 'Example of a Dynamic Link',
//    description: 'This link works whether app is installed or not!',
//  ),
//);

//final Uri dynamicUrl = await parameters.buildUrl();

//final Uri dynamicUrl = await parameters.buildUrl();
//final ShortDynamicLink shortDynamicLink = parameters.buildShortLink();
//final Uri shortUrl = shortDynamicLink.shortUrl;
