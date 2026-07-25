import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/obd_service.dart';

class GaugesScreen extends StatelessWidget {
  const GaugesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final obd = context.watch<OBDService>();

    return Scaffold(
      appBar: AppBar(title: const Text('LIVE GAUGES')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [
          _GaugeCard(
            label: 'RPM',
            value: '${obd.rpm}',
            unit: 'rpm',
            color: const Color(0xFFFF6D00),
            max: 7000,
            current: obd.rpm.toDouble(),
          ),
          _GaugeCard(
            label: 'BOOST',
            value: obd.boost.toStringAsFixed(1),
            unit: 'psi',
            color: const Color(0xFF00E5FF),
            max: 25,
            current: obd.boost,
          ),
          _GaugeCard(
            label: 'SPEED',
            value: obd.speed.toStringAsFixed(0),
            unit: 'km/h',
            color: const Color(0xFF7C4DFF),
            max: 280,
            current: obd.speed,
          ),
          _GaugeCard(
            label: 'COOLANT',
            value: obd.coolant.toStringAsFixed(0),
            unit: '°C',
            color: const Color(0xFF00E676),
            max: 120,
            current: obd.coolant,
          ),
          _GaugeCard(
            label: 'THROTTLE',
            value: obd.throttle.toStringAsFixed(0),
            unit: '%',
            color: const Color(0xFFFFEA00),
            max: 100,
            current: obd.throttle,
          ),
          _GaugeCard(
            label: 'AFR',
            value: obd.afr.toStringAsFixed(1),
            unit: ':1',
            color: const Color(0xFFFF4081),
            max: 20,
            current: obd.afr,
          ),
        ],
      ),
    );
  }
}

class _GaugeCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final double max;
  final double current;

  const _GaugeCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.max,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (current / max).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 13, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(unit, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[900],
              color: color,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }
}
