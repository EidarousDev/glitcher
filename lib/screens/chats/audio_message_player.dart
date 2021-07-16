import 'package:flutter/cupertino.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:just_audio/just_audio.dart';

class MyAudioPlayer with ChangeNotifier {
  AudioPlayer advancedPlayer = AudioPlayer();
  //AudioCache audioCache;

  get isPlaying => advancedPlayer.playing;

  Duration duration;
  Duration position;
  final List<String> urlList;
  final Function onComplete;
  final Function onPlayingStarted;
  final bool isLocal;

  MyAudioPlayer(
      {this.urlList,
      this.isLocal = false,
      this.onComplete,
      this.onPlayingStarted}) {
    initAudioPlayer();
  }

  int index = 0;

  bool onPlayingStartedCalled = false;

  initAudioPlayer() async {
    advancedPlayer = AudioPlayer();
    //audioCache = AudioCache(fixedPlayer: advancedPlayer);
    if (isLocal)
      duration = await advancedPlayer.setFilePath(urlList[index]);
    else
      duration = await advancedPlayer.setUrl(urlList[index]);

    advancedPlayer.positionStream.listen((p) {
      if (onPlayingStarted != null) {
        if (p > Duration(microseconds: 1) && !onPlayingStartedCalled) {
          onPlayingStarted();
          onPlayingStartedCalled = true;
        }
      }
      position = p;
      print('P:${p.inMilliseconds}');
      print('D:${duration.inMilliseconds}');
      notifyListeners();

      if (duration.inMilliseconds - p.inMilliseconds <
          Constants.endPositionOffsetInMilliSeconds) {
        stop();
        if (urlList.length > 1) {
          if (this.index < urlList.length - 1)
            this.index++;
          else
            this.index = 0;
          play(index: this.index);
          notifyListeners();
        } else {
          stop();
        }
      } else if (duration.inMilliseconds - p.inMilliseconds == 0) {
        if (urlList.length > 1) {
          if (this.index < urlList.length - 1)
            this.index++;
          else
            this.index = 0;
          play(index: this.index);
          notifyListeners();
        } else {
          stop();
        }
      }
    });
  }

  Future play({index = 0}) async {
    if (index == null) {
      index = this.index;
    }
    if (isLocal)
      duration = await advancedPlayer.setFilePath(urlList[index]);
    else
      duration = await advancedPlayer.setUrl(urlList[index]);
    await advancedPlayer.play();

    notifyListeners();
  }

  Future stop() async {
    await advancedPlayer.pause();
    await advancedPlayer.seek(Duration.zero);
    // position = null;
    // duration = null;
    notifyListeners();
  }

  Future pause() async {
    await advancedPlayer.pause();
    notifyListeners();
  }

  seek(Duration p) {
    advancedPlayer.seek(p);
    notifyListeners();
  }

  next() {
    advancedPlayer.stop();
    if (this.index < urlList.length - 1)
      this.index++;
    else
      this.index = 0;
    notifyListeners();
    play(index: this.index);
  }

  prev() {
    advancedPlayer.stop();
    if (this.index > 0)
      this.index--;
    else
      this.index = urlList.length - 1;
    notifyListeners();
    play(index: this.index);
  }
}
