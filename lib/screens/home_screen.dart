import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/obd_service.dart';
import 'connect_screen.dart';
import 'gauges_screen.dart';
import 'tune_screen.dart';
import 'code_screen.dart';
import 'comms_screen.dart';
import 'device_control_screen.dart';
import 'bt_tether_screen.dart';
import 'recorder_screen.dart';
import 'can_bus_screen.dart';
import 'aftermarket_hu_screen.dart';

class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final Widget Function() builder;
  const _MenuItem({required this.icon, required this.label, required this.color, required this.builder});
}

final List<_MenuItem> kHomeMenu = [
  _MenuItem(icon: Icons.bluetooth_searching, label: 'CONNECT / OBD', color: const Color(0xFF00E5FF), builder: () => const ConnectScreen()),
  _MenuItem(icon: Icons.speed, label: 'LIVE GAUGES', color: const Color(0xFFFF6D00), builder: () => const GaugesScreen()),
  _MenuItem(icon: Icons.tune, label: 'AI TUNING', color: const Color(0xFF7C4DFF), builder: () => const TuneScreen()),
  _MenuItem(icon: Icons.code, label: 'CODING / NCS', color: const Color(0xFF00E676), builder: () => const CodeScreen()),
  _MenuItem(icon: Icons.device_hub, label: 'DEVICE CONNECTIONS', color: const Color(0xFFFFEA00), builder: () => const CommsScreen()),
  _MenuItem(icon: Icons.headphones, label: 'DEVICE CONTROL', color: const Color(0xFFE040FB), builder: () => const DeviceControlScreen()),
  _MenuItem(icon: Icons.wifi_tethering, label: 'BT INTERNET / TETHER', color: const Color(0xFF18FFFF), builder: () => const BtTetherScreen()),
  _MenuItem(icon: Icons.radio_button_checked, label: 'CHANNEL RECORDER', color: const Color(0xFFFF5252), builder: () => const RecorderScreen()),
  _MenuItem(icon: Icons.cable, label: 'CAN / OBD GATEWAY', color: const Color(0xFF69F0AE), builder: () => const CanBusScreen()),
  _MenuItem(icon: Icons.speaker_group, label: 'AFTERMARKET HU / CAN', color: const Color(0xFFB2FF59), builder: () => const AftermarketHuScreen()),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final obd = context.watch<OBDService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('E60Coder Pro', style: TextStyle(letterSpacing: 2)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: obd.isConnected ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: obd.isConnected ? Colors.green : Colors.red),
                ),
                child: Text(obd.status, style: TextStyle(fontSize: 11, color: obd.isConnected ? Colors.greenAccent : Colors.redAccent)),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('BMW E60 / N54-N55', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: const Color(0xFF00E5FF), fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('Advanced OBD • Coding • AI Tuning', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: kHomeMenu.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  if (i == kHomeMenu.length) {
                    return Column(children: [
                      const SizedBox(height: 8),
                      if (!obd.isConnected)
                        ElevatedButton.icon(
                          onPressed: () => obd.startDemoMode(),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('START DEMO MODE'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[900], foregroundColor: Colors.white70, minimumSize: const Size(double.infinity, 48)),
                        ),
                      const SizedBox(height: 12),
                      Text('v4.0.0 • Legal OBD use only', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]), textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                    ]);
                  }
                  final item = kHomeMenu[i];
                  return _MenuButton(
                    icon: item.icon,
                    label: item.label,
                    color: item.color,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => item.builder())),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _MenuButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.5), width: 1.5),
            gradient: LinearGradient(colors: [color.withOpacity(0.15), Colors.transparent], begin: Alignment.centerLeft, end: Alignment.centerRight),
          ),
          child: Row(children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.8))),
            Icon(Icons.chevron_right, color: color.withOpacity(0.7)),
          ]),
        ),
      ),
    );
  }
}
