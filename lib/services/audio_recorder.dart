import 'dart:async';
import 'dart:io' as io;
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:glitcher/screens/chats/group_conversation.dart';
import 'package:path_provider/path_provider.dart';

class AudioRecorder {
  FlutterAudioRecorder _recorder;
  Recording _recording;
  Timer timer;

  Future init() async {
    String customPath = '/flutter_audio_recorder_';
    io.Directory appDocDirectory;
    if (io.Platform.isIOS) {
      appDocDirectory = await getApplicationDocumentsDirectory();
    } else {
      appDocDirectory = await getExternalStorageDirectory();
    }

    // can add extension like ".mp4" ".wav" ".m4a" ".aac"
    customPath = appDocDirectory.path +
        customPath +
        DateTime.now().millisecondsSinceEpoch.toString();

    // .wav <---> AudioFormat.WAV
    // .mp4 .m4a .aac <---> AudioFormat.AAC
    // AudioFormat is optional, if given value, will overwrite path extension when there is conflicts.

    _recorder = FlutterAudioRecorder(customPath,
        audioFormat: AudioFormat.WAV, sampleRate: 22050);
    await _recorder.initialized;
  }

  Future startRecording({var conversation}) async {
    await _recorder.start();
    var current = await _recorder.current();

    _recording = current;

    Timer.periodic(Duration(milliseconds: 10), (Timer t) async {
      var current = await _recorder.current();

      _recording = current;
      timer = t;
     if(conversation != null){
       conversation.updateRecordTime(timer.tick.toString());
     }
    });
  }

  Future stopRecording() async {
    timer.cancel();
    var result = await _recorder.stop();
    _recording = result;
    return result;
  }
}
