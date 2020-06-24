import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';

typedef void OnError(Exception exception);

enum PlayerState { stopped, playing, paused }

class AudioMessagePlayer extends StatefulWidget {
  final String url;
  AudioMessagePlayer({Key key, @required this.url}) : super(key: key);

  @override
  _AudioMessagePlayerState createState() => _AudioMessagePlayerState(this.url);
}

class _AudioMessagePlayerState extends State<AudioMessagePlayer> {
  String url;
  _AudioMessagePlayerState(this.url);

  Duration duration;
  Duration position;

  AudioPlayer audioPlayer = AudioPlayer();

  String localFilePath;

  AudioPlayerState playerState = AudioPlayerState.STOPPED;

  get isPlaying => playerState == AudioPlayerState.PLAYING;
  get isPaused => playerState == AudioPlayerState.PAUSED;

  get durationText =>
      duration != null ? duration.toString().split('.').first : '';

  get positionText =>
      position != null ? position.toString().split('.').first : '';

  bool isMuted = false;

  StreamSubscription _positionSubscription;
  StreamSubscription _audioPlayerStateSubscription;

  @override
  void initState() {
    super.initState();
    initAudioPlayer();
  }

  @override
  void dispose() {
    //_positionSubscription.cancel();
    //_audioPlayerStateSubscription.cancel();
    audioPlayer.stop();
    super.dispose();
  }

  void initAudioPlayer() {
    audioPlayer = AudioPlayer();

    _positionSubscription =
        audioPlayer.onAudioPositionChanged.listen((Duration p) {
      //print('Current position: $p');
      setState(() => position = p);
    });

    _audioPlayerStateSubscription =
        audioPlayer.onPlayerStateChanged.listen((AudioPlayerState s) {
      // print('Current player state: $s');
      if (mounted) setState(() => playerState = s);
    });

    audioPlayer.onDurationChanged.listen((Duration d) {
      //print('Max duration: $d');
      setState(() => duration = d);
    });

    audioPlayer.onPlayerCompletion.listen((event) {
      setState(() {
        position = duration;
        playerState = AudioPlayerState.STOPPED;
      });
    });

    audioPlayer.onPlayerError.listen((msg) {
      print('audioPlayer error : $msg');
      setState(() {
        playerState = AudioPlayerState.STOPPED;
        duration = Duration(seconds: 0);
        position = Duration(seconds: 0);
      });
    });
//    _positionSubscription = audioPlayer.onAudioPositionChanged
//        .listen((p) => setState(() => position = p));

//    _audioPlayerStateSubscription =
//        audioPlayer.onPlayerStateChanged.listen((s) {
//      if (s == AudioPlayerState.PLAYING) {
//        setState(() => duration = audioPlayer.duration);
//      } else if (s == AudioPlayerState.STOPPED) {
//        onComplete();
//        setState(() {
//          position = duration;
//        });
//      }
//    }, onError: (msg) {
//      setState(() {
//        playerState = PlayerState.stopped;
//        duration = Duration(seconds: 0);
//        position = Duration(seconds: 0);
//      });
//    });
  }

  Future play() async {
    initAudioPlayer();
    print('audio url: ${this.url}');
    await audioPlayer.play(this.url);
    setState(() {
      playerState = AudioPlayerState.PLAYING;
    });
  }

  Future _playLocal() async {
    await audioPlayer.play(localFilePath, isLocal: true);
    setState(() => playerState = AudioPlayerState.PLAYING);
  }

  Future pause() async {
    await audioPlayer.pause();
    setState(() => playerState = AudioPlayerState.PAUSED);
  }

  Future stop() async {
    await audioPlayer.stop();
    setState(() {
      playerState = AudioPlayerState.STOPPED;
      position = Duration();
    });

    _positionSubscription.cancel();
    _audioPlayerStateSubscription.cancel();
  }

  Future<Uint8List> _loadFileBytes(String url, {OnError onError}) async {
    Uint8List bytes;
    try {
      bytes = await readBytes(url);
    } on ClientException {
      rethrow;
    }
    return bytes;
  }

  Future _loadFile() async {
    final bytes = await _loadFileBytes(this.url,
        onError: (Exception exception) =>
            print('_loadFile => exception $exception'));

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/audio.mp3');

    await file.writeAsBytes(bytes);
    if (await file.exists())
      setState(() {
        localFilePath = file.path;
      });
  }

  Widget _buildPlayer() => Container(
        padding: EdgeInsets.all(0),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          !isPlaying
              ? IconButton(
                  onPressed: isPlaying ? null : () => play(),
                  iconSize: 24.0,
                  icon: Icon(Icons.play_arrow),
                  color: Colors.cyan,
                )
              : IconButton(
                  onPressed: isPlaying ? () => pause() : null,
                  iconSize: 24.0,
                  icon: Icon(Icons.pause),
                  color: Colors.cyan,
                ),
          duration == null
              ? Container()
              : SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3.0,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.0),
                    overlayShape: RoundSliderOverlayShape(overlayRadius: 12.0),
                  ),
                  child: Slider(
                      value: position?.inMilliseconds?.toDouble() ?? 0.0,
                      onChanged: (double value) =>
                          audioPlayer.seek(Duration(seconds: value ~/ 1000)),
                      min: 0.0,
                      max: duration.inMilliseconds.toDouble()),
                ),
        ]),
      );

  Row _buildProgressView() {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Padding(
        padding: EdgeInsets.all(0),
        child: CircularProgressIndicator(
          value: position != null && position.inMilliseconds > 0
              ? (position?.inMilliseconds?.toDouble() ?? 0.0) /
                  (duration?.inMilliseconds?.toDouble() ?? 0.0)
              : 0.0,
          valueColor: AlwaysStoppedAnimation(Colors.cyan),
          backgroundColor: Colors.grey.shade400,
        ),
      ),
      Text(
        position != null
            ? "${positionText ?? ''} / ${durationText ?? ''}"
            : duration != null ? durationText : '',
        style: TextStyle(fontSize: 16.0),
      )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return _buildPlayer();
  }
}
