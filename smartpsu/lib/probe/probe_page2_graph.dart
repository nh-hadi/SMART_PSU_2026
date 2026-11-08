import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';

class ProbePage2GraphView extends StatelessWidget {
  final Color activeColor;
  final String themeName;
  final String probeMode;
  final VoidCallback onNavigateBack;

  const ProbePage2GraphView({
    super.key,
    required this.activeColor,
    this.themeName = 'WIREFRAME',
    required this.probeMode,
    required this.onNavigateBack,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFullColor = themeName == 'FULL_COLOR';

    Color signalColor = const Color(0xFF00E5FF);
    if (probeMode == 'DIODA') signalColor = const Color(0xFFFF007F);
    if (probeMode == 'RESISTOR') signalColor = const Color(0xFFFFEA00);

    return Column(
      children: [
        // Top Toolbar
        isFullColor
            ? Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF141224),
                      Color(0xFF10131F),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: onNavigateBack,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                          ),
                          border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.5), width: 0.8),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.arrow_back_ios, size: 8, color: Color(0xFF00E5FF)),
                            SizedBox(width: 3),
                            Text(
                              'KEMBALI KE MULTIMETER',
                              style: TextStyle(
                                color: Color(0xFF00E5FF),
                                fontSize: 8,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: signalColor.withOpacity(0.18),
                        border: Border.all(color: signalColor.withOpacity(0.4), width: 0.8),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.waves, color: signalColor, size: 10),
                          const SizedBox(width: 3),
                          Text(
                            '$probeMode LOGIC PULSE',
                            style: TextStyle(
                              color: signalColor,
                              fontSize: 7.5,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFF0051FF)],
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        'OSCILLOSCOPE PROBE [I2C / SPI / CLK]',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 7.8,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w900,
                        ),
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
                    GestureDetector(
                      onTap: onNavigateBack,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white38, width: 0.8),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.arrow_back_ios, size: 8, color: Colors.white70),
                            Text(
                              'KEMBALI KE MULTIMETER',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 8,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'PROBE SIGNAL OSCILLOSCOPE [LOGIC CLK / DATA]',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
        const SizedBox(height: 4),

        // Signal Canvas Area
        Expanded(
          child: isFullColor
              ? Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0E18),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: Size.infinite,
                        painter: _ProbeSignalPainter(signalColor: signalColor),
                      ),
                      // Overlay Status Badge Kiri Atas
                      Positioned(
                        top: 8,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10131F).withOpacity(0.85),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.white12, width: 0.6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.tune, color: Color(0xFF00FF88), size: 11),
                              SizedBox(width: 4),
                              Text(
                                'REAL-TIME PROBE BUS • 100 kHz • I2C / SPI / RESET PULSE',
                                style: TextStyle(
                                  color: Color(0xFF00FF88),
                                  fontSize: 7.5,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Overlay Skala Waktu Kanan Bawah
                      Positioned(
                        bottom: 8,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10131F).withOpacity(0.85),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: Colors.white12, width: 0.5),
                          ),
                          child: Text(
                            'TIME: 10us/DIV • LEVEL: 3.3V TTL',
                            style: TextStyle(
                              color: signalColor.withOpacity(0.9),
                              fontSize: 7.2,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : AppTheme.buildPanel(
                  activeColor: activeColor,
                  child: const Center(
                    child: Text(
                      'PANEL GRAFIK SIGNAL PROBE (WAVEFORM LOGIC CLOCK / DATA PULSE)\n\n'
                      '[ Analisis Denyut Pulsa Bus I2C, SPI, Clock Crystal, & Reset Signal HP ]',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _ProbeSignalPainter extends CustomPainter {
  final Color signalColor;

  _ProbeSignalPainter({required this.signalColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Grid Garis Lab Presisi
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B).withOpacity(0.55)
      ..strokeWidth = 0.6;

    for (double x = 0; x < size.width; x += 26.0) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 22.0) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Logic square pulse / wave
    final path = Path();
    final double midY = size.height * 0.55;
    final double amp = size.height * 0.24;

    double curX = 0;
    path.moveTo(curX, midY + amp);

    while (curX < size.width) {
      final double highLen = 22.0 + (curX % 32);
      final double lowLen = 16.0 + (curX % 22);

      // Naik ke HIGH
      path.lineTo(curX, midY - amp);
      curX += highLen;
      path.lineTo(curX, midY - amp);

      // Turun ke LOW
      path.lineTo(curX, midY + amp);
      curX += lowLen;
      path.lineTo(curX, midY + amp);
    }

    // Glow Outer Neon
    final glowPaint = Paint()
      ..color = signalColor.withOpacity(0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.2;

    // Stroke Core
    final strokePaint = Paint()
      ..color = signalColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _ProbeSignalPainter oldDelegate) {
    return oldDelegate.signalColor != signalColor;
  }
}
