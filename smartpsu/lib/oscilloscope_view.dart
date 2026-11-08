import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'psu_udp_service.dart';

class OscilloscopePanelView extends StatelessWidget {
  final Color activeColor;
  final String themeName;
  final String graphMode;
  final Function(String) onGraphModeChanged;
  final double currentAmp;
  final double currentVolt;
  final double currentWatt;
  final List<double>? customAmpHistory;
  final List<double>? customVoltHistory;

  const OscilloscopePanelView({
    super.key,
    required this.activeColor,
    this.themeName = 'WIREFRAME',
    required this.graphMode,
    required this.onGraphModeChanged,
    this.currentAmp = 0.850,
    this.currentVolt = 5.120,
    this.currentWatt = 4.350,
    this.customAmpHistory,
    this.customVoltHistory,
  });

  // Cek apakah mode tertentu aktif
  bool get _isArusActive => graphMode == 'SEMUA' || graphMode.contains('ARUS');
  bool get _isVoltActive => graphMode == 'SEMUA' || graphMode.contains('VOLT');
  bool get _isDayaActive => graphMode == 'SEMUA' || graphMode.contains('DAYA');

  /// Menghitung skala maksimum arus secara dinamis (0 - 1.0A -> 1.5A -> 2.0A dst.)
  double get _dynamicMaxAmp {
    if (currentAmp <= 1.0) return 1.0;
    if (currentAmp <= 1.5) return 1.5;
    return (currentAmp * 2).ceil() / 2.0; // Naik per kelipatan 0.5A
  }

  /// Menghitung skala maksimum voltase secara dinamis (5V -> 9V -> 12V -> 20V -> 30V)
  double get _dynamicMaxVolt {
    if (currentVolt <= 5.5) return 6.0;
    if (currentVolt <= 9.5) return 10.0;
    if (currentVolt <= 12.5) return 15.0;
    if (currentVolt <= 20.5) return 24.0;
    return 30.0;
  }

  /// Menghitung skala maksimum watt secara dinamis
  double get _dynamicMaxWatt {
    if (currentWatt <= 10.0) return 15.0;
    if (currentWatt <= 25.0) return 30.0;
    if (currentWatt <= 65.0) return 70.0;
    return 100.0;
  }

  // Toggle multi-selection filter: klik untuk aktif/nonaktif tanpa menghapus pilihan lain
  void _toggleMode(String key) {
    HapticFeedback.selectionClick();

    if (key == 'SEMUA') {
      if (graphMode == 'SEMUA' || (_isArusActive && _isVoltActive && _isDayaActive)) {
        onGraphModeChanged('ARUS'); // default kembali ke ARUS jika di-uncheck
      } else {
        onGraphModeChanged('SEMUA');
      }
      return;
    }

    bool arus = _isArusActive;
    bool volt = _isVoltActive;
    bool daya = _isDayaActive;

    if (key == 'ARUS') arus = !arus;
    if (key == 'VOLTASE') volt = !volt;
    if (key == 'DAYA') daya = !daya;

    // Minimal 1 gelombang harus aktif
    if (!arus && !volt && !daya) {
      if (key == 'ARUS') arus = true;
      if (key == 'VOLTASE') volt = true;
      if (key == 'DAYA') daya = true;
    }

    if (arus && volt && daya) {
      onGraphModeChanged('SEMUA');
    } else {
      final List<String> activeList = [];
      if (arus) activeList.add('ARUS');
      if (volt) activeList.add('VOLTASE');
      if (daya) activeList.add('DAYA');
      onGraphModeChanged(activeList.join('+'));
    }
  }

  Widget _buildGraphFilterButton(String modeKey) {
    bool isSelected;
    Color filterColor;

    switch (modeKey) {
      case 'VOLTASE':
        isSelected = _isVoltActive;
        filterColor = const Color(0xFF00E5FF); // Electric Cyan
        break;
      case 'DAYA':
        isSelected = _isDayaActive;
        filterColor = const Color(0xFFFFEA00); // Neon Yellow
        break;
      case 'SEMUA':
        isSelected = _isArusActive && _isVoltActive && _isDayaActive;
        filterColor = const Color(0xFFA855F7); // Neon Purple
        break;
      case 'ARUS':
      default:
        isSelected = _isArusActive;
        filterColor = const Color(0xFFFF6B00); // Vivid Electric Amber / Neon Orange
        break;
    }

    final bool isFullColor = themeName == 'FULL_COLOR';

    if (isFullColor) {
      return GestureDetector(
        onTap: () => _toggleMode(modeKey),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
          decoration: BoxDecoration(
            color: isSelected ? filterColor.withOpacity(0.18) : const Color(0xFF131826),
            borderRadius: BorderRadius.circular(4),
            border: isSelected ? Border.all(color: filterColor.withOpacity(0.5), width: 0.9) : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: filterColor.withOpacity(0.35),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: isSelected ? filterColor : const Color(0xFF475569),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                modeKey,
                style: TextStyle(
                  color: isSelected ? filterColor : const Color(0xFF64748B),
                  fontSize: 8.5,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _toggleMode(modeKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.18) : Colors.transparent,
          border: Border.all(
            color: isSelected ? activeColor : Colors.white24,
            width: isSelected ? 1.2 : 0.8,
          ),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          modeKey,
          style: TextStyle(
            color: isSelected ? activeColor : Colors.white60,
            fontSize: 8.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }

  /// Membuat label angka sumbu Y beresolusi tinggi (11 Tick Lengkap: 100% -> 0%)
  Widget _buildYAxisLabels({
    required bool isRight,
    required double maxValue,
    required String unit,
    required Color color,
  }) {
    // 11 Tick Lengkap (1.0, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1, 0.0)
    final ticks = [1.0, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1, 0.0];

    return Container(
      width: 40,
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
          } else if (unit == 'V') {
            final double v = val;
            label = v == v.roundToDouble() ? '${v.toInt()}V' : '${v.toStringAsFixed(1)}V';
          } else {
            final double w = val;
            label = w == w.roundToDouble() ? '${w.toInt()}W' : '${w.toStringAsFixed(1)}W';
          }

          final tickLine = Container(
            width: 5,
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
                    fontSize: 7.0,
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

  @override
  Widget build(BuildContext context) {
    final bool isFullColor = themeName == 'FULL_COLOR';
    final double maxAmp = _dynamicMaxAmp;
    final double maxVolt = _dynamicMaxVolt;
    final double maxWatt = _dynamicMaxWatt;

    final bool showArus = _isArusActive;
    final bool showVolt = _isVoltActive;
    final bool showDaya = _isDayaActive;

    // Tentukan label sumbu kanan: jika Volt aktif -> tampilkan Volt (Cyan), jika tidak dan Daya aktif -> Watt (Yellow)
    final bool rightIsVolt = showVolt || !showDaya;
    final double rightMax = rightIsVolt ? maxVolt : maxWatt;
    final String rightUnit = rightIsVolt ? 'V' : 'W';
    final Color rightColor = rightIsVolt ? const Color(0xFF00E5FF).withOpacity(0.85) : const Color(0xFFFFEA00).withOpacity(0.85);

    // Kiri selalu untuk Arus jika Arus aktif, atau fallback abu-abu
    final Color leftColor = showArus ? const Color(0xFFFF6B00).withOpacity(0.9) : const Color(0xFF475569);

    return Column(
      children: [
        // Toolbar Waveform Multi-Selection
        isFullColor
            ? Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10131F),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    _buildGraphFilterButton('ARUS'),
                    const SizedBox(width: 4),
                    _buildGraphFilterButton('VOLTASE'),
                    const SizedBox(width: 4),
                    _buildGraphFilterButton('DAYA'),
                    const SizedBox(width: 4),
                    _buildGraphFilterButton('SEMUA'),
                    const Spacer(),
                    // Badge Sumbu Kiri (Ampere)
                    if (showArus)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B00).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'A: 0-${maxAmp.toStringAsFixed(1)}A',
                          style: const TextStyle(
                            color: Color(0xFFFF6B00),
                            fontSize: 7.5,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                    // Badge Sumbu Kanan (Volt / Watt)
                    if (showVolt)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'V: 0-${maxVolt.toStringAsFixed(0)}V',
                          style: const TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 7.5,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FF88).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.bolt, color: Color(0xFF00FF88), size: 10),
                          SizedBox(width: 2),
                          Text(
                            '200Hz',
                            style: TextStyle(
                              color: Color(0xFF00FF88),
                              fontSize: 7.2,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : AppTheme.buildPanel(
                height: 32,
                activeColor: activeColor,
                child: Row(
                  children: [
                    _buildGraphFilterButton('ARUS'),
                    const SizedBox(width: 4),
                    _buildGraphFilterButton('VOLTASE'),
                    const SizedBox(width: 4),
                    _buildGraphFilterButton('DAYA'),
                    const SizedBox(width: 4),
                    _buildGraphFilterButton('SEMUA'),
                    const Spacer(),
                    Text(
                      '[0-${maxAmp.toStringAsFixed(1)}A / 200Hz]',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 8,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
        const SizedBox(height: 4),

        // Canvas Area (Grid Osiloskop dengan Sumbu Y Kiri & Kanan Berbeda)
        Expanded(
          child: isFullColor
              ? Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0E18),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Row(
                    children: [
                      // Sumbu Y Sisi Kiri: Skala Arus Ampere (Neon Rose)
                      _buildYAxisLabels(
                        isRight: false,
                        maxValue: maxAmp,
                        unit: 'A',
                        color: leftColor,
                      ),

                      // Area Grid & Gelombang Riil (Real-Time Stream via Ring Buffer)
                      Expanded(
                        child: ValueListenableBuilder<int>(
                          valueListenable: PsuUdpService.instance.waveTickNotifier,
                          builder: (context, _, __) {
                            return CustomPaint(
                              size: Size.infinite,
                              painter: _OscilloscopeWaveformPainter(
                                showArus: showArus,
                                showVolt: showVolt,
                                showDaya: showDaya,
                                maxAmp: maxAmp,
                                currentAmp: currentAmp,
                                maxVolt: maxVolt,
                                currentVolt: currentVolt,
                                maxWatt: maxWatt,
                                currentWatt: currentWatt,
                                ampHistory: customAmpHistory ?? PsuUdpService.instance.ampHistory,
                                voltHistory: customVoltHistory ?? PsuUdpService.instance.voltHistory,
                              ),
                            );
                          },
                        ),
                      ),

                      // Sumbu Y Sisi Kanan: Skala Voltase / Watt (Cyan / Yellow)
                      _buildYAxisLabels(
                        isRight: true,
                        maxValue: rightMax,
                        unit: rightUnit,
                        color: rightColor,
                      ),
                    ],
                  ),
                )
              : AppTheme.buildPanel(
                  activeColor: activeColor,
                  child: Row(
                    children: [
                      _buildYAxisLabels(
                        isRight: false,
                        maxValue: maxAmp,
                        unit: 'A',
                        color: Colors.white70,
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'PANEL 3: GRAFIK OSCILLOSCOPE\n'
                            '[Multi-Channel Live Stream]',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      _buildYAxisLabels(
                        isRight: true,
                        maxValue: rightMax,
                        unit: rightUnit,
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _OscilloscopeWaveformPainter extends CustomPainter {
  final bool showArus;
  final bool showVolt;
  final bool showDaya;
  final double maxAmp;
  final double currentAmp;
  final double maxVolt;
  final double currentVolt;
  final double maxWatt;
  final double currentWatt;
  final List<double>? ampHistory;
  final List<double>? voltHistory;

  const _OscilloscopeWaveformPainter({
    required this.showArus,
    required this.showVolt,
    required this.showDaya,
    required this.maxAmp,
    required this.currentAmp,
    required this.maxVolt,
    required this.currentVolt,
    required this.maxWatt,
    required this.currentWatt,
    this.ampHistory,
    this.voltHistory,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // 1. Gambar Grid Garis Lab
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B).withOpacity(0.55)
      ..strokeWidth = 0.6;

    const double stepX = 26.0;
    for (double x = 0; x < size.width; x += stepX) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Garis Grid Horizontal selaras 1:1 tepat di tengah setiap baris Expanded sumbu Y (11 baris)
    final double rowHeight = size.height / 11.0;
    for (int i = 0; i < 11; i++) {
      final y = (i * rowHeight) + (rowHeight / 2.0);
      final bool isCenter = i == 5;
      final linePaint = isCenter
          ? (Paint()
            ..color = const Color(0xFF64748B).withOpacity(0.85)
            ..strokeWidth = 1.0)
          : (Paint()
            ..color = const Color(0xFF334155).withOpacity(0.5)
            ..strokeWidth = 0.6);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final double w = size.width;

    // Titik pusat Y untuk tick 0.0 (baris terbawah) dan tick 1.0 (baris teratas)
    final double yZero = (10 * rowHeight) + (rowHeight / 2.0); // Baseline 0.0
    final double yMax = (0 * rowHeight) + (rowHeight / 2.0);   // Garis 1.0 (Puncak)
    final double waveSpan = yZero - yMax; // Tinggi rentang gelombang dari 0.0 ke 1.0

    // Fungsi pembantu menggambar stream data historis nyata selaras dengan garis grid
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

    // 1. Gambar Gelombang Arus Riil
    if (showArus) {
      if (ampHistory != null && ampHistory!.isNotEmpty) {
        drawRealtimeTrace(
          ampHistory!,
          maxAmp,
          const Color(0xFFFF6B00), // Vivid Electric Amber / Neon Orange
        );
      }
    }

    // 2. Gambar Gelombang Voltase Riil
    if (showVolt) {
      if (voltHistory != null && voltHistory!.isNotEmpty) {
        drawRealtimeTrace(
          voltHistory!,
          maxVolt,
          const Color(0xFF00E5FF), // Electric Cyan
        );
      }
    }

    // 3. Gambar Gelombang Daya Riil (V * I)
    if (showDaya) {
      if (voltHistory != null && ampHistory != null) {
        final List<double> wattHistory = [];
        final int len = math.min(voltHistory!.length, ampHistory!.length);
        for (int i = 0; i < len; i++) {
          wattHistory.add(voltHistory![i] * ampHistory![i]);
        }
        drawRealtimeTrace(
          wattHistory,
          maxWatt,
          const Color(0xFFFFEA00), // Electric Yellow
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OscilloscopeWaveformPainter oldDelegate) {
    return true; // Re-paint saat tick buffer masuk via ValueListenableBuilder
  }
}
