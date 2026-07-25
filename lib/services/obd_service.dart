import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class OBDService extends ChangeNotifier {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _txChar;
  BluetoothCharacteristic? _rxChar;
  bool _isConnected = false;
  String _status = 'Disconnected';
  final List<String> _logs = [];

  // Live data
  int rpm = 0;
  double boost = 0.0;
  double speed = 0.0;
  double coolant = 0.0;
  double throttle = 0.0;
  double afr = 14.7;

  bool get isConnected => _isConnected;
  String get status => _status;
  List<String> get logs => List.unmodifiable(_logs);
  BluetoothDevice? get device => _device;

  void _addLog(String msg) {
    final ts = DateTime.now().toIso8601String().substring(11, 19);
    _logs.insert(0, '[$ts] $msg');
    if (_logs.length > 100) _logs.removeLast();
    notifyListeners();
  }

  Future<void> startScan() async {
    _addLog('Scanning for OBD adapters...');
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          final name = r.device.platformName;
          if (name.toLowerCase().contains('obd') ||
              name.toLowerCase().contains('elm') ||
              name.toLowerCase().contains('vgate') ||
              name.toLowerCase().contains('carista')) {
            _addLog('Found: $name (${r.device.remoteId})');
          }
        }
      });
    } catch (e) {
      _addLog('Scan error: $e');
    }
  }

  Future<void> connect(BluetoothDevice device) async {
    try {
      _status = 'Connecting...';
      notifyListeners();
      await device.connect(timeout: const Duration(seconds: 10));
      _device = device;
      _addLog('Connected to ${device.platformName}');

      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        for (var char in service.characteristics) {
          if (char.properties.write || char.properties.writeWithoutResponse) {
            _txChar = char;
          }
          if (char.properties.notify || char.properties.indicate) {
            _rxChar = char;
            await char.setNotifyValue(true);
            char.lastValueStream.listen(_onDataReceived);
          }
        }
      }

      // ELM327 init sequence
      await _sendCommand('ATZ');
      await Future.delayed(const Duration(milliseconds: 1000));
      await _sendCommand('ATE0'); // Echo off
      await _sendCommand('ATL0'); // Linefeeds off
      await _sendCommand('ATS0'); // Spaces off
      await _sendCommand('ATH1'); // Headers on
      await _sendCommand('ATSP0'); // Auto protocol
      await _sendCommand('0100'); // Supported PIDs

      _isConnected = true;
      _status = 'Connected • Live';
      _addLog('OBD link ready');
      _startLivePolling();
      notifyListeners();
    } catch (e) {
      _status = 'Connection failed';
      _addLog('Connect error: $e');
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    await _device?.disconnect();
    _isConnected = false;
    _status = 'Disconnected';
    _device = null;
    _addLog('Disconnected');
    notifyListeners();
  }

  Future<void> _sendCommand(String cmd) async {
    if (_txChar == null) return;
    final data = '$cmd\r'.codeUnits;
    await _txChar!.write(data, withoutResponse: true);
    _addLog('TX: $cmd');
  }

  void _onDataReceived(List<int> data) {
    final response = String.fromCharCodes(data).trim();
    if (response.isEmpty) return;
    _addLog('RX: $response');
    _parseResponse(response);
  }

  void _parseResponse(String response) {
    // Basic PID parsing (expand for full BMW specific)
    if (response.contains('41 0C')) {
      // RPM
      try {
        final parts = response.split(' ');
        if (parts.length >= 4) {
          final a = int.parse(parts[2], radix: 16);
          final b = int.parse(parts[3], radix: 16);
          rpm = ((a * 256) + b) ~/ 4;
        }
      } catch (_) {}
    }
    // Add more PID parsers as needed
    notifyListeners();
  }

  Timer? _pollTimer;
  void _startLivePolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 200), (_) async {
      if (!_isConnected) return;
      await _sendCommand('010C'); // RPM
      await Future.delayed(const Duration(milliseconds: 40));
      await _sendCommand('010D'); // Speed
      // Add more PIDs: 0105 coolant, 0111 throttle, etc.
    });
  }

  // Demo / simulation mode when no hardware
  void startDemoMode() {
    _isConnected = true;
    _status = 'DEMO MODE • Simulated Live Data';
    _addLog('Demo mode activated');
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!_isConnected) {
        timer.cancel();
        return;
      }
      rpm = 2200 + (DateTime.now().millisecond % 2800);
      boost = 8.0 + (DateTime.now().millisecond % 120) / 10;
      speed = 40 + (DateTime.now().second % 80).toDouble();
      coolant = 85 + (DateTime.now().second % 15).toDouble();
      throttle = 15 + (DateTime.now().millisecond % 70).toDouble();
      afr = 13.8 + (DateTime.now().millisecond % 20) / 10;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
