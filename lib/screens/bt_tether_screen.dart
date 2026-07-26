import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/bt_tether_service.dart';

class BtTetherScreen extends StatefulWidget {
  const BtTetherScreen({super.key});

  @override
  State<BtTetherScreen> createState() => _BtTetherScreenState();
}

class _BtTetherScreenState extends State<BtTetherScreen> {
  late final BtTetherService _svc;

  @override
  void initState() {
    super.initState();
    _svc = BtTetherService();
    WidgetsBinding.instance.addPostFrameCallback((_) => _svc.refresh());
  }

  @override
  void dispose() {
    _svc.dispose();
    super.dispose();
  }

  Future<void> _openBluetoothSettings() async {
    try {
      const channel = MethodChannel('e60coder/settings');
      await channel.invokeMethod('openBluetoothSettings');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Open Settings → Bluetooth / Network → Bluetooth tethering manually')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _svc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('BT INTERNET / TETHER'),
          actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () => _svc.refresh())],
        ),
        body: Consumer<BtTetherService>(
          builder: (context, svc, _) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: svc.adapterOn ? Colors.greenAccent.withOpacity(0.5) : Colors.redAccent.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.bluetooth, color: svc.adapterOn ? Colors.greenAccent : Colors.redAccent),
                        const SizedBox(width: 8),
                        Text(svc.adapterOn ? 'Bluetooth ON' : 'Bluetooth OFF', style: TextStyle(color: svc.adapterOn ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 8),
                      Text(svc.status, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.4)),
                  ),
                  child: const Text(
                    'Internet over Bluetooth only works with a paired host that has Bluetooth tethering turned ON. Apps cannot route system traffic through random nearby devices over BLE.',
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _openBluetoothSettings,
                  icon: const Icon(Icons.settings),
                  label: const Text('OPEN SYSTEM BLUETOOTH / NETWORK SETTINGS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF).withOpacity(0.2),
                    foregroundColor: const Color(0xFF00E5FF),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: 20),
                Text('DEVICES', style: TextStyle(color: Colors.grey[600], fontSize: 11, letterSpacing: 1)),
                const SizedBox(height: 8),
                if (svc.scanning)
                  const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))))
                else if (svc.candidates.isEmpty)
                  Text('No devices listed yet.', style: TextStyle(color: Colors.grey[500]))
                else
                  ...svc.candidates.map((c) {
                    final isBonded = c.source == 'BONDED';
                    return Card(
                      color: const Color(0xFF121212),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(isBonded ? Icons.link : Icons.bluetooth_searching, color: isBonded ? Colors.greenAccent : Colors.amber),
                        title: Text(c.name),
                        subtitle: Text('${c.id}\n${c.canTetherHint}${c.rssi != null ? '\nRSSI ${c.rssi} dBm' : ''}', style: TextStyle(fontSize: 11, color: Colors.grey[500], height: 1.3)),
                        isThreeLine: true,
                        trailing: Text(c.source, style: TextStyle(fontSize: 10, color: isBonded ? Colors.greenAccent : Colors.amber)),
                      ),
                    );
                  }),
                const SizedBox(height: 20),
                Text('HOW TO', style: TextStyle(color: Colors.grey[600], fontSize: 11, letterSpacing: 1)),
                const SizedBox(height: 8),
                Text(BtTetherService.howTo, style: TextStyle(fontSize: 12, color: Colors.grey[400], height: 1.45)),
              ],
            );
          },
        ),
      ),
    );
  }
}
