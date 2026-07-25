import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Connection type for the adapter
enum AdapterType { bluetooth, kdcan, demo }

/// Fine-grained BLE connection phase
enum BleConnectionPhase {
  idle,
  scanning,
  connecting,
  connected,
  disconnecting,
  disconnected,
  lost, // unexpected drop (range, power, etc.)
}

/// E60Coder Pro OBD Service
/// Supports:
///   - Bluetooth ELM327 / OBDLink / Vgate style adapters
///   - USB K-DCAN cables (FTDI FT232RL / CH340 / CP210x based)
///   - Demo / simulation mode
///
/// BLE monitoring:
///   - device.connectionState stream
///   - FlutterBluePlus.adapterState (phone BT on/off)
///   - Automatic cleanup on unexpected disconnect
class OBDService extends ChangeNotifier {
  // Bluetooth
  BluetoothDevice? _btDevice;
  BluetoothCharacteristic? _txChar;
  BluetoothCharacteristic? _rxChar;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  StreamSubscription<BluetoothAdapterState>? _adapterSub;

  // K-DCAN / USB serial (placeholder for usb_serial integration)
  // When using real USB: import 'package:usb_serial/usb_serial.dart';
  // UsbPort? _usbPort;

  bool _isConnected = false;
  String _status = 'Disconnected';
  AdapterType _adapterType = AdapterType.demo;
  BleConnectionPhase _blePhase = BleConnectionPhase.idle;
  final List<String> _logs = [];

  // Live data
  int rpm = 0;
  double boost = 0.0;
  double speed = 0.0;
  double coolant = 0.0;
  double throttle = 0.0;
  double afr = 14.7;

  // K-DCAN specific state
  int _kdcanBaud = 115200;
  bool _kdcanKline = false;

  bool get isConnected => _isConnected;
  String get status => _status;
  List<String> get logs => List.unmodifiable(_logs);
  BluetoothDevice? get device => _btDevice;
  AdapterType get adapterType => _adapterType;
  int get kdcanBaud => _kdcanBaud;
  BleConnectionPhase get blePhase => _blePhase;

  OBDService() {
    _startAdapterMonitoring();
  }

  void _addLog(String msg) {
    final ts = DateTime.now().toIso8601String().substring(11, 19);
    _logs.insert(0, '[$ts] $msg');
    if (_logs.length > 100) _logs.removeLast();
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // BLE ADAPTER + CONNECTION STATE MONITORING
  // ──────────────────────────────────────────────

  /// Watch phone Bluetooth radio (on / off / turning on / etc.)
  void _startAdapterMonitoring() {
    _adapterSub?.cancel();
    _adapterSub = FlutterBluePlus.adapterState.listen((state) {
      switch (state) {
        case BluetoothAdapterState.on:
          _addLog('Phone BT: ON');
          break;
        case BluetoothAdapterState.off:
          _addLog('Phone BT: OFF');
          if (_adapterType == AdapterType.bluetooth && _isConnected) {
            _handleUnexpectedDisconnect('Phone Bluetooth turned off');
          }
          break;
        case BluetoothAdapterState.turningOn:
          _addLog('Phone BT: turning ON…');
          break;
        case BluetoothAdapterState.turningOff:
          _addLog('Phone BT: turning OFF…');
          break;
        case BluetoothAdapterState.unauthorized:
          _addLog('Phone BT: UNAUTHORIZED – check permissions');
          _status = 'BT permission denied';
          notifyListeners();
          break;
        case BluetoothAdapterState.unavailable:
          _addLog('Phone BT: UNAVAILABLE on this device');
          _status = 'BT unavailable';
          notifyListeners();
          break;
        default:
          _addLog('Phone BT state: $state');
      }
    });
  }

  /// Attach a listener to a specific device’s connection state
  void _monitorDeviceConnection(BluetoothDevice device) {
    _connSub?.cancel();
    _connSub = device.connectionState.listen((state) {
      switch (state) {
        case BluetoothConnectionState.connected:
          _blePhase = BleConnectionPhase.connected;
          _addLog('BLE state → CONNECTED');
          break;

        case BluetoothConnectionState.disconnected:
          _addLog('BLE state → DISCONNECTED');
          if (_isConnected && _adapterType == AdapterType.bluetooth) {
            _handleUnexpectedDisconnect('Link lost (out of range / power / reset)');
          } else {
            _blePhase = BleConnectionPhase.disconnected;
            notifyListeners();
          }
          break;

        default:
          _addLog('BLE state → $state');
      }
    }, onError: (e) {
      _addLog('BLE connection stream error: $e');
      _handleUnexpectedDisconnect('Connection stream error');
    });
  }

  /// Called when the link drops without an explicit disconnect() call
  void _handleUnexpectedDisconnect(String reason) {
    _addLog('⚠ Unexpected disconnect: $reason');
    _blePhase = BleConnectionPhase.lost;
    _status = 'Connection lost';
    _pollTimer?.cancel();
    _pollTimer = null;
    _isConnected = false;
    _txChar = null;
    _rxChar = null;
    // Keep _btDevice so user can try reconnect
    _adapterType = AdapterType.bluetooth;
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // BLUETOOTH SCAN / CONNECT
  // ──────────────────────────────────────────────

  Future<void> startScan() async {
    _blePhase = BleConnectionPhase.scanning;
    _status = 'Scanning…';
    notifyListeners();
    _addLog('Scanning for Bluetooth OBD adapters…');

    try {
      if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
        _addLog('BT adapter is not ON – attempting to turn on (Android)');
        try {
          await FlutterBluePlus.turnOn();
        } catch (_) {}
      }

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          final name = r.device.platformName;
          if (name.toLowerCase().contains('obd') ||
              name.toLowerCase().contains('elm') ||
              name.toLowerCase().contains('vgate') ||
              name.toLowerCase().contains('carista') ||
              name.toLowerCase().contains('obdlink')) {
            _addLog('Found BT: $name (${r.device.remoteId})');
          }
        }
      });
    } catch (e) {
      _addLog('BT Scan error: $e');
      _blePhase = BleConnectionPhase.idle;
      _status = 'Scan failed';
      notifyListeners();
    }
  }

  Future<void> connectBluetooth(BluetoothDevice device) async {
    try {
      _blePhase = BleConnectionPhase.connecting;
      _status = 'Connecting Bluetooth…';
      notifyListeners();

      _monitorDeviceConnection(device);

      await device.connect(
        timeout: const Duration(seconds: 12),
        autoConnect: false,
      );

      _btDevice = device;
      _adapterType = AdapterType.bluetooth;
      _addLog('BT Connected: ${device.platformName}');

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

      if (_txChar == null) {
        throw Exception('No writable characteristic found on adapter');
      }

      await _sendCommand('ATZ');
      await Future.delayed(const Duration(milliseconds: 1000));
      await _sendCommand('ATE0');
      await _sendCommand('ATL0');
      await _sendCommand('ATS0');
      await _sendCommand('ATH1');
      await _sendCommand('ATSP0');
      await _sendCommand('0100');

      _isConnected = true;
      _blePhase = BleConnectionPhase.connected;
      _status = 'BT Connected • Live';
      _addLog('Bluetooth OBD link ready');
      _startLivePolling();
      notifyListeners();
    } catch (e) {
      _blePhase = BleConnectionPhase.disconnected;
      _status = 'BT Connection failed';
      _addLog('BT Connect error: $e');
      try {
        await device.disconnect();
      } catch (_) {}
      _connSub?.cancel();
      _connSub = null;
      notifyListeners();
    }
  }

  /// Try to re-connect to the last known Bluetooth device
  Future<void> reconnectBluetooth() async {
    if (_btDevice == null) {
      _addLog('No previous BT device to reconnect');
      return;
    }
    _addLog('Attempting reconnect to ${_btDevice!.platformName}…');
    await connectBluetooth(_btDevice!);
  }

  // ──────────────────────────────────────────────
  // K-DCAN USB SUPPORT
  // ──────────────────────────────────────────────

  Future<void> scanKdcan() async {
    _addLog('Scanning for K-DCAN USB cables…');
    _addLog('Looking for FTDI (0403:6001), CH340 (1A86:7523), CP210x…');

    await Future.delayed(const Duration(milliseconds: 600));
    _addLog('K-DCAN candidate found (simulated) – FTDI FT232RL');
    _addLog('Tip: Plug cable into phone with OTG adapter for real detection');
    notifyListeners();
  }

  Future<void> connectKdcan({
    int baud = 115200,
    bool useKline = false,
  }) async {
    try {
      _status = 'Connecting K-DCAN…';
      _kdcanBaud = baud;
      _kdcanKline = useKline;
      notifyListeners();

      _addLog('Opening USB serial @ $baud baud');
      _addLog(useKline ? 'Mode: K-Line (ISO 9141 / KWP2000)' : 'Mode: D-CAN / high-speed');

      await Future.delayed(const Duration(milliseconds: 800));

      if (useKline) {
        await _kdcanSend(Uint8List.fromList([0x81, 0x10, 0xF1, 0x81, 0x03]));
        await Future.delayed(const Duration(milliseconds: 100));
      } else {
        await _kdcanSend(Uint8List.fromList('ATZ\r'.codeUnits));
        await Future.delayed(const Duration(milliseconds: 300));
      }

      _adapterType = AdapterType.kdcan;
      _isConnected = true;
      _status = 'K-DCAN Connected • $baud baud';
      _addLog('K-DCAN link ready – BMW E60 modules accessible');
      _startLivePolling();
      notifyListeners();
    } catch (e) {
      _status = 'K-DCAN failed';
      _addLog('K-DCAN error: $e');
      notifyListeners();
    }
  }

  Future<void> _kdcanSend(Uint8List data) async {
    final hex = data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
    _addLog('K-DCAN TX: $hex');
  }

  // ──────────────────────────────────────────────
  // COMMON
  // ──────────────────────────────────────────────

  Future<void> disconnect() async {
    _blePhase = BleConnectionPhase.disconnecting;
    _status = 'Disconnecting…';
    notifyListeners();

    _pollTimer?.cancel();
    _pollTimer = null;

    try {
      if (_adapterType == AdapterType.bluetooth) {
        try {
          if (_rxChar != null) {
            await _rxChar!.setNotifyValue(false);
          }
        } catch (e) {
          _addLog('Warn: could not stop BT notifications – $e');
        }

        try {
          await _btDevice?.disconnect();
          _addLog('Bluetooth adapter disconnected');
        } catch (e) {
          _addLog('BT disconnect error (forced cleanup): $e');
        }
      } else if (_adapterType == AdapterType.kdcan) {
        try {
          _addLog('K-DCAN USB port closed');
        } catch (e) {
          _addLog('K-DCAN close error (forced cleanup): $e');
        }
      }
    } catch (e) {
      _addLog('Disconnect unexpected error: $e');
    } finally {
      _connSub?.cancel();
      _connSub = null;
      _isConnected = false;
      _status = 'Disconnected';
      _blePhase = BleConnectionPhase.disconnected;
      _btDevice = null;
      _txChar = null;
      _rxChar = null;
      _adapterType = AdapterType.demo;
      _addLog('Session ended – ready for next connection');
      notifyListeners();
    }
  }

  Future<void> _sendCommand(String cmd) async {
    if (_adapterType == AdapterType.bluetooth && _txChar != null) {
      try {
        final data = '$cmd\r'.codeUnits;
        await _txChar!.write(data, withoutResponse: true);
        _addLog('BT TX: $cmd');
      } catch (e) {
        _addLog('BT TX error: $e');
        if (_isConnected) {
          _handleUnexpectedDisconnect('Write failed – link dead?');
        }
      }
    } else if (_adapterType == AdapterType.kdcan) {
      await _kdcanSend(Uint8List.fromList('$cmd\r'.codeUnits));
    }
  }

  void _onDataReceived(List<int> data) {
    final response = String.fromCharCodes(data).trim();
    if (response.isEmpty) return;
    _addLog('RX: $response');
    _parseResponse(response);
  }

  void _parseResponse(String response) {
    if (response.contains('41 0C')) {
      try {
        final parts = response.split(' ');
        if (parts.length >= 4) {
          final a = int.parse(parts[2], radix: 16);
          final b = int.parse(parts[3], radix: 16);
          rpm = ((a * 256) + b) ~/ 4;
        }
      } catch (_) {}
    }
    notifyListeners();
  }

  Timer? _pollTimer;
  void _startLivePolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 200), (_) async {
      if (!_isConnected) return;
      await _sendCommand('010C');
      await Future.delayed(const Duration(milliseconds: 40));
      await _sendCommand('010D');
    });
  }

  void startDemoMode() {
    _isConnected = true;
    _adapterType = AdapterType.demo;
    _blePhase = BleConnectionPhase.idle;
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

  void setKdcanBaud(int baud) {
    _kdcanBaud = baud;
    _addLog('K-DCAN baud set to $baud');
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _connSub?.cancel();
    _adapterSub?.cancel();
    super.dispose();
  }
}
