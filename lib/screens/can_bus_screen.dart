import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/can_bus_service.dart';

class CanBusScreen extends StatefulWidget {
  const CanBusScreen({super.key});
  @override
  State<CanBusScreen> createState() => _CanBusScreenState();
}

class _CanBusScreenState extends State<CanBusScreen> {
  late final CanBusService _can;
  final _hostCtrl = TextEditingController(text: '192.168.0.10');
  final _portCtrl = TextEditingController(text: '35000');
  final _cmdCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _can = CanBusService();
  }

  @override
  void dispose() {
    _can.dispose();
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _cmdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _can,
      child: Scaffold(
        appBar: AppBar(title: const Text('CAN / OBD GATEWAY'), actions: [IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _can.clearFrames())]),
        body: Consumer<CanBusService>(builder: (context, can, _) {
          return Column(children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.black26,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(can.status, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w600)),
                Text('Transport: ${can.transport}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.withOpacity(0.4))),
                  child: const Text('Requires an OBD/CAN adapter on a vehicle you own or are authorized to work on. Phones do not wirelessly sniff a car CAN without a plugged-in gateway.', style: TextStyle(fontSize: 11, height: 1.35)),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextField(controller: _hostCtrl, decoration: const InputDecoration(labelText: 'Wi-Fi ELM host', isDense: true, border: OutlineInputBorder()))),
                  const SizedBox(width: 8),
                  SizedBox(width: 90, child: TextField(controller: _portCtrl, decoration: const InputDecoration(labelText: 'Port', isDense: true, border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  ElevatedButton(onPressed: can.isConnected ? null : () => can.connectWifi(host: _hostCtrl.text.trim(), port: int.tryParse(_portCtrl.text) ?? 35000), child: const Text('Wi-Fi CONNECT')),
                  ElevatedButton(onPressed: can.isConnected ? null : () => can.attachBluetoothBridge(), child: const Text('BT OBD BRIDGE')),
                  ElevatedButton(onPressed: can.isConnected ? null : () => can.startDemo(), child: const Text('DEMO')),
                  if (can.isConnected) ElevatedButton(onPressed: () => can.disconnect(), style: ElevatedButton.styleFrom(foregroundColor: Colors.redAccent), child: const Text('DISCONNECT')),
                ]),
                if (can.isConnected) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextField(controller: _cmdCtrl, decoration: const InputDecoration(labelText: 'AT / OBD command', hintText: '010C or ATMA', isDense: true, border: OutlineInputBorder()))),
                    const SizedBox(width: 8),
                    ElevatedButton(onPressed: () { final c = _cmdCtrl.text.trim(); if (c.isNotEmpty) can.sendCommand(c); }, child: const Text('SEND')),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    OutlinedButton(onPressed: () => can.startMonitorAll(), child: const Text('ATMA MONITOR')),
                    const SizedBox(width: 8),
                    OutlinedButton(onPressed: () => can.stopMonitor(), child: const Text('STOP MON')),
                  ]),
                ],
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: can.frames.isEmpty
                  ? Center(child: Text('No frames yet', style: TextStyle(color: Colors.grey[600])))
                  : ListView.builder(
                      itemCount: can.frames.length,
                      itemBuilder: (context, i) {
                        final f = can.frames[i];
                        final t = f.time.toIso8601String().substring(11, 19);
                        final color = f.source == 'TX' ? Colors.orange : f.source == 'demo' ? Colors.purpleAccent : Colors.greenAccent;
                        return ListTile(
                          dense: true,
                          leading: Text(f.source, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                          title: Text(f.decoded, style: const TextStyle(fontSize: 13)),
                          subtitle: Text(f.id != 0 ? '[$t] ID 0x${f.id.toRadixString(16).toUpperCase()}' : '[$t]', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                        );
                      },
                    ),
            ),
          ]);
        }),
      ),
    );
  }
}
