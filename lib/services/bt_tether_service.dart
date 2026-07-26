import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Bluetooth internet / tethering helper.
/// BLE does not provide system-wide internet. Real tether uses Classic BT PAN
/// with a host that enables Bluetooth tethering and pairs with you.
class BtTetherService extends ChangeNotifier {
  bool _scanning = false;
  String _status = 'Idle';
  bool _adapterOn = false;
  final List<TetherCandidate> _candidates = [];

  bool get scanning => _scanning;
  String get status => _status;
  bool get adapterOn => _adapterOn;
  List<TetherCandidate> get candidates => List.unmodifiable(_candidates);

  Future<void> refresh() async {
    _scanning = true;
    _status = 'Checking Bluetooth…';
    _candidates.clear();
    notifyListeners();

    try {
      final state = await FlutterBluePlus.adapterState.first;
      _adapterOn = state == BluetoothAdapterState.on;

      if (!_adapterOn) {
        _status = 'Bluetooth is OFF – turn it on to use tether';
        _scanning = false;
        notifyListeners();
        return;
      }

      _status = 'Listing paired devices…';
      notifyListeners();

      try {
        final bonded = await FlutterBluePlus.bondedDevices;
        for (final d in bonded) {
          _candidates.add(TetherCandidate(
            name: d.platformName.isNotEmpty ? d.platformName : 'Paired device',
            id: d.remoteId.str,
            source: 'BONDED',
            canTetherHint:
                'May share internet only if this device has Bluetooth tethering enabled and you connect via system PAN settings.',
          ));
        }
      } catch (e) {
        _status = 'Could not list paired devices: $e';
      }

      _status = 'Scanning nearby (info only)…';
      notifyListeners();
      try {
        await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
        await Future.delayed(const Duration(seconds: 5));
        for (final r in FlutterBluePlus.lastScanResults) {
          final id = r.device.remoteId.str;
          if (_candidates.any((c) => c.id == id)) continue;
          final name = r.advertisementData.advName.isNotEmpty
              ? r.advertisementData.advName
              : (r.device.platformName.isNotEmpty ? r.device.platformName : 'Nearby device');
          _candidates.add(TetherCandidate(
            name: name,
            id: id,
            source: 'NEARBY',
            rssi: r.rssi,
            canTetherHint:
                'Nearby only. Internet sharing requires pairing + the other device enabling Bluetooth tethering. Not automatic over BLE.',
          ));
        }
        await FlutterBluePlus.stopScan();
      } catch (_) {}

      _status = _candidates.isEmpty
          ? 'No devices found. Pair a phone that can share BT tether.'
          : 'Found ${_candidates.length} device(s). Use system settings for real tether.';
    } catch (e) {
      _status = 'Error: $e';
    }

    _scanning = false;
    notifyListeners();
  }

  static const String howTo = '''
How Bluetooth internet actually works

1. On the phone that HAS internet (the host):
   Settings → Network / Hotspot → Bluetooth tethering → ON

2. On THIS device (the client):
   Settings → Bluetooth → pair with the host
   Then Settings → Network → select the Bluetooth network / PAN connection

3. Open any browser – traffic uses the host’s connection.

Limits:
• BLE apps cannot inject a system-wide internet route by themselves
• Random devices in range cannot be used without pairing + their consent
• Classic BT PAN is required, not GATT/BLE alone
''';
}

class TetherCandidate {
  final String name;
  final String id;
  final String source;
  final String canTetherHint;
  final int? rssi;

  TetherCandidate({
    required this.name,
    required this.id,
    required this.source,
    required this.canTetherHint,
    this.rssi,
  });
}
