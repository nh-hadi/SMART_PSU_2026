import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Halaman 2: Overview Layar Penuh 4-Channel USB
class UsbPage2Overview extends StatelessWidget {
  final List<Map<String, dynamic>> channelsData;
  final String themeName;
  final Color activeColor;
  final Function(int) onSelectChannel;

  const UsbPage2Overview({
    super.key,
    required this.channelsData,
    required this.themeName,
    required this.activeColor,
    required this.onSelectChannel,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFullColor = themeName == 'FULL_COLOR';

    return Column(
      children: [
        // Grid 4 Channel (2x2 Grid Penuh)
        Expanded(
          child: Column(
            children: [
              // Baris 1: CH1 & CH2
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _buildUsbChannelCard(channelsData[0])),
                    SizedBox(width: isFullColor ? 6 : 4),
                    Expanded(child: _buildUsbChannelCard(channelsData[1])),
                  ],
                ),
              ),
              SizedBox(height: isFullColor ? 6 : 4),

              // Baris 2: CH3 & CH4
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _buildUsbChannelCard(channelsData[2])),
                    SizedBox(width: isFullColor ? 6 : 4),
                    Expanded(child: _buildUsbChannelCard(channelsData[3])),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Kartu Kompak Tiap Channel di Panel Overview (Desain Premium Dashboard)
  Widget _buildUsbChannelCard(Map<String, dynamic> data) {
    final bool isFullColor = themeName == 'FULL_COLOR';
    final int chNum = data['ch'] as int;

    // Aksen warna per channel
    Color chAccentColor;
    switch (chNum) {
      case 1:
        chAccentColor = const Color(0xFF00E5FF); // Neon Cyan
        break;
      case 2:
        chAccentColor = const Color(0xFFFF007F); // Neon Rose
        break;
      case 3:
        chAccentColor = const Color(0xFFFFD600); // Amber Yellow
        break;
      default:
        chAccentColor = const Color(0xFF00FF88); // Neon Green
    }

    // Helper untuk memisahkan angka dan satuan unit
    List<String> splitValueUnit(String str) {
      final parts = str.trim().split(' ');
      if (parts.length >= 2) return [parts[0], parts.sublist(1).join(' ')];
      return [str, ''];
    }

    final voltParts = splitValueUnit(data['volt'] as String);
    final ampParts = splitValueUnit(data['amp'] as String);
    final wattParts = splitValueUnit(data['watt'] as String);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onSelectChannel(chNum);
      },
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: isFullColor ? const Color(0xFF0E1322) : const Color(0xFF0A0A0A),
          border: Border.all(
            color: isFullColor ? chAccentColor.withOpacity(0.35) : activeColor.withOpacity(0.5),
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: isFullColor ? chAccentColor.withOpacity(0.08) : Colors.black54,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar: Badge CH, Nama Port, Status Active
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: isFullColor
                        ? LinearGradient(
                            colors: [chAccentColor.withOpacity(0.35), chAccentColor.withOpacity(0.12)],
                          )
                        : null,
                    color: isFullColor ? null : Colors.transparent,
                    border: Border.all(
                      color: isFullColor ? chAccentColor.withOpacity(0.8) : activeColor,
                      width: 0.9,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'CH ${data['ch']}',
                    style: TextStyle(
                      color: isFullColor ? chAccentColor : activeColor,
                      fontSize: 9.5,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    data['name'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF88).withOpacity(0.12),
                    border: Border.all(
                      color: const Color(0xFF00FF88).withOpacity(0.6),
                      width: 0.8,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 4.5,
                        height: 4.5,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00FF88),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Color(0xFF00FF88), blurRadius: 4),
                          ],
                        ),
                      ),
                      const SizedBox(width: 3.5),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Color(0xFF00FF88),
                          fontSize: 7.5,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),

            // Main Display: 3 Metrik Card (Volt, Amp, Watt) dengan Value & Unit jelas
            Expanded(
              child: Row(
                children: [
                  // 1. VOLT CARD
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 5),
                      decoration: BoxDecoration(
                        color: isFullColor ? const Color(0xFF141A2E) : Colors.black,
                        border: Border.all(
                          color: isFullColor ? const Color(0xFF00E5FF).withOpacity(0.25) : Colors.white24,
                          width: 0.8,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(Icons.bolt, size: 11, color: isFullColor ? const Color(0xFF00E5FF) : Colors.white70),
                              const SizedBox(width: 3),
                              Text(
                                'VOLTAGE',
                                style: TextStyle(
                                  color: isFullColor ? const Color(0xFF00E5FF) : Colors.white70,
                                  fontSize: 8.5,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    voltParts[0],
                                    style: TextStyle(
                                      color: isFullColor ? const Color(0xFF00E5FF) : Colors.white,
                                      fontSize: 24,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    voltParts[1],
                                    style: TextStyle(
                                      color: isFullColor ? const Color(0xFF00E5FF).withOpacity(0.8) : Colors.white70,
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // 2. AMPERE CARD
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 5),
                      decoration: BoxDecoration(
                        color: isFullColor ? const Color(0xFF141A2E) : Colors.black,
                        border: Border.all(
                          color: isFullColor ? const Color(0xFFFF007F).withOpacity(0.25) : Colors.white24,
                          width: 0.8,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(Icons.waves, size: 11, color: isFullColor ? const Color(0xFFFF007F) : Colors.amberAccent),
                              const SizedBox(width: 3),
                              Text(
                                'CURRENT',
                                style: TextStyle(
                                  color: isFullColor ? const Color(0xFFFF007F) : Colors.amberAccent,
                                  fontSize: 8.5,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    ampParts[0],
                                    style: TextStyle(
                                      color: isFullColor ? const Color(0xFFFF007F) : Colors.amberAccent,
                                      fontSize: 24,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    ampParts[1],
                                    style: TextStyle(
                                      color: isFullColor ? const Color(0xFFFF007F).withOpacity(0.8) : Colors.amberAccent,
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // 3. WATT CARD
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 5),
                      decoration: BoxDecoration(
                        color: isFullColor ? const Color(0xFF141A2E) : Colors.black,
                        border: Border.all(
                          color: isFullColor ? const Color(0xFFFFD600).withOpacity(0.25) : Colors.white24,
                          width: 0.8,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(Icons.speed, size: 11, color: isFullColor ? const Color(0xFFFFD600) : Colors.cyanAccent),
                              const SizedBox(width: 3),
                              Text(
                                'POWER',
                                style: TextStyle(
                                  color: isFullColor ? const Color(0xFFFFD600) : Colors.cyanAccent,
                                  fontSize: 8.5,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    wattParts[0],
                                    style: TextStyle(
                                      color: isFullColor ? const Color(0xFFFFD600) : Colors.cyanAccent,
                                      fontSize: 24,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    wattParts[1],
                                    style: TextStyle(
                                      color: isFullColor ? const Color(0xFFFFD600).withOpacity(0.8) : Colors.cyanAccent,
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),

            // Bottom Bar: D+/D-, Kapasitas mAh, dan Badge Protokol Charging
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
              decoration: BoxDecoration(
                color: isFullColor ? const Color(0xFF141A2E) : Colors.black,
                border: isFullColor ? null : Border.all(color: Colors.white12, width: 0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Text(
                    'D+ ${data['dp']}',
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 8,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'D- ${data['dm']}',
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 8,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 8,
                    color: Colors.white24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${data['mah']}',
                    style: const TextStyle(
                      color: Color(0xFF00FF88),
                      fontSize: 8,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7928CA).withOpacity(0.25),
                      border: Border.all(color: const Color(0xFFC084FC).withOpacity(0.6), width: 0.6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      '${data['protocol']}',
                      style: const TextStyle(
                        color: Color(0xFFE9D5FF),
                        fontSize: 7.5,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
