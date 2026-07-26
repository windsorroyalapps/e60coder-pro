import 'dart:async';
import 'package:flutter/foundation.dart';

class MediaControlService extends ChangeNotifier {
  String? deviceName;
  String? deviceId;
  String primaryType;

  bool isPlaying = false;
  double volume = 0.7;
  int positionMs = 0;
  int durationMs = 180000;
  String title = 'No track';
  String artist = '—';
  String album = '';

  bool _connected = false;
  Timer? _tick;

  bool get isLinked => _connected;

  void attach({required String name, required String id, String type = 'Audio / media'}) {
    deviceName = name;
    deviceId = id;
    primaryType = type;
    _connected = true;
    title = 'E60 Cabin Session';
    artist = 'BMW Drive';
    album = 'Live Link';
    durationMs = 240000;
    positionMs = 32000;
    notifyListeners();
  }

  void detach() {
    _tick?.cancel();
    _tick = null;
    isPlaying = false;
    _connected = false;
    deviceName = null;
    deviceId = null;
    notifyListeners();
  }

  void play() {
    if (!_connected) return;
    isPlaying = true;
    _startTick();
    notifyListeners();
  }

  void pause() {
    isPlaying = false;
    _tick?.cancel();
    _tick = null;
    notifyListeners();
  }

  void togglePlayPause() {
    if (isPlaying) {
      pause();
    } else {
      play();
    }
  }

  void next() {
    if (!_connected) return;
    positionMs = 0;
    title = 'Next Track';
    artist = deviceName ?? 'Device';
    notifyListeners();
  }

  void previous() {
    if (!_connected) return;
    positionMs = 0;
    title = 'Previous Track';
    artist = deviceName ?? 'Device';
    notifyListeners();
  }

  void setVolume(double v) {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
  }

  void seek(double fraction) {
    positionMs = (durationMs * fraction.clamp(0.0, 1.0)).round();
    notifyListeners();
  }

  void _startTick() {
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isPlaying) return;
      positionMs += 1000;
      if (positionMs >= durationMs) {
        positionMs = 0;
        next();
      }
      notifyListeners();
    });
  }

  static String formatTime(int ms) {
    final s = (ms / 1000).floor();
    final m = s ~/ 60;
    final r = s % 60;
    return '$m:${r.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }
}
