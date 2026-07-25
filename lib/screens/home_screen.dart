import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/obd_service.dart';
import 'connect_screen.dart';
import 'gauges_screen.dart';
import 'tune_screen.dart';
import 'code_screen.dart';

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
                  border: Border.all(
                    color: obd.isConnected ? Colors.green : Colors.red,
                  ),
                ),
                child: Text(
                  obd.status,
                  style: TextStyle(
                    fontSize: 11,
                    color: obd.isConnected ? Colors.greenAccent : Colors.redAccent,
                  ),
                ),
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
            const SizedBox(height: 12),
            Text(
              'BMW E60 / N54-N55',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF00E5FF),
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Advanced OBD • Coding • AI Tuning',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _MenuButton(
              icon: Icons.bluetooth_searching,
              label: 'CONNECT / OBD',
              color: const Color(0xFF00E5FF),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConnectScreen()),
              ),
            ),
            const SizedBox(height: 14),
            _MenuButton(
              icon: Icons.speed,
              label: 'LIVE GAUGES',
              color: const Color(0xFFFF6D00),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GaugesScreen()),
              ),
            ),
            const SizedBox(height: 14),
            _MenuButton(
              icon: Icons.tune,
              label: 'AI TUNING',
              color: const Color(0xFF7C4DFF),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TuneScreen()),
              ),
            ),
            const SizedBox(height: 14),
            _MenuButton(
              icon: Icons.code,
              label: 'CODING / NCS',
              color: const Color(0xFF00E676),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CodeScreen()),
              ),
            ),
            const Spacer(),
            if (!obd.isConnected)
              ElevatedButton.icon(
                onPressed: () => obd.startDemoMode(),
                icon: const Icon(Icons.play_arrow),
                label: const Text('START DEMO MODE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[900],
                  foregroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              'v4.0.0 • Legal OBD use only',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
              textAlign: TextAlign.center,
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

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.5), width: 1.5),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.15), Colors.transparent],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right, color: color.withOpacity(0.7)),
            ],
          ),
        ),
      ),
    );
  }
}
