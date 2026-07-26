import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/media_control_service.dart';
import '../services/comms_service.dart';

class DeviceControlScreen extends StatefulWidget {
  final CommsEndpoint? endpoint;
  const DeviceControlScreen({super.key, this.endpoint});

  @override
  State<DeviceControlScreen> createState() => _DeviceControlScreenState();
}

class _DeviceControlScreenState extends State<DeviceControlScreen> {
  late final MediaControlService _media;

  @override
  void initState() {
    super.initState();
    _media = MediaControlService();
    final e = widget.endpoint;
    if (e != null) {
      _media.attach(name: e.name, id: e.id, type: e.primaryBroadcast);
    } else {
      _media.attach(name: 'Demo Audio Device', id: 'demo', type: 'Audio / media');
    }
  }

  @override
  void dispose() {
    _media.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _media,
      child: Scaffold(
        appBar: AppBar(title: const Text('DEVICE CONTROL')),
        body: Consumer<MediaControlService>(
          builder: (context, media, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.4)),
                  ),
                  child: Column(children: [
                    const Icon(Icons.speaker, size: 40, color: Color(0xFF00E5FF)),
                    const SizedBox(height: 8),
                    Text(media.deviceName ?? 'No device', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Text(media.primaryType, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                    if (media.deviceId != null)
                      Text(media.deviceId!, style: TextStyle(color: Colors.grey[600], fontSize: 11, fontFamily: 'monospace')),
                  ]),
                ),
                const SizedBox(height: 28),
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(colors: [const Color(0xFF00E5FF).withOpacity(0.3), const Color(0xFF7C4DFF).withOpacity(0.3)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Icon(Icons.music_note, size: 72, color: Colors.white54),
                ),
                const SizedBox(height: 20),
                Text(media.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(media.artist, style: TextStyle(fontSize: 14, color: Colors.grey[400])),
                if (media.album.isNotEmpty) Text(media.album, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 20),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(activeTrackColor: const Color(0xFF00E5FF), inactiveTrackColor: Colors.grey[800], thumbColor: const Color(0xFF00E5FF)),
                  child: Slider(value: media.durationMs > 0 ? (media.positionMs / media.durationMs).clamp(0.0, 1.0) : 0, onChanged: (v) => media.seek(v)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(MediaControlService.formatTime(media.positionMs), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    Text(MediaControlService.formatTime(media.durationMs), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  ]),
                ),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  IconButton(iconSize: 36, onPressed: () => media.previous(), icon: const Icon(Icons.skip_previous, color: Colors.white)),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF00E5FF).withOpacity(0.2), border: Border.all(color: const Color(0xFF00E5FF))),
                    child: IconButton(iconSize: 48, onPressed: () => media.togglePlayPause(), icon: Icon(media.isPlaying ? Icons.pause : Icons.play_arrow, color: const Color(0xFF00E5FF))),
                  ),
                  const SizedBox(width: 12),
                  IconButton(iconSize: 36, onPressed: () => media.next(), icon: const Icon(Icons.skip_next, color: Colors.white)),
                ]),
                const SizedBox(height: 24),
                Row(children: [
                  const Icon(Icons.volume_down, color: Colors.grey, size: 22),
                  Expanded(child: SliderTheme(data: SliderTheme.of(context).copyWith(activeTrackColor: Colors.orange, inactiveTrackColor: Colors.grey[800], thumbColor: Colors.orange), child: Slider(value: media.volume, onChanged: (v) => media.setVolume(v)))),
                  const Icon(Icons.volume_up, color: Colors.grey, size: 22),
                ]),
                const SizedBox(height: 28),
                Align(alignment: Alignment.centerLeft, child: Text('DEVICE FUNCTIONS', style: TextStyle(color: Colors.grey[600], fontSize: 11, letterSpacing: 1))),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _funcChip(Icons.equalizer, 'EQ', () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('EQ profile → Cabin (sim)')))),
                  _funcChip(Icons.surround_sound, 'Surround', () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Surround toggle (sim)')))),
                  _funcChip(Icons.phone, 'Call audio', () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Route call audio (sim)')))),
                  _funcChip(Icons.navigation, 'Nav prompts', () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigation voice ducking (sim)')))),
                  _funcChip(Icons.mic, 'Voice assist', () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voice assistant trigger (sim)')))),
                  _funcChip(Icons.power_settings_new, 'Disconnect', () { media.detach(); Navigator.pop(context); }),
                ]),
                const SizedBox(height: 24),
                Text('Local/sim controls. Remote AVRCP/A2DP needs platform channels for true headset control.', style: TextStyle(color: Colors.grey[700], fontSize: 11), textAlign: TextAlign.center),
              ]),
            );
          },
        ),
      ),
    );
  }

  Widget _funcChip(IconData icon, String label, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: const Color(0xFF00E5FF)),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.grey[900],
      side: BorderSide(color: Colors.grey[700]!),
    );
  }
}
