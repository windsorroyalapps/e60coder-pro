import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class ChannelEvent {
  final DateTime time;
  final String channel;
  final String direction;
  final String summary;
  final String raw;
  final String decoded;
  final Map<String, String> meta;

  ChannelEvent({required this.time, required this.channel, required this.direction, required this.summary, this.raw = '', this.decoded = '', this.meta = const {}});

  Map<String, dynamic> toJson() => {'time': time.toIso8601String(), 'channel': channel, 'direction': direction, 'summary': summary, 'raw': raw, 'decoded': decoded, 'meta': meta};

  factory ChannelEvent.fromJson(Map<String, dynamic> j) => ChannelEvent(
        time: DateTime.tryParse(j['time'] as String? ?? '') ?? DateTime.now(),
        channel: j['channel'] as String? ?? 'SYSTEM',
        direction: j['direction'] as String? ?? 'EVT',
        summary: j['summary'] as String? ?? '',
        raw: j['raw'] as String? ?? '',
        decoded: j['decoded'] as String? ?? '',
        meta: Map<String, String>.from((j['meta'] as Map?)?.map((k, v) => MapEntry('$k', '$v')) ?? {}),
      );
}

class ChannelRecording {
  final String id;
  final DateTime started;
  DateTime? ended;
  final List<ChannelEvent> events;
  String label;

  ChannelRecording({required this.id, required this.started, this.ended, List<ChannelEvent>? events, this.label = 'Session'}) : events = events ?? [];

  int get eventCount => events.length;
  String get durationLabel {
    final end = ended ?? DateTime.now();
    final s = end.difference(started).inSeconds;
    return '${s ~/ 60}m ${s % 60}s';
  }

  Map<String, dynamic> toJson() => {'id': id, 'started': started.toIso8601String(), 'ended': ended?.toIso8601String(), 'label': label, 'events': events.map((e) => e.toJson()).toList()};

  factory ChannelRecording.fromJson(Map<String, dynamic> j) => ChannelRecording(
        id: j['id'] as String? ?? 'unknown',
        started: DateTime.tryParse(j['started'] as String? ?? '') ?? DateTime.now(),
        ended: j['ended'] != null ? DateTime.tryParse(j['ended'] as String) : null,
        label: j['label'] as String? ?? 'Session',
        events: (j['events'] as List?)?.map((e) => ChannelEvent.fromJson(Map<String, dynamic>.from(e as Map))).toList() ?? [],
      );
}

class ChannelRecorder extends ChangeNotifier {
  static ChannelRecorder? instance;

  bool _recording = false;
  ChannelRecording? _active;
  final List<ChannelRecording> _history = [];
  static const int maxEventsPerSession = 2000;

  ChannelRecorder() {
    instance = this;
  }

  bool get isRecording => _recording;
  ChannelRecording? get active => _active;
  List<ChannelRecording> get history => List.unmodifiable(_history);

  void start({String label = 'Session'}) {
    if (_recording) return;
    _active = ChannelRecording(id: DateTime.now().millisecondsSinceEpoch.toString(), started: DateTime.now(), label: label);
    _recording = true;
    logEvent(channel: 'SYSTEM', direction: 'EVT', summary: 'Recording started', decoded: 'Session "$label" began');
    notifyListeners();
  }

  void stop() {
    if (!_recording || _active == null) return;
    logEvent(channel: 'SYSTEM', direction: 'EVT', summary: 'Recording stopped', decoded: '${_active!.eventCount} events captured');
    _active!.ended = DateTime.now();
    _history.insert(0, _active!);
    if (_history.length > 20) _history.removeLast();
    _recording = false;
    _active = null;
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  void logEvent({required String channel, required String direction, required String summary, String raw = '', String? decoded, Map<String, String> meta = const {}}) {
    if (!_recording || _active == null) return;
    final autoDecoded = decoded ?? decodePayload(channel: channel, direction: direction, raw: raw, summary: summary);
    _active!.events.add(ChannelEvent(time: DateTime.now(), channel: channel, direction: direction, summary: summary, raw: raw, decoded: autoDecoded, meta: meta));
    if (_active!.events.length > maxEventsPerSession) _active!.events.removeAt(0);
    notifyListeners();
  }

  static String decodePayload({required String channel, required String direction, required String raw, required String summary}) {
    final text = raw.isNotEmpty ? raw : summary;
    final upper = text.toUpperCase();
    if (channel == 'OBD' || channel == 'BLE') {
      final obd = _decodeObd(upper, text);
      if (obd != null) return obd;
    }
    if (summary.toLowerCase().contains('connected')) return 'Link up — GATT session active';
    if (summary.toLowerCase().contains('disconnect')) return 'Link down — session ended or lost';
    if (summary.toLowerCase().contains('scan')) return 'Discovery phase — advertising only, no data tunnel yet';
    if (RegExp(r'^[0-9A-F\s]+$', caseSensitive: false).hasMatch(text.trim()) && text.trim().length >= 4) {
      return 'Binary/hex frame (${text.trim().split(RegExp(r'\s+')).length} bytes) — inspect raw';
    }
    return text.isEmpty ? 'No payload' : 'Pass-through: $text';
  }

  static String? _decodeObd(String upper, String original) {
    if (upper.startsWith('ATZ')) return 'ELM: reset adapter';
    if (upper.startsWith('ATE0')) return 'ELM: echo off';
    if (upper.startsWith('ATL0')) return 'ELM: linefeeds off';
    if (upper.startsWith('ATS0')) return 'ELM: spaces off';
    if (upper.startsWith('ATH1')) return 'ELM: headers on';
    if (upper.startsWith('ATSP')) return 'ELM: set protocol';
    if (upper.contains('0100')) return 'OBD: request supported PIDs (01 00)';
    if (upper.contains('010C')) return 'OBD: request Engine RPM (PID 0C)';
    if (upper.contains('010D')) return 'OBD: request Vehicle Speed (PID 0D)';
    if (upper.contains('0105')) return 'OBD: request Coolant Temp (PID 05)';
    if (upper.contains('0111')) return 'OBD: request Throttle Position (PID 11)';
    final rpmMatch = RegExp(r'41\s*0C\s*([0-9A-F]{2})\s*([0-9A-F]{2})', caseSensitive: false).firstMatch(upper);
    if (rpmMatch != null) {
      final a = int.parse(rpmMatch.group(1)!, radix: 16);
      final b = int.parse(rpmMatch.group(2)!, radix: 16);
      return 'OBD response: RPM = ${((a * 256) + b) ~/ 4}';
    }
    final spdMatch = RegExp(r'41\s*0D\s*([0-9A-F]{2})', caseSensitive: false).firstMatch(upper);
    if (spdMatch != null) return 'OBD response: Speed = ${int.parse(spdMatch.group(1)!, radix: 16)} km/h';
    final coolMatch = RegExp(r'41\s*05\s*([0-9A-F]{2})', caseSensitive: false).firstMatch(upper);
    if (coolMatch != null) return 'OBD response: Coolant = ${int.parse(coolMatch.group(1)!, radix: 16) - 40} °C';
    if (upper.contains('NO DATA')) return 'OBD: no data for PID';
    if (upper.contains('SEARCHING')) return 'ELM: searching for protocol';
    if (upper.contains('UNABLE')) return 'ELM: unable to connect';
    return null;
  }

  String exportJson(ChannelRecording rec) => const JsonEncoder.withIndent('  ').convert(rec.toJson());
}
