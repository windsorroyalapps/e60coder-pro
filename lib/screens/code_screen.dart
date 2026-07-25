import 'package:flutter/material.dart';

class CodeScreen extends StatelessWidget {
  const CodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final codes = [
      {'name': 'Disable Seatbelt Chime', 'status': 'Ready'},
      {'name': 'Enable DVD in Motion', 'status': 'Ready'},
      {'name': 'Angel Eyes as DRL', 'status': 'Ready'},
      {'name': 'Mirror Fold on Lock', 'status': 'Ready'},
      {'name': 'Digital Speedo in Cluster', 'status': 'Ready'},
      {'name': 'Disable Auto Start-Stop', 'status': 'Ready'},
      {'name': 'Launch Control Enable', 'status': 'Advanced'},
      {'name': 'Sport Displays Always On', 'status': 'Ready'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('NCS / CODING')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: codes.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
        itemBuilder: (context, i) {
          final item = codes[i];
          return ListTile(
            title: Text(item['name']!),
            subtitle: Text(item['status']!, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            trailing: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${item['name']} → coding sequence started (sim)')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676).withOpacity(0.2),
                foregroundColor: const Color(0xFF00E676),
              ),
              child: const Text('CODE'),
            ),
          );
        },
      ),
    );
  }
}
