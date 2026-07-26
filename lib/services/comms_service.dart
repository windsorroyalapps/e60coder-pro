import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'broadcast_decoder.dart';

class CommsEndpoint {
  final String channel;
  final String name;
  final String id;
  final String state;
  final Map<String, String> details;
  final int? rssi;
  final List<String> broadcastTypes;
  final String primaryBroadcast;
  final List<String> decodeNotes;

  CommsEndpoint({
    required this.channel,
    required this.name,
    required this.id,
    required this.state,
    this.details = const {},
    this.rssi,
    this.broadcastTypes = const [],
    this.primaryBroadcast = 'Unknown',
    this.decodeNotes = const [],
  });
}

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
    await Future.wait([_scanBluetooth(), _scanUsbPlaceholder(), _scanNetworkPlaceholder()]);
    _scanning = false;
    _status = 'Found ${_endpoints.length} endpoint(s)';
    notifyListeners();
  }

  Future<void> _scanBluetooth() async {
    try {
      final connected = FlutterBluePlus.connectedDevices;
      for (final d in connected) {
        final name = d.platformName.isNotEmpty ? d.platformName : 'Unknown BLE';
        final decoded = BroadcastDecoder.decode(name: name, id: d.remoteId.str);
        _endpoints.add(CommsEndpoint(
          channel: 'BLE', name: name, id: d.remoteId.str, state: 'CONNECTED',
          details: {'type': 'Bluetooth LE', 'bond': 'n/a', 'broadcast': decoded.primary},
          broadcastTypes: decoded.categories, primaryBroadcast: decoded.primary, decodeNotes: decoded.details,
        ));
      }
      try {
        final bonded = await FlutterBluePlus.bondedDevices;
        for (final d in bonded) {
          if (_endpoints.any((e) => e.id == d.remoteId.str)) continue;
          final name = d.platformName.isNotEmpty ? d.platformName : 'Paired device';
          final decoded = BroadcastDecoder.decode(name: name, id: d.remoteId.str);
          _endpoints.add(CommsEndpoint(
            channel: 'BLE', name: name, id: d.remoteId.str, state: 'BONDED',
            details: {'type': 'Bluetooth (paired)', 'note': 'Paired but not actively connected', 'broadcast': decoded.primary},
            broadcastTypes: decoded.categories, primaryBroadcast: decoded.primary, decodeNotes: decoded.details,
          ));
        }
      } catch (_) {}
      if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on) {
        await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
        await Future.delayed(const Duration(seconds: 4));
        for (final r in FlutterBluePlus.lastScanResults) {
          final id = r.device.remoteId.str;
          if (_endpoints.any((e) => e.id == id)) continue;
          final adv = r.advertisementData;
          final name = adv.advName.isNotEmpty ? adv.advName : (r.device.platformName.isNotEmpty ? r.device.platformName : 'Advertising device');
          final uuids = adv.serviceUuids.map((u) => u.str128).toList();
          final mfg = Map<int, List<int>>.from(adv.manufacturerData);
          final svcData = <String, List<int>>{};
          for (final e in adv.serviceData.entries) {
            svcData[e.key.str128] = e.value;
          }
          final decoded = BroadcastDecoder.decode(name: name, id: id, serviceUuids: uuids, manufacturerData: mfg, serviceData: svcData, connectable: adv.connectable);
          _endpoints.add(CommsEndpoint(
            channel: 'BLE', name: name, id: id, state: 'ADVERTISING', rssi: r.rssi,
            details: {'type': 'BLE advertisement', 'connectable': adv.connectable.toString(), 'rssi': '${r.rssi} dBm', 'broadcast': decoded.primary},
            broadcastTypes: decoded.categories, primaryBroadcast: decoded.primary, decodeNotes: decoded.details,
          ));
        }
        await FlutterBluePlus.stopScan();
      }
    } catch (e) {
      _endpoints.add(CommsEndpoint(channel: 'BLE', name: 'Bluetooth scan error', id: 'error', state: 'ERROR', details: {'error': e.toString()}));
    }
  }

  Future<void> _scanUsbPlaceholder() async {
    _endpoints.add(CommsEndpoint(
      channel: 'USB', name: 'USB Host (OTG)', id: 'usb-host', state: 'READY',
      details: {'note': 'Enable usb_serial for live VID/PID', 'hint': 'K-DCAN = FTDI 0403:6001 or CH340 1A86:7523', 'broadcast': 'Serial / diagnostic data (when K-DCAN attached)'},
      broadcastTypes: const ['Serial data stream', 'Vehicle diagnostics (K-Line / D-CAN)', 'Possible mass-storage if USB stick'],
      primaryBroadcast: 'Serial / diagnostic',
      decodeNotes: const ['USB serial → raw bytes (ELM AT, KWP2000, UDS)', 'If storage device → file transfer', 'If audio DAC → digital audio'],
    ));
  }

  Future<void> _scanNetworkPlaceholder() async {
    _endpoints.add(CommsEndpoint(
      channel: 'NETWORK', name: 'IP stack', id: 'net-0', state: 'AVAILABLE',
      details: {'note': 'Add connectivity_plus for live Wi-Fi/mobile state', 'broadcast': 'IP packets (TCP/UDP)'},
      broadcastTypes: const ['TCP / UDP traffic', 'Possible media streaming (HTTP, RTSP)', 'Possible file transfer (FTP, HTTP)', 'Possible telemetry / GPS over IP'],
      primaryBroadcast: 'IP networking',
      decodeNotes: const ['Depends on active apps & sockets', 'Use platform tools for deep packet inspection'],
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
