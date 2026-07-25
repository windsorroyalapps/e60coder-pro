import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/obd_service.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OBDService>().startScan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final obd = context.watch<OBDService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('OBD CONNECT'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => obd.startScan(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.black26,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: ${obd.status}', style: const TextStyle(color: Colors.cyanAccent)),
                const SizedBox(height: 4),
                Text(
                  obd.isConnected
                      ? 'Device: ${obd.device?.platformName ?? "Unknown"}'
                      : 'Scan for ELM327 / OBDLink / Vgate',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ScanResult>>(
              stream: FlutterBluePlus.scanResults,
              builder: (context, snapshot) {
                final results = snapshot.data ?? [];
                final filtered = results.where((r) {
                  final n = r.device.platformName.toLowerCase();
                  return n.contains('obd') ||
                      n.contains('elm') ||
                      n.contains('vgate') ||
                      n.contains('carista') ||
                      n.contains('obdlink') ||
                      n.isNotEmpty;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No adapters found yet...\nMake sure Bluetooth is on', textAlign: TextAlign.center),
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final r = filtered[i];
                    return ListTile(
                      leading: const Icon(Icons.bluetooth, color: Colors.cyan),
                      title: Text(r.device.platformName.isEmpty ? 'Unknown Device' : r.device.platformName),
                      subtitle: Text(r.device.remoteId.str),
                      trailing: ElevatedButton(
                        onPressed: () => obd.connect(r.device),
                        child: const Text('CONNECT'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (obd.isConnected)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () => obd.disconnect(),
                icon: const Icon(Icons.link_off),
                label: const Text('DISCONNECT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[900],
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
          // Logs
          Container(
            height: 160,
            color: Colors.black,
            child: ListView.builder(
              reverse: true,
              itemCount: obd.logs.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: Text(
                  obd.logs[i],
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.greenAccent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
