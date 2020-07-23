import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audio_cache.dart';
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
  _AudioMessagePlayerState createState() => _AudioMessagePlayerState();
}

class _AudioMessagePlayerState extends State<AudioMessagePlayer> {
  _AudioMessagePlayerState();

  Duration _duration;
  Duration position;

  AudioPlayer advancedPlayer = AudioPlayer();
  AudioCache audioCache;

  String localFilePath;

  AudioPlayerState playerState = AudioPlayerState.STOPPED;

  get isPlaying => playerState == AudioPlayerState.PLAYING;
  get isPaused => playerState == AudioPlayerState.PAUSED;

  get durationText =>
      _duration != null ? _duration.toString().split('.').first : '';

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
    advancedPlayer.stop();
    super.dispose();
  }

  void initAudioPlayer() {
    advancedPlayer = AudioPlayer();
    audioCache = AudioCache(fixedPlayer: advancedPlayer);
    advancedPlayer.durationHandler = (d) => setState((){
     _duration = d;
    });

    advancedPlayer.positionHandler = (p) => setState((){
     position = p;
    });


//    _positionSubscription =
//        advancedPlayer.onAudioPositionChanged.listen((Duration p) {
//      //print('Current position: $p');
//      setState(() => position = p);
//    });
//
//    _audioPlayerStateSubscription =
//        advancedPlayer.onPlayerStateChanged.listen((AudioPlayerState s) {
//      // print('Current player state: $s');
//      if (mounted) setState(() => playerState = s);
//    });
//
//    advancedPlayer.onDurationChanged.listen((Duration d) {
//      //print('Max duration: $d');
//      setState(() => _duration = d);
//    });
//
//    advancedPlayer.onPlayerCompletion.listen((event) {
//      setState(() {
//        position = _duration;
//        playerState = AudioPlayerState.STOPPED;
//      });
//    });
//
//    advancedPlayer.onPlayerError.listen((msg) {
//      print('audioPlayer error : $msg');
//      setState(() {
//        playerState = AudioPlayerState.STOPPED;
//        _duration = Duration(seconds: 0);
//        position = Duration(seconds: 0);
//      });
//    });

  }

  Future play() async {
    print('audio url: ${widget.url}');
    await advancedPlayer.play(widget.url);
    setState(() {
      playerState = AudioPlayerState.PLAYING;
    });
  }

  Future _playLocal() async {
    await advancedPlayer.play(localFilePath, isLocal: true);
    setState(() => playerState = AudioPlayerState.PLAYING);
  }

  Future pause() async {
    await advancedPlayer.pause();
    setState(() => playerState = AudioPlayerState.PAUSED);
  }

  Future stop() async {
    await advancedPlayer.stop();
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
    final bytes = await _loadFileBytes(widget.url,
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
          _duration == null
              ? Container()
              : SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3.0,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.0),
                    overlayShape: RoundSliderOverlayShape(overlayRadius: 12.0),
                  ),
                  child: Slider(
                      value: position?.inSeconds?.toDouble() ?? 0.0,
                      onChanged: (double value) =>
                          advancedPlayer.seek(Duration(seconds: value ~/ 1000)),
                      min: 0.0,
                      max: _duration.inSeconds.toDouble()),
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
                  (_duration?.inMilliseconds?.toDouble() ?? 0.0)
              : 0.0,
          valueColor: AlwaysStoppedAnimation(Colors.cyan),
          backgroundColor: Colors.grey.shade400,
        ),
      ),
      Text(
        position != null
            ? "${positionText ?? ''} / ${durationText ?? ''}"
            : _duration != null ? durationText : '',
        style: TextStyle(fontSize: 16.0),
      )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return _buildPlayer();
  }
}
