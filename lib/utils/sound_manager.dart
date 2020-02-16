import 'dart:async';
import 'dart:io';

import 'package:audioplayer/audioplayer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

class SoundManager {
  AudioPlayer audioPlayer = new AudioPlayer();

  Future playLocal(localFileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = new File("${dir.path}/$localFileName");
    if (!(await file.exists())) {
      final soundData = await rootBundle.load("assets/sounds/$localFileName");
      final bytes = soundData.buffer.asUint8List();
      await file.writeAsBytes(bytes, flush: true);
    }
    await audioPlayer.play(file.path, isLocal: true);
  }
}
