/// Decodes BLE advertising / service data into human-readable
/// "what is this channel broadcasting?" categories.
class BroadcastDecoder {
  static DecodeResult decode({
    required String name,
    required String id,
    List<String> serviceUuids = const [],
    Map<int, List<int>> manufacturerData = const {},
    Map<String, List<int>> serviceData = const {},
    bool connectable = true,
  }) {
    final categories = <String>{};
    final details = <String>[];
    final nameLower = name.toLowerCase();

    if (_matchesAny(nameLower, ['obd', 'elm', 'vgate', 'carista', 'obdlink', 'bimmer'])) {
      categories.add('Vehicle / OBD diagnostics');
      details.add('Name suggests OBD-II / car diagnostic adapter');
    }
    if (_matchesAny(nameLower, ['airpod', 'headset', 'buds', 'speaker', 'soundbar', 'jbl', 'bose', 'sony wh', 'sony wf'])) {
      categories.add('Audio / headphones');
    }
    if (_matchesAny(nameLower, ['watch', 'band', 'fitbit', 'garmin', 'polar', 'mi band'])) {
      categories.add('Wearable / fitness');
    }
    if (_matchesAny(nameLower, ['mouse', 'keyboard', 'trackpad', 'hid'])) {
      categories.add('Input device (HID)');
    }
    if (_matchesAny(nameLower, ['printer', 'hp ', 'canon', 'epson'])) {
      categories.add('Printer / imaging');
    }
    if (_matchesAny(nameLower, ['tv', 'roku', 'chromecast', 'fire stick', 'apple tv'])) {
      categories.add('Media / streaming device');
    }
    if (_matchesAny(nameLower, ['gps', 'navigator', 'tomtom', 'garmin'])) {
      categories.add('GPS / navigation');
    }

    for (final uuid in serviceUuids) {
      final short = _to16Bit(uuid);
      final cat = _uuidCategory[short];
      if (cat != null) {
        categories.add(cat);
        details.add('Service $short → $cat');
      } else if (uuid.isNotEmpty) {
        details.add('Service UUID: $uuid');
      }
    }

    for (final entry in manufacturerData.entries) {
      final company = _companyName[entry.key] ?? 'Company 0x${entry.key.toRadixString(16).padLeft(4, '0')}';
      final hex = entry.value.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
      details.add('Manufacturer: $company  [$hex]');
      if (entry.key == 0x004C) categories.add('Apple ecosystem (Continuity / AirPods / Watch)');
      if (entry.key == 0x00E0) categories.add('Google Fast Pair / Android');
    }

    for (final entry in serviceData.entries) {
      final short = _to16Bit(entry.key);
      final cat = _uuidCategory[short];
      final hex = entry.value.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
      if (cat != null) {
        categories.add(cat);
        details.add('SvcData $short ($cat): $hex');
      } else {
        details.add('SvcData $short: $hex');
      }
    }

    if (categories.isEmpty) {
      categories.add(connectable ? 'Generic BLE peripheral' : 'Beacon / non-connectable');
    }

    return DecodeResult(
      categories: categories.toList()..sort(),
      details: details,
      primary: categories.isNotEmpty ? categories.first : 'Unknown',
    );
  }

  static bool _matchesAny(String text, List<String> keys) => keys.any((k) => text.contains(k));

  static String _to16Bit(String uuid) {
    final clean = uuid.toLowerCase().replaceAll('-', '');
    if (clean.length >= 8 && clean.startsWith('0000') && clean.contains('00001000800000805f9b34fb')) {
      return '0x${clean.substring(4, 8)}';
    }
    if (clean.length == 4) return '0x$clean';
    if (clean.length == 8) return '0x${clean.substring(4)}';
    return uuid.length > 12 ? uuid.substring(0, 8) + '…' : uuid;
  }

  static const Map<String, String> _uuidCategory = {
    '0x1108': 'Audio (Headset)',
    '0x110a': 'Audio (A2DP Source)',
    '0x110b': 'Audio (A2DP Sink)',
    '0x110c': 'Audio (AVRCP Target)',
    '0x110e': 'Audio (AVRCP Controller)',
    '0x110f': 'Audio (Advanced Audio)',
    '0x111e': 'Audio (Hands-Free)',
    '0x111f': 'Audio (Hands-Free Audio Gateway)',
    '0x1203': 'Audio (Generic Audio)',
    '0x184e': 'Audio (Telephone Bearer)',
    '0x184f': 'Audio (Microphone Control)',
    '0x1850': 'Audio (Audio Stream Control)',
    '0x1851': 'Audio (Broadcast Audio Scan)',
    '0x1852': 'Audio (Published Audio Capabilities)',
    '0x1853': 'Audio (Basic Audio Announcement)',
    '0x1854': 'Audio (Broadcast Audio Announcement)',
    '0x1855': 'Audio (Common Audio)',
    '0x1848': 'Media control / playback',
    '0x1849': 'Media control (Generic)',
    '0x1105': 'File transfer (OPP)',
    '0x1106': 'File transfer (FTP)',
    '0x112f': 'Phonebook access',
    '0x1130': 'Phonebook access (PSE)',
    '0x1132': 'Message access (MAP)',
    '0x1124': 'Input device (HID)',
    '0x1812': 'Input device (HID Service)',
    '0x1813': 'Input (Scan Parameters)',
    '0x180d': 'Health (Heart Rate)',
    '0x180f': 'Health (Battery)',
    '0x1810': 'Health (Blood Pressure)',
    '0x1816': 'Fitness (Cycling Speed/Cadence)',
    '0x1818': 'Fitness (Cycling Power)',
    '0x1814': 'Fitness (Running Speed/Cadence)',
    '0x181a': 'Environment / sensors',
    '0x181c': 'User Data',
    '0x1822': 'Pulse Oximeter',
    '0x1826': 'Fitness Machine',
    '0x1819': 'Location / Navigation',
    '0x1821': 'Indoor Positioning',
    '0x1805': 'Time (Current Time)',
    '0x1806': 'Time (Reference Time Update)',
    '0x1807': 'Time (Next DST Change)',
    '0x180a': 'Device Information',
    '0x1800': 'Generic Access',
    '0x1801': 'Generic Attribute',
    '0x1112': 'Headset Audio Gateway',
    '0x112e': 'Phonebook Access Client',
    '0xfff0': 'Vendor / custom (often OBD serial bridge)',
    '0xffe0': 'Vendor / custom serial',
    '0xffe5': 'Vendor / custom serial',
  };

  static const Map<int, String> _companyName = {
    0x0006: 'Microsoft',
    0x000a: 'Qualcomm',
    0x004c: 'Apple',
    0x0059: 'Nordic Semiconductor',
    0x0075: 'Samsung',
    0x00e0: 'Google',
    0x0131: 'Cypress / Infineon',
    0x0157: 'Anhui Huami (Amazfit)',
    0x02e5: 'Espressif',
    0x005d: 'Realtek',
    0x00d2: 'Sony',
    0x0087: 'Garmin',
    0x01d1: 'Fitbit',
  };
}

class DecodeResult {
  final List<String> categories;
  final List<String> details;
  final String primary;

  DecodeResult({required this.categories, required this.details, required this.primary});
}
