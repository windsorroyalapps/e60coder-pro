import 'package:flutter/material.dart';

class AftermarketHuScreen extends StatelessWidget {
  const AftermarketHuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AFTERMARKET HU / CAN')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF69F0AE).withOpacity(0.5)),
              gradient: LinearGradient(colors: [const Color(0xFF69F0AE).withOpacity(0.15), Colors.transparent]),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aftermarket head unit + CAN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF69F0AE))),
                SizedBox(height: 6),
                Text('SWC interfaces, BMW E60 notes, and what this app does for OBD vs the stereo install.', style: TextStyle(fontSize: 13, height: 1.35)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _card('How aftermarket HUs use CAN', const Color(0xFF00E5FF),
              'Most double-DIN Android / Pioneer / Sony / Kenwood units do not sit as a full peer on the vehicle powertrain CAN. They use a vehicle-specific interface box that:\n\n'
              '\u2022 Reads a limited set of body/comfort messages (ignition, lights, reverse)\n'
              '\u2022 Translates steering-wheel controls (SWC) to IR, resistive, or key codes\n'
              '\u2022 Sometimes provides speed/RPM from OBD for apps or mute logic\n\n'
              'The phone app talks to OBD/ELM or the HU over BT/Wi-Fi for media \u2014 not as a substitute for that install interface.'),
          const SizedBox(height: 12),
          _card('BMW E60 notes', const Color(0xFFFF6D00),
              'E60 platforms use multiple networks (e.g. K-CAN / PT-CAN style segments) and factory audio that is often MOST or brand-specific digital \u2014 not a simple USB Android radio.\n\n'
              'Typical aftermarket path:\n'
              '1. Dash kit + wiring harness for your chassis\n'
              '2. SWC / CAN interface (PAC, iDatalink, brand-specific BMW module)\n'
              '3. Optional antenna / camera / amp adapters\n'
              '4. Head unit BT/Wi-Fi for phone projection only\n\n'
              'K-DCAN / OBD in E60Coder Pro is for diagnostics through the OBD gateway \u2014 not for driving a proprietary HU CAN box protocol.'),
          const SizedBox(height: 12),
          _card('Common interface brands', const Color(0xFF7C4DFF),
              'PAC / RP-series \u2014 SWC + often CAN for many brands\n'
              'iDatalink / Maestro \u2014 deep vehicle integration\n'
              'Axxess / Metra \u2014 harness + interface kits\n'
              'Brand OEM boxes \u2014 Pioneer/Sony/Kenwood vehicle kits\n'
              'Generic OBD gauges \u2014 ELM-style dongle \u2192 speed/RPM to HU apps\n\n'
              'Always match the interface to chassis year/model.'),
          const SizedBox(height: 12),
          _card('What E60Coder Pro can vs cannot do', const Color(0xFF00E676),
              'Connect ELM/K-DCAN on your car \u2014 Yes (Connect / CAN gateway)\n'
              'Log PIDs (RPM, speed, temp) \u2014 Yes (Gauges + Recorder)\n'
              'SWC programming of PAC/Maestro \u2014 No (use vendor tools)\n'
              'Replace MOST fiber in software \u2014 No (hardware install)\n'
              'Proprietary HU CAN protocol \u2014 Only if documented serial/ELM bridge'),
          const SizedBox(height: 12),
          _card('Install checklist (E60-oriented)', const Color(0xFFFFEA00),
              '\u2610 Battery disconnected before major harness work\n'
              '\u2610 Correct dash kit for E60 sedan/touring\n'
              '\u2610 Power / ground / ignition / illumination verified\n'
              '\u2610 SWC interface programmed for BMW + head-unit brand\n'
              '\u2610 Reverse camera trigger (CAN or discrete) tested\n'
              '\u2610 Steering wheel buttons: volume, track, voice, mode\n'
              '\u2610 No airbag / SRS wiring modified\n'
              '\u2610 OBD port still free for diagnostics\n'
              '\u2610 After install: scan for body-module faults if bus was disturbed'),
          const SizedBox(height: 12),
          _card('Legal / safety', Colors.redAccent,
              'Only work on vehicles you own or are authorized to modify. Do not disturb airbag, ABS, or powertrain control wiring. CAN experiments without a proper interface can set faults or affect vehicle systems.'),
          const SizedBox(height: 24),
          Text('Reference only \u2014 not a substitute for vehicle-specific install guides.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  static Widget _card(String title, Color color, String body) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 10),
          Text(body, style: const TextStyle(fontSize: 13, height: 1.45)),
        ],
      ),
    );
  }
}
