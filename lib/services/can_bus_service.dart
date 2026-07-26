import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// CAN access via OBD/Wi-Fi/BT gateway only. Phone is not on the CAN wires.
/// Use only on vehicles you own or are authorized to diagnose.
class CanBusService extends ChangeNotifier {
  bool _connected = false;
  String _status = 'Disconnected';
  String _transport = 'none';
  final List<CanFrame> _frames = [];
  Socket? _socket;
  StreamSubscription<List<int>>? _sub;
  final StringBuffer _rxBuf = StringBuffer();

  bool get isConnected => _connected;
  String get status => _status;
  String get transport => _transport;
  List<CanFrame> get frames => List.unmodifiable(_frames);

  Future<void> connectWifi({String host = '192.168.0.10', int port = 35000}) async {
    await disconnect();
    _status = 'Connecting Wi-Fi $host:$port…';
    notifyListeners();
    try {
      _socket = await Socket.connect(host, port, timeout: const Duration(seconds: 5));
      _transport = 'wifi';
      _connected = true;
      _status = 'Wi-Fi OBD/CAN gateway connected';
      _sub = _socket!.listen(_onBytes, onError: (e) {
        _status = 'Socket error: $e';
        _connected = false;
        notifyListeners();
      }, onDone: () {
        _status = 'Socket closed';
        _connected = false;
        notifyListeners();
      });
      await _initElm();
      notifyListeners();
    } catch (e) {
      _status = 'Wi-Fi connect failed: $e';
      _connected = false;
      notifyListeners();
    }
  }

  void startDemo() {
    disconnect();
    _transport = 'demo';
    _connected = true;
    _status = 'DEMO CAN stream';
    notifyListeners();
    Timer.periodic(const Duration(milliseconds: 200), (t) {
      if (!_connected || _transport != 'demo') {
        t.cancel();
        return;
      }
      final id = 0x0C8 + (DateTime.now().millisecond % 8);
      final data = List<int>.generate(8, (i) => (DateTime.now().millisecond + i * 17) & 0xFF);
      _pushFrame(CanFrame(id: id, data: data, source: 'demo', decoded: _lightDecode(id, data)));
    });
  }

  void attachBluetoothBridge() {
    _transport = 'bluetooth_bridge';
    _connected = true;
    _status = 'Using Bluetooth OBD as CAN gateway';
    notifyListeners();
  }

  Future<void> disconnect() async {
    await _sub?.cancel();
    _sub = null;
    await _socket?.close();
    _socket = null;
    _connected = false;
    _transport = 'none';
    _status = 'Disconnected';
    notifyListeners();
  }

  Future<void> sendCommand(String cmd) async {
    if (!_connected) return;
    final line = cmd.endsWith('\r') ? cmd : '$cmd\r';
    if (_socket != null) {
      _socket!.add(line.codeUnits);
      _pushFrame(CanFrame(id: 0, data: [], source: 'TX', decoded: 'CMD: $cmd', isCommand: true));
    } else if (_transport == 'demo') {
      _pushFrame(CanFrame(id: 0, data: [], source: 'TX', decoded: 'CMD (demo): $cmd', isCommand: true));
    }
    notifyListeners();
  }

  Future<void> startMonitorAll() async {
    await sendCommand('ATMA');
    _status = 'Monitor mode requested (ATMA)';
    notifyListeners();
  }

  Future<void> stopMonitor() async {
    await sendCommand(' ');
    _status = 'Monitor stop signal sent';
    notifyListeners();
  }

  Future<void> _initElm() async {
    for (final c in ['ATZ', 'ATE0', 'ATL0', 'ATS0', 'ATH1', 'ATSP6']) {
      await sendCommand(c);
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  void _onBytes(List<int> data) {
    _rxBuf.write(String.fromCharCodes(data));
    var text = _rxBuf.toString();
    if (text.contains('\r') || text.contains('\n') || text.contains('>')) {
      final parts = text.split(RegExp(r'[\r\n>]+'));
      _rxBuf.clear();
      if (parts.isNotEmpty && !text.endsWith('\n') && !text.endsWith('\r') && !text.endsWith('>')) {
        _rxBuf.write(parts.removeLast());
      }
      for (final p in parts) {
        final line = p.trim();
        if (line.isEmpty) continue;
        _ingestLine(line);
      }
    }
  }

  void _ingestLine(String line) {
    final cleaned = line.replaceAll(RegExp(r'[^0-9A-Fa-f\s]'), ' ').trim();
    final toks = cleaned.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (toks.length >= 3 && toks[0].length <= 3) {
      try {
        final id = int.parse(toks[0], radix: 16);
        final data = toks.skip(1).map((t) => int.parse(t, radix: 16)).toList();
        _pushFrame(CanFrame(id: id, data: data, source: 'RX', decoded: _lightDecode(id, data)));
        return;
      } catch (_) {}
    }
    _pushFrame(CanFrame(id: 0, data: [], source: 'RX', decoded: line));
  }

  void _pushFrame(CanFrame f) {
    _frames.insert(0, f);
    if (_frames.length > 500) _frames.removeLast();
    notifyListeners();
  }

  static String _lightDecode(int id, List<int> data) {
    if (data.length >= 4 && data[0] == 0x41 && data[1] == 0x0C) {
      return 'PID RPM → ${((data[2] * 256) + data[3]) ~/ 4}';
    }
    if (data.length >= 3 && data[0] == 0x41 && data[1] == 0x0D) {
      return 'PID Speed → ${data[2]} km/h';
    }
    final hex = data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
    return 'ID 0x${id.toRadixString(16).toUpperCase()}  [$hex]';
  }

  void clearFrames() {
    _frames.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

class CanFrame {
  final int id;
  final List<int> data;
  final String source;
  final String decoded;
  final bool isCommand;
  final DateTime time;
  CanFrame({required this.id, required this.data, required this.source, required this.decoded, this.isCommand = false, DateTime? time}) : time = time ?? DateTime.now();
}
