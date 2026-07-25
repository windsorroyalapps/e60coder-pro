import 'package:flutter/material.dart';

class TuneScreen extends StatelessWidget {
  const TuneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI TUNING ENGINE')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Select map profile. These are suggestion profiles only.\nAlways validate on a dyno / with proper tools.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          _TuneCard(
            title: 'SPORT MODE',
            color: const Color(0xFFFF6D00),
            items: const [
              'Boost target +4 psi',
              'Throttle response +35%',
              'Ignition advance +2°',
              'VANOS aggressive',
            ],
          ),
          const SizedBox(height: 12),
          _TuneCard(
            title: 'TRACK MODE',
            color: const Color(0xFFFF1744),
            items: const [
              'Launch Control @ 3800 RPM',
              'Aggressive VANOS timing',
              'Torque request max',
              'Cooling strategy high',
            ],
          ),
          const SizedBox(height: 12),
          _TuneCard(
            title: 'ECO MODE',
            color: const Color(0xFF00E676),
            items: const [
              'Fuel trim -7%',
              'Optimal timing for economy',
              'Soft throttle map',
              'Early upshift bias',
            ],
          ),
          const SizedBox(height: 12),
          _TuneCard(
            title: 'CUSTOM / STAGE 1+',
            color: const Color(0xFF7C4DFF),
            items: const [
              'User defined maps',
              'Load from file / GitHub',
              'DME flash support (advanced)',
              'Safety limits enforced',
            ],
          ),
        ],
      ),
    );
  }
}

class _TuneCard extends StatelessWidget {
  final String title;
  final Color color;
  final List<String> items;

  const _TuneCard({
    required this.title,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.5)),
        color: color.withOpacity(0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 10),
          ...items.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 16, color: color),
                    const SizedBox(width: 8),
                    Expanded(child: Text(e, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              )),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$title profile selected (simulation)')),
                );
              },
              child: Text('APPLY PROFILE', style: TextStyle(color: color)),
            ),
          ),
        ],
      ),
    );
  }
}
