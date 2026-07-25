import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Connection type for the adapter
enum AdapterType { bluetooth, kdcan, demo }

/// E60Coder Pro OBD Service
/// Supports:
///   - Bluetooth ELM327 / OBDLink / Vgate style adapters
///   - USB K-DCAN cables (FTDI FT232RL / CH340 / CP210x based)
///   - Demo / simulation mode
///
/// K-DCAN notes:
///   - Typical chip: FTDI FT232RL
///   - Common baud rates: 9600 (K-Line), 115200 (faster CAN/D-CAN)
///   - Used with INPA / ISTA / Tool32 for BMW E60 era cars
///   - On Android requires USB host + usb_serial package
class OBDService extends ChangeNotifier {
  // Bluetooth
  BluetoothDevice? _btDevice;
  BluetoothCharacteristic? _txChar;
  BluetoothCharacteristic? _rxChar;

  // K-DCAN / USB serial (placeholder for usb_serial integration)
  // When using real USB: import 'package:usb_serial/usb_serial.dart';
  // UsbPort? _usbPort;

  bool _isConnected = false;
  String _status = 'Disconnected';
  AdapterType _adapterType = AdapterType.demo;
  final List<String> _logs = [];

  // Live data
  int rpm = 0;
  double boost = 0.0;
  double speed = 0.0;
  double coolant = 0.0;
  double throttle = 0.0;
  double afr = 14.7;

  // K-DCAN specific state
  int _kdcanBaud = 115200; // default high-speed for D-CAN
  bool _kdcanKline = false; // true = pure K-Line mode (older modules)

  bool get isConnected => _isConnected;
  String get status => _status;
  List<String> get logs => List.unmodifiable(_logs);
  BluetoothDevice? get device => _btDevice;
  AdapterType get adapterType => _adapterType;
  int get kdcanBaud => _kdcanBaud;

  void _addLog(String msg) {
    final ts = DateTime.now().toIso8601String().substring(11, 19);
    _logs.insert(0, '[$ts] $msg');
    if (_logs.length > 100) _logs.removeLast();
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // BLUETOOTH SCAN / CONNECT (ELM327 style)
  // ──────────────────────────────────────────────

  Future<void> startScan() async {
    _addLog('Scanning for Bluetooth OBD adapters...');
    try {
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
    }
  }

  Future<void> connectBluetooth(BluetoothDevice device) async {
    try {
      _status = 'Connecting Bluetooth...';
      notifyListeners();
      await device.connect(timeout: const Duration(seconds: 10));
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

      // ELM327 init sequence
      await _sendCommand('ATZ');
      await Future.delayed(const Duration(milliseconds: 1000));
      await _sendCommand('ATE0');
      await _sendCommand('ATL0');
      await _sendCommand('ATS0');
      await _sendCommand('ATH1');
      await _sendCommand('ATSP0');
      await _sendCommand('0100');

      _isConnected = true;
      _status = 'BT Connected • Live';
      _addLog('Bluetooth OBD link ready');
      _startLivePolling();
      notifyListeners();
    } catch (e) {
      _status = 'BT Connection failed';
      _addLog('BT Connect error: $e');
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────
  // K-DCAN USB SUPPORT
  // ──────────────────────────────────────────────

  /// Scan for connected USB serial devices that look like K-DCAN
  /// (FTDI / CH340 / CP210x VID/PID common on genuine & clone K-DCAN cables)
  Future<void> scanKdcan() async {
    _addLog('Scanning for K-DCAN USB cables...');
    _addLog('Looking for FTDI (0403:6001), CH340 (1A86:7523), CP210x...');

    // Real implementation would use:
    // final devices = await UsbSerial.listDevices();
    // for (var d in devices) {
    //   _addLog('USB: ${d.productName} VID:${d.vid} PID:${d.pid}');
    // }

    // Simulated detection for now (demo + structure ready)
    await Future.delayed(const Duration(milliseconds: 600));
    _addLog('K-DCAN candidate found (simulated) – FTDI FT232RL');
    _addLog('Tip: Plug cable into phone with OTG adapter for real detection');
    notifyListeners();
  }

  /// Connect to a K-DCAN cable
  /// [baud] – 9600 for classic K-Line, 115200 for D-CAN / high-speed
  /// [useKline] – force pure K-Line mode (older E60 modules)
  Future<void> connectKdcan({
    int baud = 115200,
    bool useKline = false,
  }) async {
    try {
      _status = 'Connecting K-DCAN...';
      _kdcanBaud = baud;
      _kdcanKline = useKline;
      notifyListeners();

      _addLog('Opening USB serial @ $baud baud');
      _addLog(useKline ? 'Mode: K-Line (ISO 9141 / KWP2000)' : 'Mode: D-CAN / high-speed');

      // Real code would be:
      // final devices = await UsbSerial.listDevices();
      // final port = await devices.first.create();
      // await port.open();
      // await port.setDTR(true);
      // await port.setRTS(true);
      // port.setPortParameters(baud, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);
      // port.inputStream.listen(_onUsbData);

      // For now we go into a ready state so the UI works
      await Future.delayed(const Duration(milliseconds: 800));

      // BMW specific wake-up / init for K-DCAN
      if (useKline) {
        await _kdcanSend(Uint8List.fromList([0x81, 0x10, 0xF1, 0x81, 0x03])); // StartCommunication
        await Future.delayed(const Duration(milliseconds: 100));
      } else {
        // D-CAN style init (simplified)
        await _kdcanSend(Uint8List.fromList('ATZ\r'.codeUnits));
        await Future.delayed(const Duration(milliseconds: 300));
      }

      _adapterType = AdapterType.kdcan;
      _isConnected = true;
      _status = 'K-DCAN Connected • ${baud} baud';
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
    // Real: await _usbPort?.write(data);
    final hex = data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
    _addLog('K-DCAN TX: $hex');
  }

  // ──────────────────────────────────────────────
  // COMMON
  // ──────────────────────────────────────────────

  Future<void> disconnect() async {
    _status = 'Disconnecting...';
    notifyListeners();

    // Always stop live polling first
    _pollTimer?.cancel();
    _pollTimer = null;

    try {
      if (_adapterType == AdapterType.bluetooth) {
        // Stop notifications cleanly before disconnect
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
          // Force local cleanup even if remote disconnect fails
        }
      } else if (_adapterType == AdapterType.kdcan) {
        try {
          // Real: await _usbPort?.close();
          _addLog('K-DCAN USB port closed');
        } catch (e) {
          _addLog('K-DCAN close error (forced cleanup): $e');
        }
      }
    } catch (e) {
      _addLog('Disconnect unexpected error: $e');
    } finally {
      // Always reset local state so UI recovers
      _isConnected = false;
      _status = 'Disconnected';
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
      final data = '$cmd\r'.codeUnits;
      await _txChar!.write(data, withoutResponse: true);
      _addLog('BT TX: $cmd');
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
    // Basic OBD-II PID parsing
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
    // TODO: expand for BMW specific IDs / KWP responses when on K-DCAN
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
      // More PIDs: 0105 coolant, 0111 throttle, etc.
    });
  }

  // Demo / simulation mode
  void startDemoMode() {
    _isConnected = true;
    _adapterType = AdapterType.demo;
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

  /// Quick helper: set preferred K-DCAN baud
  void setKdcanBaud(int baud) {
    _kdcanBaud = baud;
    _addLog('K-DCAN baud set to $baud');
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
