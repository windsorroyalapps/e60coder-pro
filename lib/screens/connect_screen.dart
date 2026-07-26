import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/obd_service.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedBaud = 115200;
  bool _useKline = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OBDService>().startScan();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _statusColor(OBDService obd) {
    switch (obd.blePhase) {
      case BleConnectionPhase.connected:
        return Colors.greenAccent;
      case BleConnectionPhase.connecting:
      case BleConnectionPhase.scanning:
        return Colors.amber;
      case BleConnectionPhase.lost:
        return Colors.orange;
      case BleConnectionPhase.disconnecting:
        return Colors.deepOrange;
      default:
        return obd.isConnected ? Colors.greenAccent : Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final obd = context.watch<OBDService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('OBD CONNECT'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00E5FF),
          labelColor: const Color(0xFF00E5FF),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.bluetooth), text: 'BLUETOOTH'),
            Tab(icon: Icon(Icons.usb), text: 'K-DCAN'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_tabController.index == 0) {
                obd.startScan();
              } else {
                obd.scanKdcan();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.black26,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: _statusColor(obd)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(obd.status, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w600)),
                    ),
                    Text(
                      '${obd.adapterType.name.toUpperCase()} • ${obd.blePhase.name}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 10, letterSpacing: 0.5),
                    ),
                  ],
                ),
                if (obd.device != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Device: ${obd.device!.platformName}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ),
                if (obd.blePhase == BleConnectionPhase.lost)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => obd.reconnectBluetooth(),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('RECONNECT'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.orange, side: const BorderSide(color: Colors.orange)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildBluetoothTab(obd), _buildKdcanTab(obd)],
            ),
          ),
          if (obd.isConnected)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await obd.disconnect();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Disconnected successfully'), backgroundColor: Colors.green, duration: Duration(seconds: 2)));
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Disconnect error: $e'), backgroundColor: Colors.red[800], duration: const Duration(seconds: 3)));
                    }
                  }
                },
                icon: const Icon(Icons.link_off),
                label: const Text('DISCONNECT'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900], foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 48)),
              ),
            ),
          Container(
            height: 150,
            color: Colors.black,
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              itemCount: obd.logs.length,
              itemBuilder: (context, i) => Text(obd.logs[i], style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.greenAccent, height: 1.3)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBluetoothTab(OBDService obd) {
    final results = obd.scanResults.isNotEmpty ? obd.scanResults : <ScanResult>[];

    return StreamBuilder<List<ScanResult>>(
      stream: FlutterBluePlus.scanResults,
      builder: (context, snapshot) {
        final live = snapshot.data ?? [];
        final all = results.isNotEmpty ? results : live;

        final filtered = all.where((r) {
          final n = r.device.platformName.toLowerCase();
          final adv = r.advertisementData.advName.toLowerCase();
          return n.contains('obd') || n.contains('elm') || n.contains('vgate') || n.contains('carista') || n.contains('obdlink') || adv.contains('obd') || adv.contains('elm') || n.isNotEmpty || adv.isNotEmpty;
        }).toList();

        filtered.sort((a, b) => b.rssi.compareTo(a.rssi));

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bluetooth_searching, size: 48, color: Colors.grey[700]),
                const SizedBox(height: 12),
                Text('No Bluetooth adapters found', style: TextStyle(color: Colors.grey[500])),
                const SizedBox(height: 4),
                Text('ELM327 / OBDLink / Vgate / Carista', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 16),
                OutlinedButton.icon(onPressed: () => obd.startScan(), icon: const Icon(Icons.refresh, size: 18), label: const Text('SCAN AGAIN')),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, i) {
            final r = filtered[i];
            final adv = r.advertisementData;
            final displayName = adv.advName.isNotEmpty ? adv.advName : (r.device.platformName.isNotEmpty ? r.device.platformName : 'Unknown');

            Color rssiColor;
            if (r.rssi >= -60) {
              rssiColor = Colors.greenAccent;
            } else if (r.rssi >= -80) {
              rssiColor = Colors.amber;
            } else {
              rssiColor = Colors.redAccent;
            }

            return Card(
              color: const Color(0xFF121212),
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ExpansionTile(
                leading: Icon(Icons.bluetooth, color: rssiColor),
                title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${r.device.remoteId.str}  •  ${r.rssi} dBm', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                trailing: ElevatedButton(
                  onPressed: () => obd.connectBluetooth(r.device),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF).withOpacity(0.2), foregroundColor: const Color(0xFF00E5FF), padding: const EdgeInsets.symmetric(horizontal: 12)),
                  child: const Text('CONNECT'),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _advRow('Connectable', adv.connectable ? 'Yes' : 'No'),
                        if (adv.txPowerLevel != null) _advRow('TX Power', '${adv.txPowerLevel} dBm'),
                        if (adv.manufacturerData.isNotEmpty)
                          ...adv.manufacturerData.entries.map((e) {
                            final id = '0x${e.key.toRadixString(16).padLeft(4, '0')}';
                            final hex = e.value.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
                            return _advRow('Manufacturer $id', hex);
                          }),
                        if (adv.serviceUuids.isNotEmpty)
                          _advRow('Service UUIDs', adv.serviceUuids.map((u) => u.str128).join('\n')),
                        if (adv.serviceData.isNotEmpty)
                          ...adv.serviceData.entries.map((e) {
                            final hex = e.value.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
                            return _advRow('Svc ${e.key.str128}', hex);
                          }),
                        const SizedBox(height: 4),
                        Text(OBDService.formatAdvData(r), style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _advRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11))),
          Expanded(child: Text(value, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.cyanAccent))),
        ],
      ),
    );
  }

  Widget _buildKdcanTab(OBDService obd) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF121212), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.withOpacity(0.4))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [Icon(Icons.usb, color: Colors.orange, size: 20), SizedBox(width: 8), Text('K-DCAN USB Cable', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, letterSpacing: 0.5))]),
                const SizedBox(height: 8),
                Text('FTDI FT232RL / CH340 / CP210x based cables\nUse OTG adapter on Android. Supports INPA / ISTA style access.', style: TextStyle(color: Colors.grey[400], fontSize: 12, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('BAUD RATE', style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [9600, 38400, 115200, 500000].map((baud) {
              final selected = _selectedBaud == baud;
              return ChoiceChip(label: Text('$baud'), selected: selected, selectedColor: const Color(0xFF00E5FF).withOpacity(0.3), labelStyle: TextStyle(color: selected ? const Color(0xFF00E5FF) : Colors.grey, fontWeight: selected ? FontWeight.bold : FontWeight.normal), onSelected: (_) => setState(() => _selectedBaud = baud));
            }).toList(),
          ),
          const SizedBox(height: 16),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('K-Line Mode', style: TextStyle(fontSize: 14)), subtitle: Text(_useKline ? 'ISO 9141 / KWP2000 (older modules)' : 'D-CAN / high-speed (recommended)', style: TextStyle(color: Colors.grey[500], fontSize: 12)), value: _useKline, activeColor: const Color(0xFF00E5FF), onChanged: (v) => setState(() => _useKline = v)),
          const SizedBox(height: 20),
          ElevatedButton.icon(onPressed: () => obd.scanKdcan(), icon: const Icon(Icons.search), label: const Text('SCAN FOR K-DCAN'), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[900], foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 48))),
          const SizedBox(height: 10),
          ElevatedButton.icon(onPressed: () => obd.connectKdcan(baud: _selectedBaud, useKline: _useKline), icon: const Icon(Icons.link), label: Text('CONNECT  •  $_selectedBaud baud'), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.withOpacity(0.25), foregroundColor: Colors.orange, minimumSize: const Size(double.infinity, 52))),
          const SizedBox(height: 24),
          Text('TIPS', style: TextStyle(color: Colors.grey[600], fontSize: 11, letterSpacing: 1)),
          const SizedBox(height: 6),
          Text('• 9600 = classic K-Line (many E60 modules)\n• 115200 = D-CAN / faster modern modules\n• Use a quality FTDI-based cable for best results\n• OTG adapter required on most phones', style: TextStyle(color: Colors.grey[500], fontSize: 12, height: 1.5)),
        ],
      ),
    );
  }
}
