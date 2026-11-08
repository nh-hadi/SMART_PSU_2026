import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'psu_udp_service.dart';
import 'theme.dart';

class HardwareTestView extends StatefulWidget {
  final Color activeColor;
  final String themeName;

  const HardwareTestView({
    super.key,
    required this.activeColor,
    this.themeName = 'FULL_COLOR',
  });

  @override
  State<HardwareTestView> createState() => _HardwareTestViewState();
}

class _HardwareTestViewState extends State<HardwareTestView> {
  final PsuUdpService _udpService = PsuUdpService.instance;

  bool _mosfetState = false;
  bool _relay1State = false;
  bool _relay2State = false;
  late final TextEditingController _ipController;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: _udpService.targetIp);
    _udpService.ipNotifier.addListener(_onAutoIpDetected);
    // Sinkronkan switch awal dengan data telemetri terakhir
    final cur = _udpService.dataNotifier.value;
    _mosfetState = cur.mosfet;
    _relay1State = cur.relay1;
    _relay2State = cur.relay2;
  }

  void _onAutoIpDetected() {
    if (mounted && _ipController.text != _udpService.targetIp) {
      setState(() {
        _ipController.text = _udpService.targetIp;
      });
    }
  }

  @override
  void dispose() {
    _udpService.ipNotifier.removeListener(_onAutoIpDetected);
    _ipController.dispose();
    super.dispose();
  }

  void _toggleSwitch(String target, bool current) {
    HapticFeedback.selectionClick();
    final newState = !current;
    setState(() {
      if (target == 'mosfet') _mosfetState = newState;
      if (target == 'relay1') _relay1State = newState;
      if (target == 'relay2') _relay2State = newState;
    });
    _udpService.sendCommand(target, newState);
  }

  void _setAllOutputs(bool state) {
    HapticFeedback.mediumImpact();
    setState(() {
      _mosfetState = state;
      _relay1State = state;
      _relay2State = state;
    });
    _udpService.sendCommand('all', state);
  }

  Widget _buildControlCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool state,
    required Color color,
    required VoidCallback onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF131826),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: state ? color.withOpacity(0.8) : Colors.white12,
          width: state ? 1.4 : 0.8,
        ),
        boxShadow: state
            ? [
                BoxShadow(
                  color: color.withOpacity(0.25),
                  blurRadius: 8,
                )
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: state ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, color: state ? color : Colors.white54, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: state ? color : Colors.white,
                    fontSize: 9.5,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 7.5,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: state ? color : const Color(0xFF222B3D),
                borderRadius: BorderRadius.circular(4),
                boxShadow: state
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 6,
                        )
                      ]
                    : null,
              ),
              child: Text(
                state ? 'AKTIF (ON)' : 'OFF',
                style: TextStyle(
                  color: state ? Colors.black : Colors.white70,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveSensorBadge({
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1420),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white10, width: 0.7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 7, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 1),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(color: color.withOpacity(0.8), fontSize: 7, fontFamily: 'monospace'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PsuTelemetryData>(
      valueListenable: _udpService.dataNotifier,
      builder: (context, data, _) {
        return Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: const Color(0xFF0B0E18),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Menu Uji Coba
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF007F), Color(0xFFFF5252)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.build_circle, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'HARDWARE TEST BENCH (DIAGNOSTIK)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Tombol Quick All On & All Off
                  GestureDetector(
                    onTap: () => _setAllOutputs(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.2),
                        border: Border.all(color: Colors.greenAccent, width: 0.8),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        'ALL ON',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _setAllOutputs(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.2),
                        border: Border.all(color: Colors.redAccent, width: 0.8),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        'ALL OFF',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Area Kontrol Switch & Status Live
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kolom Kiri: Saklar Pengujian (MOSFET & 2 RELAY)
                    Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          _buildControlCard(
                            title: 'MOSFET OUTPUT POWER',
                            subtitle: 'GPIO D7 / Direct Cut-Off',
                            icon: Icons.electric_bolt,
                            state: data.mosfet,
                            color: const Color(0xFF00E5FF),
                            onToggle: () => _toggleSwitch('mosfet', data.mosfet),
                          ),
                          const SizedBox(height: 6),
                          _buildControlCard(
                            title: 'RELAY 1 (MAIN RAIL)',
                            subtitle: 'GPIO D5 / High Current Switch',
                            icon: Icons.toggle_on,
                            state: data.relay1,
                            color: const Color(0xFFFF9100),
                            onToggle: () => _toggleSwitch('relay1', data.relay1),
                          ),
                          const SizedBox(height: 6),
                          _buildControlCard(
                            title: 'RELAY 2 (AUX RAIL)',
                            subtitle: 'GPIO D6 / Auxiliary Output',
                            icon: Icons.toggle_on,
                            state: data.relay2,
                            color: const Color(0xFF00E676),
                            onToggle: () => _toggleSwitch('relay2', data.relay2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Kolom Kanan: Monitoring Respon Sensor Live (INA3221 & ADS1115)
                    Expanded(
                      flex: 5,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10131F),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white12, width: 0.8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.analytics, color: Color(0xFFA855F7), size: 12),
                                const SizedBox(width: 4),
                                const Text(
                                  'RESPON SENSOR SECARA LANGSUNG (LIVE)',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                ValueListenableBuilder<int>(
                                  valueListenable: _udpService.packetCountNotifier,
                                  builder: (context, count, _) => Text(
                                    'PKT: $count',
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 7,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white12, height: 10),
                            // INA3221 Channel 1, 2, 3
                            Row(
                              children: [
                                Expanded(
                                  child: _buildLiveSensorBadge(
                                    label: 'INA CH1 (PSU)',
                                    value: '${data.v1.toStringAsFixed(2)}V',
                                    unit: '${data.i1.toStringAsFixed(0)}mA',
                                    color: const Color(0xFF00E5FF),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: _buildLiveSensorBadge(
                                    label: 'INA CH2 (AUX)',
                                    value: '${data.v2.toStringAsFixed(2)}V',
                                    unit: '${data.i2.toStringAsFixed(0)}mA',
                                    color: const Color(0xFFFF9100),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: _buildLiveSensorBadge(
                                    label: 'INA CH3 (USB)',
                                    value: '${data.v3.toStringAsFixed(2)}V',
                                    unit: '${data.i3.toStringAsFixed(0)}mA',
                                    color: const Color(0xFF00E676),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // ADS1115 A1, A2, A3
                            Row(
                              children: [
                                Expanded(
                                  child: _buildLiveSensorBadge(
                                    label: 'ADS A1 (D-)',
                                    value: data.dm.toStringAsFixed(2),
                                    unit: 'V',
                                    color: const Color(0xFFFFEA00),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: _buildLiveSensorBadge(
                                    label: 'ADS A2 (D+)',
                                    value: data.dp.toStringAsFixed(2),
                                    unit: 'V',
                                    color: const Color(0xFF00E5FF),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: _buildLiveSensorBadge(
                                    label: 'ADS A3 (AVO)',
                                    value: data.avo.toStringAsFixed(2),
                                    unit: 'V',
                                    color: const Color(0xFFFF007F),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            // Baris Khusus: Status Alamat I2C Terdaftar (I2C Bus Scanner Live)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF181C2B),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFA855F7).withOpacity(0.4), width: 0.8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.hub, color: Color(0xFFA855F7), size: 12),
                                  const SizedBox(width: 5),
                                  const Text(
                                    'I2C BUS DETECTED:',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 7.5,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      data.i2cAddrs,
                                      style: const TextStyle(
                                        color: Color(0xFF00FF88),
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'monospace',
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            // Box Pengaturan Set IP Target ESP
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black38,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.white12, width: 0.6),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.settings_ethernet, color: Color(0xFF00E5FF), size: 12),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'IP ESP:',
                                    style: TextStyle(color: Colors.white70, fontSize: 7.5, fontFamily: 'monospace'),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: SizedBox(
                                      height: 20,
                                      child: TextField(
                                        controller: _ipController,
                                        style: const TextStyle(
                                          color: Color(0xFF00FF88),
                                          fontSize: 8,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.bold,
                                        ),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF88))),
                                          hintText: '192.168.4.1',
                                          hintStyle: TextStyle(color: Colors.white30, fontSize: 7.5),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      _udpService.updateTargetIp(_ipController.text);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          duration: const Duration(milliseconds: 900),
                                          content: Text('Target IP ESP diubah ke: ${_ipController.text}'),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00E5FF).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(3),
                                        border: Border.all(color: const Color(0xFF00E5FF), width: 0.6),
                                      ),
                                      child: const Text(
                                        'SET',
                                        style: TextStyle(
                                          color: Color(0xFF00E5FF),
                                          fontSize: 7.5,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Info Status Koneksi Live
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'PORT: ${_udpService.port}',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 7.5,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  ValueListenableBuilder<bool>(
                                    valueListenable: _udpService.connectionNotifier,
                                    builder: (context, connected, _) => Text(
                                      connected ? 'CONNECTED [ONLINE]' : 'OFFLINE (MENUNGGU PAKET)',
                                      style: TextStyle(
                                        color: connected ? Colors.greenAccent : Colors.redAccent,
                                        fontSize: 7.5,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
