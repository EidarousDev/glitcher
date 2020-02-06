import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:glitcher/models/post_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/screens/user_timeline/profile_screen.dart';
import 'package:glitcher/services/share_link.dart';
import 'package:glitcher/utils/constants.dart';
import 'package:share/share.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class PostItem extends StatefulWidget {
  final Post post;
  final User author;

  PostItem({Key key, @required this.post, @required this.author})
      : super(key: key);
  @override
  _PostItemState createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  YoutubePlayerController _youtubeController;
  bool _isPlaying;
  AssetsAudioPlayer assetsAudioPlayer = AssetsAudioPlayer();
  VideoPlayerController videoPlayerController;
  ChewieController chewieController;
  Chewie playerWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: InkWell(
        child: _buildPost(widget.post, widget.author),
        onTap: () {},
      ),
    );
  }

  _buildPost(Post post, User author) {
    return Column(
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ProfileScreen(post.authorId)));
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  radius: 25.0,
                  backgroundColor: Colors.grey,
                  backgroundImage: author.profileImageUrl != null
                      ? NetworkImage(author.profileImageUrl)
                      : AssetImage('assets/images/default_profile.png'),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Text('@${author.username}' ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                )),
                          ],
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                        )
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 0.0, bottom: 8.0),
                      child: Text(
                        post.text ?? '',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      child: post.imageUrl == null
                          ? null
                          : Container(
                              width: double.infinity,
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.network(post.imageUrl)),
                            ),
                    ),
                    Container(
                      child: post.video == null ? null : playerWidget,
                    ),
                    Container(child: null
                        //TODO: Fix YouTube Player
//                      post.youtubeId == null
//                          ? null
//                          : YoutubePlayer(
//                              context: context,
//                              videoId: post.youtubeId,
//                              flags: YoutubePlayerFlags(
//                                autoPlay: false,
//                                showVideoProgressIndicator: true,
//                                forceHideAnnotation: true,
//                              ),
//                              videoProgressIndicatorColor: Colors.red,
//                              progressColors: ProgressColors(
//                                playedColor: Colors.red,
//                                handleColor: Colors.redAccent,
//                              ),
//                              onPlayerInitialized: (controller) {
//                                _youtubeController = controller;
//                                _youtubeController.addListener(listener);
//                              },
//                            ),
                        ),
                  ],
                ),
              ),
            )
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            width: double.infinity,
            height: .5,
          ),
        ),
        SizedBox(
          height: 1.0,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
                color: currentTheme == AvailableThemes.LIGHT_THEME
                    ? Constants.lightLineBreak
                    : Constants.darkLineBreak),
          ),
        ),
        Container(
          height: inlineBreak,
          color: currentTheme == AvailableThemes.LIGHT_THEME
              ? Constants.lightPrimary
              : Constants.darkAccent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              SizedBox(
                height: 14.0,
                width: 18.0,
                child: IconButton(
                  padding: new EdgeInsets.all(0.0),
                  icon: Icon(
                    FontAwesome.getIconData('thumbs-o-up'),
                    size: 18.0,
                  ),
                  onPressed: () async {
                    assetsAudioPlayer.open(AssetsAudio(
                      asset: "like_sound.mp3",
                      folder: "assets/sounds/",
                    ));
                    assetsAudioPlayer.play();

                    //Likes Handling was here
                  },
                ),
              ),
              SizedBox(
                  height: 14.0,
                  width: 18.0,
                  child: Text(
                    post.likesCount.toString(),
                  )),
              SizedBox(
                width: 1.0,
                height: inlineBreak,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      color: currentTheme == AvailableThemes.LIGHT_THEME
                          ? Constants.lightInLineBreak
                          : Constants.darkLineBreak),
                ),
              ),
              SizedBox(
                height: 14.0,
                width: 18.0,
                child: IconButton(
                  padding: new EdgeInsets.all(0.0),
                  icon: Icon(
                    FontAwesome.getIconData('thumbs-o-down'),
                    size: 18.0,
                  ),
                  onPressed: () {
                    assetsAudioPlayer.open(AssetsAudio(
                      asset: "dislike_sound.mp3",
                      folder: "assets/sounds/",
                    ));
                    assetsAudioPlayer.play();
                    //Dislikes Handling was here
                  },
                ),
              ),
              SizedBox(
                  height: 14.0,
                  width: 18.0,
                  child: Text(
                    post.disLikesCount.toString(),
                  )),
              SizedBox(
                width: 1.0,
                height: inlineBreak,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      color: currentTheme == AvailableThemes.LIGHT_THEME
                          ? Constants.lightInLineBreak
                          : Constants.darkLineBreak),
                ),
              ),
              SizedBox(
                height: 14.0,
                width: 18.0,
                child: IconButton(
                  padding: new EdgeInsets.all(0.0),
                  icon: Icon(
                    Icons.chat_bubble_outline,
                    size: 18.0,
                  ),
                  onPressed: () {
                    Navigator.of(context).pushNamed('/post', arguments: {
                      'postId': post.id,
                      'commentsNo': post.commentsCount
                    });
                  },
                ),
              ),
              SizedBox(
                  height: 14.0,
                  width: 18.0,
                  child: Text(
                    post.commentsCount.toString(),
                  )),
              SizedBox(
                width: 1.0,
                height: inlineBreak,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      color: currentTheme == AvailableThemes.LIGHT_THEME
                          ? Constants.lightInLineBreak
                          : Constants.darkLineBreak),
                ),
              ),
              SizedBox(
                height: 14.0,
                width: 18.0,
                child: IconButton(
                  padding: new EdgeInsets.all(0.0),
                  icon: Icon(
                    Icons.replay,
                    size: 18.0,
                  ),
                  onPressed: () {
                    sharePost(post.id, post.text, post.imageUrl);
                  },
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 14.0,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
                color: currentTheme == AvailableThemes.LIGHT_THEME
                    ? Constants.lightLineBreak
                    : Constants.darkLineBreak),
          ),
        ),
      ],
    );
  }

  // Sharing a post with a shortened url
  void sharePost(String postId, String postText, String imageUrl) async {
    var postLink = await DynamicLinks.createDynamicLink(
        {'postId': postId, 'postText': postText, 'imageUrl': imageUrl});
    Share.share('Check out: $postText : $postLink');
    print('Check out: $postText : $postLink');
  }

  // Youtube Video listener
  void listener() {
//    if (_youtubeController.value.playerState == PlayerState.ENDED) {
//      //_showThankYouDialog();
//    }
    if (mounted) {
//      setState(() {
//        //_playerStatus = _youtubeController.value.playerState.toString();
//        //_errorCode = _youtubeController.value.errorCode.toString();
//      });
    }
  }
}
