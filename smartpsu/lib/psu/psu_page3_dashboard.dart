import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../psu_udp_service.dart';

class PsuPage3DashboardView extends StatefulWidget {
  final Color activeColor;
  final String themeName;
  final double liveVolt;
  final double liveAmp;
  final double ocpLimit;
  final VoidCallback? onBack;

  const PsuPage3DashboardView({
    super.key,
    required this.activeColor,
    this.themeName = 'FULL_COLOR',
    required this.liveVolt,
    required this.liveAmp,
    required this.ocpLimit,
    this.onBack,
  });

  @override
  State<PsuPage3DashboardView> createState() => _PsuPage3DashboardViewState();
}

class _PsuPage3DashboardViewState extends State<PsuPage3DashboardView> {
  // Toggle filter sinyal: Arus di kiri, Volt di kanan
  bool _showArus = true;
  bool _showVolt = true;

  // Daftar range skala yang tersedia
  static const List<double> _ranges = [500.0, 1000.0, 2000.0, 3000.0, 5000.0];
  int _currentRangeIndex = 0;

  double get _currentMaxmA => _ranges[_currentRangeIndex];

  String get _currentRangeLabel {
    if (_currentMaxmA >= 1000) {
      return '0-${(_currentMaxmA / 1000).toStringAsFixed(0)}A';
    }
    return '0-${_currentMaxmA.toStringAsFixed(0)}mA';
  }

  void _nextRange() {
    setState(() {
      _currentRangeIndex = (_currentRangeIndex + 1) % _ranges.length;
    });
  }

  void _prevRange() {
    setState(() {
      _currentRangeIndex = (_currentRangeIndex - 1 + _ranges.length) % _ranges.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isFullColor = widget.themeName == 'FULL_COLOR';
    final Color activeColor = widget.activeColor;
    final double liveVolt = widget.liveVolt;
    final double liveAmp = widget.liveAmp;
    final double safeVolt = liveVolt.isFinite ? liveVolt : 0.0;
    final double safeAmp = liveAmp.isFinite ? liveAmp : 0.0;
    final double safeOcp = widget.ocpLimit.isFinite ? widget.ocpLimit : 2.0;

    final double currentmA = safeAmp * 1000.0;
    final double displaymA = currentmA > 0 ? currentmA : 100.0;
    final double displayVolt = safeVolt > 0 ? safeVolt : 5.20;
    final double displayWatt = displayVolt * (displaymA / 1000.0);

    return Container(
      decoration: BoxDecoration(
        color: isFullColor ? const Color(0xFF070913) : Colors.black,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ----------------------------------------
          // BAGIAN ATAS: SPLIT KIRI (METER SWIPEABLE 0-500mA s/d 5A) & KANAN (3 INSTRUMENT CARDS)
          // ----------------------------------------
          Expanded(
            flex: 10,
            child: Row(
              children: [
                // 1. KIRI: ANALOG METER DENGAN GESTURE SWIPE KIRI/KANAN
                Expanded(
                  flex: 9,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragEnd: (DragEndDetails details) {
                      // Geser ke kiri -> range berikutnya (500mA -> 1A -> 2A -> 3A -> 5A)
                      if (details.primaryVelocity != null) {
                        if (details.primaryVelocity! < -100) {
                          _nextRange();
                        } else if (details.primaryVelocity! > 100) {
                          _prevRange();
                        }
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(4, 4, 2, 2),
                      child: Stack(
                        children: [
                          // Header Kiri Atas: Selector Range Skala (Tap/Swipe)
                          Positioned(
                            top: 5,
                            left: 6,
                            child: GestureDetector(
                              onTap: _nextRange,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(
                                    color: widget.activeColor.withOpacity(0.5),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.tune,
                                      color: widget.activeColor,
                                      size: 9,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      _currentRangeLabel,
                                      style: TextStyle(
                                        color: widget.activeColor,
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(
                                      Icons.swipe_outlined,
                                      color: Colors.white54,
                                      size: 9,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Header Kanan Atas: Fast + Tombol Back
                          Positioned(
                            top: 6,
                            right: 8,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: widget.onBack,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: const Icon(Icons.arrow_back, color: Colors.white70, size: 10),
                                  ),
                                ),
                                const Text(
                                  'Fast',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Dial Arc Gauge & Needle (Dinamis: 0-500mA s/d 0-5000mA)
                          Positioned.fill(
                            top: 2,
                            bottom: 20,
                            child: CustomPaint(
                              painter: DarkAmmeterGaugePainter(
                                currentmA: displaymA,
                                maxScale: _currentMaxmA,
                              ),
                            ),
                          ),

                          // Indikator Titik Paging Range di Tengah Bawah Meter
                          Positioned(
                            bottom: 26,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(_ranges.length, (idx) {
                                final bool isSelected = idx == _currentRangeIndex;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _currentRangeIndex = idx;
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                                    width: isSelected ? 10 : 4,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: isSelected ? widget.activeColor : Colors.white24,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),

                          // Baris Bawah Meter: [5.20 v]  [ 100 mA ]  [Range & Max]
                          Positioned(
                            bottom: 6,
                            left: 10,
                            right: 10,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Voltase Digital Badge
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      displayVolt.toStringAsFixed(2),
                                      style: TextStyle(
                                        color: isFullColor ? const Color(0xFF00E5FF) : const Color(0xFFF78B9B),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      'V',
                                      style: TextStyle(
                                        color: isFullColor ? const Color(0xFF00E5FF).withOpacity(0.8) : const Color(0xFFE0E0E0),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),

                                // Panel Nilai mA Pill Glow
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: isFullColor ? const Color(0xFF141A2E) : const Color(0xFF646769).withOpacity(0.55),
                                    borderRadius: BorderRadius.circular(5),
                                    border: isFullColor ? Border.all(color: const Color(0xFF00FF88).withOpacity(0.3), width: 0.8) : null,
                                    boxShadow: [
                                      BoxShadow(
                                        color: isFullColor ? const Color(0xFF00FF88).withOpacity(0.12) : Colors.black.withOpacity(0.2),
                                        blurRadius: 6,
                                        offset: const Offset(0, 1.5),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        displaymA >= 1000 && _currentMaxmA >= 1000
                                            ? (displaymA / 1000.0).toStringAsFixed(3)
                                            : displaymA.toStringAsFixed(0),
                                        style: const TextStyle(
                                          color: Color(0xFF00FF88), // Hijau Neon mint kontras
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        displaymA >= 1000 && _currentMaxmA >= 1000 ? 'A' : 'mA',
                                        style: TextStyle(
                                          color: isFullColor ? const Color(0xFF00FF88).withOpacity(0.8) : const Color(0xFFE0E0E0),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),

                                // Range & Max
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: _nextRange,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('Range  ', style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 7.5, fontWeight: FontWeight.bold)),
                                          Text(_currentRangeLabel, style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('Max  ', style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 7.5, fontWeight: FontWeight.bold)),
                                        Text('${safeOcp > 0 ? (safeOcp * 1000).toStringAsFixed(0) : "100"}mA', style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. KANAN: 3 MODUL INSTRUMEN (Lebar flex 11)
                Expanded(
                  flex: 11,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(2, 4, 4, 2),
                    child: Column(
                      children: [
                        // Baris 1: Voltage + Ampere Card
                        Expanded(
                          flex: 5,
                          child: Row(
                            children: [
                              // Modul 1: Voltage (Neon Cyan)
                              Expanded(
                                flex: 1,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  margin: const EdgeInsets.only(right: 2),
                                  decoration: BoxDecoration(
                                    color: isFullColor ? const Color(0xFF10131F) : Colors.black,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isFullColor ? const Color(0xFF00E5FF).withOpacity(0.35) : activeColor,
                                      width: 1.0,
                                    ),
                                    boxShadow: isFullColor
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFF00E5FF).withOpacity(0.08),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(Icons.bolt, color: Color(0xFF00E5FF), size: 11),
                                              SizedBox(width: 3),
                                              Text(
                                                'VOLTAGE',
                                                style: TextStyle(
                                                  color: Color(0xFF00E5FF),
                                                  fontSize: 8.0,
                                                  fontWeight: FontWeight.w900,
                                                  fontFamily: 'monospace',
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Text(
                                            '0-30V',
                                            style: TextStyle(
                                              color: Colors.white38,
                                              fontSize: 7.0,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      Center(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.baseline,
                                            textBaseline: TextBaseline.alphabetic,
                                            children: [
                                              Text(
                                                displayVolt.toStringAsFixed(3),
                                                style: const TextStyle(
                                                  color: Color(0xFF00E5FF),
                                                  fontSize: 36,
                                                  fontWeight: FontWeight.w900,
                                                  fontFamily: 'monospace',
                                                  letterSpacing: 0.8,
                                                ),
                                              ),
                                              const SizedBox(width: 3),
                                              const Text(
                                                'V',
                                                style: TextStyle(
                                                  color: Color(0xFF00E5FF),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'monospace',
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

                              // Modul 2: Ampere (Electric Amber)
                              Expanded(
                                flex: 1,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  margin: const EdgeInsets.only(left: 2),
                                  decoration: BoxDecoration(
                                    color: isFullColor ? const Color(0xFF10131F) : Colors.black,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isFullColor ? const Color(0xFFFF6B00).withOpacity(0.35) : activeColor,
                                      width: 1.0,
                                    ),
                                    boxShadow: isFullColor
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFFFF6B00).withOpacity(0.08),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(Icons.waves, color: Color(0xFFFF6B00), size: 11),
                                              SizedBox(width: 3),
                                              Text(
                                                'CURRENT',
                                                style: TextStyle(
                                                  color: Color(0xFFFF6B00),
                                                  fontSize: 8.0,
                                                  fontWeight: FontWeight.w900,
                                                  fontFamily: 'monospace',
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            '${displaymA.toStringAsFixed(0)}mA',
                                            style: const TextStyle(
                                              color: Color(0xFFFF9E59),
                                              fontSize: 7.5,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      Center(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.baseline,
                                            textBaseline: TextBaseline.alphabetic,
                                            children: [
                                              Text(
                                                liveAmp.toStringAsFixed(3),
                                                style: const TextStyle(
                                                  color: Color(0xFFFF6B00),
                                                  fontSize: 36,
                                                  fontWeight: FontWeight.w900,
                                                  fontFamily: 'monospace',
                                                  letterSpacing: 0.8,
                                                ),
                                              ),
                                              const SizedBox(width: 3),
                                              const Text(
                                                'A',
                                                style: TextStyle(
                                                  color: Color(0xFFFF6B00),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'monospace',
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
                        const SizedBox(height: 3),

                        // Baris 2: Charging Data (USB PD/QC Data)
                        Expanded(
                          flex: 5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                            decoration: BoxDecoration(
                              color: isFullColor ? const Color(0xFF10131F) : Colors.black,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isFullColor ? const Color(0xFFFFEA00).withOpacity(0.3) : activeColor,
                                width: 1.0,
                              ),
                              boxShadow: isFullColor
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFFFEA00).withOpacity(0.06),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              children: [
                                // Header: Title + Badge PD/QC
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.usb,
                                          color: isFullColor ? const Color(0xFF00FF88) : Colors.white70,
                                          size: 11,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          'CHARGING DATA',
                                          style: TextStyle(
                                            color: isFullColor ? const Color(0xFF00FF88) : Colors.white70,
                                            fontSize: 7.8,
                                            fontWeight: FontWeight.w900,
                                            fontFamily: 'monospace',
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: isFullColor
                                            ? const Color(0xFF7928CA).withOpacity(0.25)
                                            : activeColor.withOpacity(0.15),
                                        border: Border.all(
                                          color: isFullColor
                                              ? const Color(0xFFC084FC).withOpacity(0.7)
                                              : activeColor.withOpacity(0.6),
                                          width: 0.6,
                                        ),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: const Text(
                                        'QC/PD FAST',
                                        style: TextStyle(
                                          color: Color(0xFFE9D5FF),
                                          fontSize: 6.8,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),

                                // Nilai Metrik: V, A, W
                                Expanded(
                                  child: Row(
                                    children: [
                                      // VOLT MINI BOX
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: isFullColor ? const Color(0xFF141A2E) : Colors.white.withOpacity(0.06),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: isFullColor ? const Color(0xFF00E5FF).withOpacity(0.25) : Colors.white12,
                                              width: 0.6,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.baseline,
                                              textBaseline: TextBaseline.alphabetic,
                                              children: [
                                                Text(
                                                  displayVolt.toStringAsFixed(2),
                                                  style: const TextStyle(
                                                    color: Color(0xFF00E5FF),
                                                    fontSize: 34,
                                                    fontWeight: FontWeight.w900,
                                                    fontFamily: 'monospace',
                                                  ),
                                                ),
                                                const SizedBox(width: 2),
                                                const Text(
                                                  'V',
                                                  style: TextStyle(
                                                    color: Color(0xFF00E5FF),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'monospace',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 3),

                                      // AMP MINI BOX
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: isFullColor ? const Color(0xFF141A2E) : Colors.white.withOpacity(0.06),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: isFullColor ? const Color(0xFFFF6B00).withOpacity(0.25) : Colors.white12,
                                              width: 0.6,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.baseline,
                                              textBaseline: TextBaseline.alphabetic,
                                              children: [
                                                Text(
                                                  liveAmp.toStringAsFixed(3),
                                                  style: const TextStyle(
                                                    color: Color(0xFFFF6B00),
                                                    fontSize: 34,
                                                    fontWeight: FontWeight.w900,
                                                    fontFamily: 'monospace',
                                                  ),
                                                ),
                                                const SizedBox(width: 2),
                                                const Text(
                                                  'A',
                                                  style: TextStyle(
                                                    color: Color(0xFFFF6B00),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'monospace',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 3),

                                      // WATT MINI BOX
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: isFullColor ? const Color(0xFF141A2E) : Colors.white.withOpacity(0.06),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: isFullColor ? const Color(0xFFFFEA00).withOpacity(0.25) : Colors.white12,
                                              width: 0.6,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.baseline,
                                              textBaseline: TextBaseline.alphabetic,
                                              children: [
                                                Text(
                                                  displayWatt.toStringAsFixed(2),
                                                  style: const TextStyle(
                                                    color: Color(0xFFFFEA00),
                                                    fontSize: 34,
                                                    fontWeight: FontWeight.w900,
                                                    fontFamily: 'monospace',
                                                  ),
                                                ),
                                                const SizedBox(width: 2),
                                                const Text(
                                                  'W',
                                                  style: TextStyle(
                                                    color: Color(0xFFFFEA00),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'monospace',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 3),

                                // Data Lines (CC1, CC2, D+, D-) Box Modern
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildDataPinPill('CC1', '0.00V', isFullColor),
                                    _buildDataPinPill('CC2', '0.00V', isFullColor),
                                    _buildDataPinPill('D+', '0.00V', isFullColor),
                                    _buildDataPinPill('D-', '0.00V', isFullColor),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ----------------------------------------
          // BAGIAN BAWAH: DUAL AXIS CURVE AMMETER GRAPH (VOLT KIRI & mA KANAN)
          // ----------------------------------------
          Expanded(
            flex: 12,
            child: Container(
              margin: const EdgeInsets.fromLTRB(4, 2, 4, 4),
              decoration: BoxDecoration(
                color: isFullColor ? const Color(0xFF0C101D) : Colors.black,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isFullColor ? const Color(0xFF1E3A8A).withOpacity(0.5) : activeColor,
                  width: 1.0,
                ),
                boxShadow: isFullColor
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  // Toolbar Header dengan Tombol ARUS (Kiri) dan VOLT (Kanan)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
                    ),
                    child: Row(
                      children: [
                        // Tombol Toggle ARUS (Sisi Kiri, Oranye/Kuning Neon)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showArus = !_showArus;
                              if (!_showArus && !_showVolt) _showVolt = true;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _showArus ? const Color(0xFFFF6B00).withOpacity(0.2) : Colors.transparent,
                              border: Border.all(
                                color: _showArus ? const Color(0xFFFF6B00) : Colors.white24,
                                width: 0.8,
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.show_chart, color: _showArus ? const Color(0xFFFF6B00) : Colors.white54, size: 10),
                                const SizedBox(width: 4),
                                Text(
                                  'ARUS (A)',
                                  style: TextStyle(
                                    color: _showArus ? const Color(0xFFFF6B00) : Colors.white54,
                                    fontSize: 8.0,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Judul Tengah: Status Ringkasan
                        Expanded(
                          child: Center(
                            child: Text(
                              'CURVE AMMETER / VOLTMETER (REALTIME)',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 7.5,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Tombol Toggle VOLT (Sisi Kanan, Electric Cyan)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showVolt = !_showVolt;
                              if (!_showVolt && !_showArus) _showArus = true;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _showVolt ? const Color(0xFF00E5FF).withOpacity(0.2) : Colors.transparent,
                              border: Border.all(
                                color: _showVolt ? const Color(0xFF00E5FF) : Colors.white24,
                                width: 0.8,
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'VOLT (V)',
                                  style: TextStyle(
                                    color: _showVolt ? const Color(0xFF00E5FF) : Colors.white54,
                                    fontSize: 8.0,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.bolt, color: _showVolt ? const Color(0xFF00E5FF) : Colors.white54, size: 10),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Area Dual-Axis Plot (Sumbu Kiri = ARUS, Sumbu Kanan = VOLT)
                  Expanded(
                    child: Row(
                      children: [
                        // Sumbu Kiri: ARUS (11 Tick presisi 1.0 -> 0.0)
                        _buildDynamicYAxisLabels(
                          isRight: false,
                          maxValue: (safeAmp <= 1.0) ? 1.0 : (safeAmp <= 2.0 ? 2.0 : (safeAmp * 2).ceil() / 2.0),
                          unit: 'A',
                          color: _showArus ? const Color(0xFFFF6B00) : const Color(0xFF475569),
                        ),

                        // Plot Wave Canvas (Real-time live buffer stream dari ESP8266)
                        Expanded(
                          child: ClipRect(
                            child: ValueListenableBuilder<int>(
                              valueListenable: PsuUdpService.instance.waveTickNotifier,
                              builder: (context, _, __) {
                                return CustomPaint(
                                  size: Size.infinite,
                                  painter: DarkCurveGraphPainter(
                                    showArus: _showArus,
                                    showVolt: _showVolt,
                                    liveVolt: displayVolt,
                                    liveAmp: safeAmp,
                                    activeColor: activeColor,
                                    ampHistory: PsuUdpService.instance.ampHistory,
                                    voltHistory: PsuUdpService.instance.voltHistory,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        // Sumbu Kanan: VOLT (11 Tick presisi 1.0 -> 0.0)
                        _buildDynamicYAxisLabels(
                          isRight: true,
                          maxValue: (displayVolt <= 6.0) ? 6.0 : (displayVolt <= 10.0 ? 10.0 : (displayVolt <= 15.0 ? 15.0 : 30.0)),
                          unit: 'V',
                          color: _showVolt ? const Color(0xFF00E5FF) : const Color(0xFF475569),
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
    );
  }

  Widget _buildDynamicYAxisLabels({
    required bool isRight,
    required double maxValue,
    required String unit,
    required Color color,
  }) {
    final ticks = [1.0, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1, 0.0];

    return Container(
      width: 36,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: ticks.map((factor) {
          final val = maxValue * factor;
          String label;
          if (unit == 'A') {
            final int mA = (val * 1000).round();
            if (mA >= 1000) {
              final double a = mA / 1000.0;
              label = a == a.roundToDouble() ? '${a.toInt()}A' : '${a.toStringAsFixed(1)}A';
            } else {
              label = '${mA}m';
            }
          } else {
            label = val == val.roundToDouble() ? '${val.toInt()}V' : '${val.toStringAsFixed(1)}V';
          }

          final tickLine = Container(
            width: 4,
            height: 1,
            color: color.withOpacity(0.85),
          );

          return Expanded(
            child: Row(
              mainAxisAlignment: isRight ? MainAxisAlignment.start : MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isRight) tickLine,
                if (isRight) const SizedBox(width: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 6.8,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
                if (!isRight) const SizedBox(width: 2),
                if (!isRight) tickLine,
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDataPinPill(String pin, String value, [bool isFullColor = true]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: isFullColor ? const Color(0xFF141A2E) : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: isFullColor ? const Color(0xFF38BDF8).withOpacity(0.25) : Colors.white12,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$pin: ',
            style: TextStyle(
              color: isFullColor ? const Color(0xFF38BDF8).withOpacity(0.8) : Colors.white38,
              fontSize: 6.8,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isFullColor ? const Color(0xFFE2E8F0) : Colors.white70,
              fontSize: 6.8,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Painter: Dark Dial Gauge 0 - 500 mA (Persis Script SVG HTML User)
/// Menggunakan matematika polar-to-cartesian persis:
/// cx = width/2, cy = height * 1.4137, startAngle = -46°, endAngle = 46°
/// rArc = 295/290 * height, rTickMinor = 303, rTickMid = 309, rTickMajor = 317, rText = 342
class DarkAmmeterGaugePainter extends CustomPainter {
  final double currentmA;
  final double maxScale;

  const DarkAmmeterGaugePainter({
    required this.currentmA,
    this.maxScale = 500.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final double targetWidth = size.width * 0.90;
    final double scale = targetWidth / 495.0;

    final double cx = size.width / 2.0;

    final double rArc = 295.0 * scale;
    final double rTickStart = 295.0 * scale;
    final double rTickMinorEnd = 303.0 * scale;
    final double rTickMidEnd = 309.0 * scale;
    final double rTickMajorEnd = 317.0 * scale;
    final double rText = 344.0 * scale;

    // Kunci posisi teks teratas: pas tepat di bawah garis panel header (margin 18px)
    final double cy = rText + 18.0;

    const double startAngle = -46.0;
    const double endAngle = 46.0;
    const double totalRange = endAngle - startAngle;

    // Helper: Polar to Cartesian (0 derajat di atas, searah jarum jam)
    Offset polarToCartesian(double centerX, double centerY, double radius, double angleInDegrees) {
      final double angleInRadians = (angleInDegrees - 90.0) * math.pi / 180.0;
      return Offset(
        centerX + (radius * math.cos(angleInRadians)),
        centerY + (radius * math.sin(angleInRadians)),
      );
    }

    // 1. Menggambar Garis Busur Utama (Arc)
    final double startRad = (startAngle - 90.0) * math.pi / 180.0;
    final double sweepRad = totalRange * math.pi / 180.0;

    final arcPaint = Paint()
      ..color = const Color(0xFFD4D4D4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * scale
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: rArc),
      startRad,
      sweepRad,
      false,
      arcPaint,
    );

    // 2. Menggambar Garis Ukur (Ticks) dan Angka Skala Dinamis (5 divisi utama)
    const int totalDivisions = 5;
    const int ticksPerDivision = 10;
    const int totalTicks = totalDivisions * ticksPerDivision; // 50 ticks

    for (int i = 0; i <= totalTicks; i++) {
      final double angle = startAngle + (i / totalTicks) * totalRange;

      final bool isMajor = (i % ticksPerDivision == 0); // 0, 1, 2, 3, 4, 5
      final bool isMid = (i % 5 == 0 && !isMajor);

      final double rEnd = isMajor ? rTickMajorEnd : (isMid ? rTickMidEnd : rTickMinorEnd);

      final p1 = polarToCartesian(cx, cy, rTickStart, angle);
      final p2 = polarToCartesian(cx, cy, rEnd, angle);

      final tickPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = (isMajor ? 2.5 : (isMid ? 1.8 : 1.2)) * scale
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(p1, p2, tickPaint);

      // Angka Skala Utama (dinamis sesuai maxScale)
      if (isMajor) {
        final double rawVal = (i / totalTicks) * maxScale;
        String textVal;
        if (maxScale >= 1000) {
          // Format Ampere jika max >= 1000 (contoh: 0, 1, 2.. atau 0.5, 1.0)
          final double valA = rawVal / 1000.0;
          textVal = (valA == valA.roundToDouble()) ? valA.toStringAsFixed(0) : valA.toStringAsFixed(1);
        } else {
          textVal = rawVal.toInt().toString();
        }

        final pText = polarToCartesian(cx, cy, rText, angle);

        final tp = TextPainter(
          text: TextSpan(
            text: textVal,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.5 * scale,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        // Rotasi angka selaras sudut busur persis seperti di SVG
        canvas.save();
        canvas.translate(pText.dx, pText.dy);
        canvas.rotate(angle * math.pi / 180.0);
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
        canvas.restore();
      }
    }

    // 3. Menggambar Jarum (Needle)
    final double clampedValue = currentmA.clamp(0.0, maxScale);
    final double needleAngle = startAngle + (clampedValue / maxScale) * totalRange;

    // Puncak jarum menyentuh batas skala dalam (r=305)
    final pNeedleTip = polarToCartesian(cx, cy, 305.0 * scale, needleAngle);
    // Base jarum ditarik panjang dari bawah poros melewati pusat (r = -150)
    final pNeedleBase = polarToCartesian(cx, cy, -150.0 * scale, needleAngle);

    final needlePaint = Paint()
      ..color = const Color(0xFFF1F786) // Kuning neon persis HTML
      ..strokeWidth = 2.4 * scale
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(pNeedleBase, pNeedleTip, needlePaint);
  }

  @override
  bool shouldRepaint(covariant DarkAmmeterGaugePainter oldDelegate) {
    return oldDelegate.currentmA != currentmA || oldDelegate.maxScale != maxScale;
  }
}

/// Custom Painter: Plot Grid Garis Horizontal Halus serta Gelombang Volt & Arus Real-time
class DarkCurveGraphPainter extends CustomPainter {
  final bool showArus;
  final bool showVolt;
  final double liveVolt;
  final double liveAmp;
  final Color activeColor;
  final List<double>? ampHistory;
  final List<double>? voltHistory;

  const DarkCurveGraphPainter({
    this.showArus = true,
    this.showVolt = true,
    required this.liveVolt,
    required this.liveAmp,
    required this.activeColor,
    this.ampHistory,
    this.voltHistory,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // 1. Grid Horizontal selaras 1:1 tepat di tengah 11 baris sumbu Y
    final double rowHeight = size.height / 11.0;
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 0.6;

    for (int i = 0; i < 11; i++) {
      final y = (i * rowHeight) + (rowHeight / 2.0);
      final bool isCenter = i == 5;
      final linePaint = isCenter
          ? (Paint()
            ..color = const Color(0xFF1E40AF).withOpacity(0.8)
            ..strokeWidth = 1.0)
          : gridPaint;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Grid Vertikal halus
    for (int i = 0; i <= 10; i++) {
      final x = size.width * (i / 10);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    final double w = size.width;
    final double yZero = (10 * rowHeight) + (rowHeight / 2.0); // Baseline 0.0
    final double yMax = (0 * rowHeight) + (rowHeight / 2.0);   // Garis 1.0
    final double waveSpan = yZero - yMax;

    void drawRealtimeTrace(List<double> history, double maxVal, Color color) {
      if (history.isEmpty) return;
      final path = Path();
      final glowPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.6;

      final strokePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;

      final double dx = w / (history.length - 1);
      final double safeMax = maxVal > 0 ? maxVal : 1.0;

      for (int i = 0; i < history.length; i++) {
        final double x = i * dx;
        final double normalized = (history[i] / safeMax).clamp(0.0, 1.05);
        final double y = yZero - (normalized * waveSpan);

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, strokePaint);
    }

    // Gambar Gelombang ARUS (Neon Orange)
    if (showArus) {
      final double maxAmpScale = (liveAmp <= 1.0) ? 1.0 : (liveAmp <= 2.0 ? 2.0 : (liveAmp * 2).ceil() / 2.0);
      if (ampHistory != null && ampHistory!.isNotEmpty) {
        drawRealtimeTrace(ampHistory!, maxAmpScale, const Color(0xFFFF6B00));
      }
    }

    // Gambar Gelombang VOLT (Electric Cyan)
    if (showVolt) {
      final double maxVoltScale = (liveVolt <= 6.0) ? 6.0 : (liveVolt <= 10.0 ? 10.0 : (liveVolt <= 15.0 ? 15.0 : 30.0));
      if (voltHistory != null && voltHistory!.isNotEmpty) {
        drawRealtimeTrace(voltHistory!, maxVoltScale, const Color(0xFF00E5FF));
      }
    }
  }

  @override
  bool shouldRepaint(covariant DarkCurveGraphPainter oldDelegate) {
    return true;
  }
}

