import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/comms_service.dart';

class CommsScreen extends StatefulWidget {
  const CommsScreen({super.key});
  @override
  State<CommsScreen> createState() => _CommsScreenState();
}

class _CommsScreenState extends State<CommsScreen> {
  late final CommsService _comms;

  @override
  void initState() {
    super.initState();
    _comms = CommsService();
    WidgetsBinding.instance.addPostFrameCallback((_) => _comms.refreshAll());
  }

  @override
  void dispose() {
    _comms.dispose();
    super.dispose();
  }

  Color _channelColor(String channel) {
    switch (channel) {
      case 'BLE': return const Color(0xFF00E5FF);
      case 'USB': return Colors.orange;
      case 'NETWORK': return const Color(0xFF7C4DFF);
      case 'SERIAL': return const Color(0xFF00E676);
      default: return Colors.grey;
    }
  }

  IconData _channelIcon(String channel) {
    switch (channel) {
      case 'BLE': return Icons.bluetooth;
      case 'USB': return Icons.usb;
      case 'NETWORK': return Icons.wifi;
      case 'SERIAL': return Icons.cable;
      default: return Icons.device_hub;
    }
  }

  Color _stateColor(String state) {
    switch (state.toUpperCase()) {
      case 'CONNECTED': return Colors.greenAccent;
      case 'BONDED': return Colors.lightBlueAccent;
      case 'ADVERTISING': return Colors.amber;
      case 'ATTACHED':
      case 'READY':
      case 'AVAILABLE': return Colors.grey;
      case 'ERROR': return Colors.redAccent;
      default: return Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _comms,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('DEVICE CONNECTIONS'),
          actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () => _comms.refreshAll())],
        ),
        body: Consumer<CommsService>(
          builder: (context, comms, _) {
            if (comms.scanning && comms.endpoints.isEmpty) {
              return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(color: Color(0xFF00E5FF)), SizedBox(height: 16), Text('Scanning communication channels…')]));
            }
            final groups = comms.grouped;
            if (groups.isEmpty) {
              return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.device_hub, size: 48, color: Colors.grey[700]), const SizedBox(height: 12), const Text('No endpoints found'), const SizedBox(height: 16), OutlinedButton.icon(onPressed: () => comms.refreshAll(), icon: const Icon(Icons.refresh), label: const Text('SCAN AGAIN'))]));
            }
            return Column(children: [
              Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), color: Colors.black26, child: Text(comms.status, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w600))),
              Expanded(child: ListView(padding: const EdgeInsets.only(bottom: 24), children: groups.entries.map((entry) {
                final channel = entry.key;
                final list = entry.value;
                final color = _channelColor(channel);
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: Row(children: [
                    Icon(_channelIcon(channel), color: color, size: 20),
                    const SizedBox(width: 8),
                    Text(channel, style: TextStyle(color: color, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(width: 8),
                    Text('(${list.length})', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ])),
                  ...list.map((e) => _endpointCard(e, color)),
                ]);
              }).toList())),
            ]);
          },
        ),
      ),
    );
  }

  Widget _endpointCard(CommsEndpoint e, Color channelColor) {
    return Card(
      color: const Color(0xFF121212),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ExpansionTile(
        leading: Icon(_channelIcon(e.channel), color: channelColor),
        title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${e.id}${e.rssi != null ? '  •  ${e.rssi} dBm' : ''}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          if (e.primaryBroadcast.isNotEmpty && e.primaryBroadcast != 'Unknown')
            Padding(padding: const EdgeInsets.only(top: 2), child: Text(e.primaryBroadcast, style: TextStyle(fontSize: 11, color: channelColor.withOpacity(0.9)))),
        ]),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: _stateColor(e.state).withOpacity(0.6))),
          child: Text(e.state, style: TextStyle(fontSize: 10, color: _stateColor(e.state), letterSpacing: 0.5)),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (e.broadcastTypes.isNotEmpty) ...[
                Text('BROADCAST / DATA TYPE', style: TextStyle(color: Colors.grey[600], fontSize: 10, letterSpacing: 1)),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 6, children: e.broadcastTypes.map((t) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: channelColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: channelColor.withOpacity(0.4))),
                  child: Text(t, style: TextStyle(fontSize: 11, color: channelColor)),
                )).toList()),
                const SizedBox(height: 12),
              ],
              if (e.decodeNotes.isNotEmpty) ...[
                Text('DECODE NOTES', style: TextStyle(color: Colors.grey[600], fontSize: 10, letterSpacing: 1)),
                const SizedBox(height: 4),
                ...e.decodeNotes.map((n) => Padding(padding: const EdgeInsets.only(bottom: 3), child: Text('• $n', style: TextStyle(fontSize: 11, color: Colors.grey[400], height: 1.3)))),
                const SizedBox(height: 8),
              ],
              if (e.details.isNotEmpty) ...[
                Text('DETAILS', style: TextStyle(color: Colors.grey[600], fontSize: 10, letterSpacing: 1)),
                const SizedBox(height: 4),
                ...e.details.entries.map((kv) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(width: 100, child: Text(kv.key, style: TextStyle(color: Colors.grey[500], fontSize: 11))),
                    Expanded(child: Text(kv.value, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.cyanAccent))),
                  ]),
                )),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}
