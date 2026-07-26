import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// A single discovered communication endpoint
class CommsEndpoint {
  final String channel; // BLE, USB, NETWORK, SERIAL, OTHER
  final String name;
  final String id;
  final String state; // connected, bonded, available, etc.
  final Map<String, String> details;
  final int? rssi;

  CommsEndpoint({
    required this.channel,
    required this.name,
    required this.id,
    required this.state,
    this.details = const {},
    this.rssi,
  });
}

/// Enumerates what is connected on the phone's communication channels.
class CommsService extends ChangeNotifier {
  final List<CommsEndpoint> _endpoints = [];
  bool _scanning = false;
  String _status = 'Idle';

  List<CommsEndpoint> get endpoints => List.unmodifiable(_endpoints);
  bool get scanning => _scanning;
  String get status => _status;

  Future<void> refreshAll() async {
    _scanning = true;
    _status = 'Scanning channels…';
    _endpoints.clear();
    notifyListeners();

    await Future.wait([
      _scanBluetooth(),
      _scanUsbPlaceholder(),
      _scanNetworkPlaceholder(),
    ]);

    _scanning = false;
    _status = 'Found ${_endpoints.length} endpoint(s)';
    notifyListeners();
  }

  Future<void> _scanBluetooth() async {
    try {
      final connected = FlutterBluePlus.connectedDevices;
      for (final d in connected) {
        _endpoints.add(CommsEndpoint(
          channel: 'BLE',
          name: d.platformName.isNotEmpty ? d.platformName : 'Unknown BLE',
          id: d.remoteId.str,
          state: 'CONNECTED',
          details: {'type': 'Bluetooth LE', 'bond': 'n/a'},
        ));
      }

      try {
        final bonded = await FlutterBluePlus.bondedDevices;
        for (final d in bonded) {
          final already = _endpoints.any((e) => e.id == d.remoteId.str);
          if (!already) {
            _endpoints.add(CommsEndpoint(
              channel: 'BLE',
              name: d.platformName.isNotEmpty ? d.platformName : 'Paired device',
              id: d.remoteId.str,
              state: 'BONDED',
              details: {
                'type': 'Bluetooth (paired)',
                'note': 'Paired but not actively connected',
              },
            ));
          }
        }
      } catch (_) {}

      if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on) {
        await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
        await Future.delayed(const Duration(seconds: 4));
        final results = FlutterBluePlus.lastScanResults;
        for (final r in results) {
          final id = r.device.remoteId.str;
          final already = _endpoints.any((e) => e.id == id);
          if (!already) {
            final name = r.advertisementData.advName.isNotEmpty
                ? r.advertisementData.advName
                : (r.device.platformName.isNotEmpty ? r.device.platformName : 'Advertising device');
            _endpoints.add(CommsEndpoint(
              channel: 'BLE',
              name: name,
              id: id,
              state: 'ADVERTISING',
              rssi: r.rssi,
              details: {
                'type': 'BLE advertisement',
                'connectable': r.advertisementData.connectable.toString(),
                'rssi': '${r.rssi} dBm',
              },
            ));
          }
        }
        await FlutterBluePlus.stopScan();
      }
    } catch (e) {
      _endpoints.add(CommsEndpoint(
        channel: 'BLE',
        name: 'Bluetooth scan error',
        id: 'error',
        state: 'ERROR',
        details: {'error': e.toString()},
      ));
    }
  }

  Future<void> _scanUsbPlaceholder() async {
    _endpoints.add(CommsEndpoint(
      channel: 'USB',
      name: 'USB Host (OTG)',
      id: 'usb-host',
      state: 'READY',
      details: {
        'note': 'Enable usb_serial package for live VID/PID listing',
        'hint': 'K-DCAN usually appears as FTDI 0403:6001 or CH340 1A86:7523',
      },
    ));
  }

  Future<void> _scanNetworkPlaceholder() async {
    _endpoints.add(CommsEndpoint(
      channel: 'NETWORK',
      name: 'IP stack',
      id: 'net-0',
      state: 'AVAILABLE',
      details: {
        'note': 'Add connectivity_plus for live Wi-Fi / mobile / ethernet state',
      },
    ));
  }

  Map<String, List<CommsEndpoint>> get grouped {
    final map = <String, List<CommsEndpoint>>{};
    for (final e in _endpoints) {
      map.putIfAbsent(e.channel, () => []).add(e);
    }
    return map;
  }
}
