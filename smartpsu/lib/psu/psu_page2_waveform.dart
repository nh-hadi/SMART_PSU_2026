import 'dart:math' as math;
import 'package:flutter/material.dart';

class PsuPage2WaveformView extends StatelessWidget {
  final Color activeColor;
  final double liveVolt;
  final double liveAmp;
  final double ocpLimit;
  final VoidCallback? onBack;

  const PsuPage2WaveformView({
    super.key,
    required this.activeColor,
    required this.liveVolt,
    required this.liveAmp,
    required this.ocpLimit,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final double displayAmp = liveAmp > 0 ? liveAmp : 1.250;
    final double displayVolt = liveVolt > 0 ? liveVolt : 4.29;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: activeColor.withOpacity(0.4), width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ----------------------------------------
          // BAGIAN ATAS (PUTIH): ANALOG GAUGE 0 - 2A + 7-SEG DISPLAY
          // ----------------------------------------
          Expanded(
            flex: 10,
            child: Stack(
              children: [
                // 1. Lampu Indikator Hijau (Kiri Atas)
                Positioned(
                  top: 8,
                  left: 12,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF22C55E).withOpacity(0.4),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Icon Gembok Terkunci (Kanan Atas) + Tombol Kembali
                Positioned(
                  top: 8,
                  right: 12,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: onBack,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.black87, size: 14),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.lock, color: Colors.black87, size: 18),
                    ],
                  ),
                ),

                // 3. Canvas Busur Skala Analog Putih (0 s/d 2A) & Jarum Merah
                Positioned.fill(
                  child: CustomPaint(
                    painter: WaveformSampWhiteGaugePainter(
                      currentAmp: displayAmp,
                    ),
                  ),
                ),

                // 4. Dua Box Nilai Tengah: [4.29] V  [5.00] A
                Positioned(
                  top: 50,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Box Volt [ 4.29 ]
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          displayVolt.toStringAsFixed(2),
                          style: const TextStyle(
                            color: Color(0xFF4ADE80),
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'V',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Box OCP [ 5.00 ]
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          ocpLimit > 0 ? ocpLimit.toStringAsFixed(2) : '5.00',
                          style: const TextStyle(
                            color: Color(0xFFFACC15),
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'A',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              ],
            ),
          ),

          // ----------------------------------------
          // BAGIAN BAWAH (HITAM): DUAL WAVEFORM (VOLT HIJAU KOTAK & CURR KUNING LOGIC)
          // ----------------------------------------
          Expanded(
            flex: 12,
            child: Container(
              color: Colors.black,
              child: Stack(
                children: [
                  // Label Header: VOLT O (Hijau) & O CURR (Kuning)
                  Positioned(
                    top: 2,
                    left: 50,
                    right: 50,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Text(
                              'VOLT',
                              style: TextStyle(
                                color: Color(0xFF39FF14),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                            SizedBox(width: 3),
                            Icon(Icons.circle_outlined, color: Color(0xFF39FF14), size: 9),
                          ],
                        ),
                        Row(
                          children: const [
                            Icon(Icons.circle_outlined, color: Color(0xFFFFEB3B), size: 9),
                            SizedBox(width: 3),
                            Text(
                              'CURR',
                              style: TextStyle(
                                color: Color(0xFFFFEB3B),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Sumbu Skala Voltase Kiri (10.00, 8.00, 6.00, 4.00, 2.00, 0.00)
                  Positioned(
                    top: 14,
                    bottom: 4,
                    left: 4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('10.00', style: TextStyle(color: Color(0xFF39FF14), fontSize: 9, fontFamily: 'monospace')),
                        Text('8.00', style: TextStyle(color: Color(0xFF39FF14), fontSize: 9, fontFamily: 'monospace')),
                        Text('6.00', style: TextStyle(color: Color(0xFF39FF14), fontSize: 9, fontFamily: 'monospace')),
                        Text('4.00', style: TextStyle(color: Color(0xFF39FF14), fontSize: 9, fontFamily: 'monospace')),
                        Text('2.00', style: TextStyle(color: Color(0xFF39FF14), fontSize: 9, fontFamily: 'monospace')),
                        Text('0.00', style: TextStyle(color: Color(0xFF39FF14), fontSize: 9, fontFamily: 'monospace')),
                      ],
                    ),
                  ),

                  // Sumbu Skala Arus Kanan (.005, .004, .003, .002, .001, .000)
                  Positioned(
                    top: 14,
                    bottom: 4,
                    right: 4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [
                        Text('.005', style: TextStyle(color: Color(0xFFFFEB3B), fontSize: 9, fontFamily: 'monospace')),
                        Text('.004', style: TextStyle(color: Color(0xFFFFEB3B), fontSize: 9, fontFamily: 'monospace')),
                        Text('.003', style: TextStyle(color: Color(0xFFFFEB3B), fontSize: 9, fontFamily: 'monospace')),
                        Text('.002', style: TextStyle(color: Color(0xFFFFEB3B), fontSize: 9, fontFamily: 'monospace')),
                        Text('.001', style: TextStyle(color: Color(0xFFFFEB3B), fontSize: 9, fontFamily: 'monospace')),
                        Text('.000', style: TextStyle(color: Color(0xFFFFEB3B), fontSize: 9, fontFamily: 'monospace')),
                      ],
                    ),
                  ),

                  // Custom Painter: Dual Waveform Logic persis gambar
                  Positioned.fill(
                    left: 36,
                    right: 36,
                    top: 14,
                    bottom: 6,
                    child: CustomPaint(
                      painter: WaveformSampLogicPainter(),
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
}

/// Custom Painter: White Dial Gauge 0 - 2A persis seperti di gambar user
/// Skala: 0, 0.25, 0.5, 0.75, 1 (Merah), 1.25, 1.5, 1.75, 2 (Merah)
class WaveformSampWhiteGaugePainter extends CustomPainter {
  final double currentAmp;

  const WaveformSampWhiteGaugePainter({
    required this.currentAmp,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Di Halaman 3, meter analog hanya menempati kolom kiri (sekitar 45% lebar layar)
    // Di Halaman 2, agar persis sama dengan Halaman 3, targetWidth diambil ~45% dari size.width
    final double targetWidth = size.width * 0.45;
    final double scale = targetWidth / 495.0;

    final double cx = size.width / 2.0;

    final double rArc = 295.0 * scale;
    final double rTickStart = 295.0 * scale;
    final double rTickMinorEnd = 303.0 * scale;
    final double rTickMidEnd = 309.0 * scale;
    final double rTickMajorEnd = 317.0 * scale;
    final double rText = 344.0 * scale;

    // Batas atas angka di bawah panel header (margin 18px), persis halaman 3
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
      ..color = const Color(0xFF1E293B)
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

    // 2. Skala Ticks (0 s/d 2.0A) - 40 divisi (setiap 0.05A)
    const int totalDivisions = 40;
    const double maxScale = 2.0;

    for (int i = 0; i <= totalDivisions; i++) {
      final double angle = startAngle + (i / totalDivisions) * totalRange;

      final bool isMajor = (i % 10 == 0); // 0, 0.5, 1.0, 1.5, 2.0
      final bool isMid = (i % 5 == 0 && !isMajor); // 0.25, 0.75, 1.25, 1.75
      final bool isRedTick = (i == 0 || i == 20 || i == 40); // 0, 1, 2 aksen merah

      final double rEnd = isMajor ? rTickMajorEnd : (isMid ? rTickMidEnd : rTickMinorEnd);

      final p1 = polarToCartesian(cx, cy, rTickStart, angle);
      final p2 = polarToCartesian(cx, cy, rEnd, angle);

      final tickPaint = Paint()
        ..color = isRedTick
            ? const Color(0xFFDC2626)
            : (isMajor ? const Color(0xFF0F172A) : const Color(0xFF475569))
        ..strokeWidth = (isMajor ? 2.5 : (isMid ? 1.8 : 1.2)) * scale
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(p1, p2, tickPaint);

      // Angka Skala Lengkap: 0, 0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2
      if (isMajor || isMid) {
        final double val = (i / totalDivisions) * maxScale;
        String labelText;
        if (val == 0.0) {
          labelText = '0';
        } else if (val == 1.0) {
          labelText = '1';
        } else if (val == 2.0) {
          labelText = '2';
        } else if (val == 0.5) {
          labelText = '0.5';
        } else if (val == 1.5) {
          labelText = '1.5';
        } else {
          labelText = val.toStringAsFixed(2);
        }

        final pText = polarToCartesian(cx, cy, rText, angle);

        final tp = TextPainter(
          text: TextSpan(
            text: labelText,
            style: TextStyle(
              color: isRedTick ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
              fontSize: (isMajor ? 16.5 : 11.5) * scale,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        // Rotasi angka selaras sudut busur persis seperti di SVG Halaman 3
        canvas.save();
        canvas.translate(pText.dx, pText.dy);
        canvas.rotate(angle * math.pi / 180.0);
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
        canvas.restore();
      }
    }

    // Label Unit Ampere di atas poros jarum
    final unitTp = TextPainter(
      text: TextSpan(
        text: 'AMPERE (MAX 2.0A)',
        style: TextStyle(
          color: const Color(0xFF64748B),
          fontSize: 10.0 * scale,
          letterSpacing: 1.0,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    unitTp.paint(canvas, Offset(cx - (unitTp.width / 2), cy - (rArc * 0.45)));

    // 3. Menggambar Jarum (Needle) dengan Ekor/Titik Bawah Over ke Bawah
    final double clampedCurrent = currentAmp.clamp(0.0, maxScale);
    final double needleAngle = startAngle + (clampedCurrent / maxScale) * totalRange;

    // Puncak jarum menyentuh batas skala dalam (r=305)
    final pNeedleTip = polarToCartesian(cx, cy, 305.0 * scale, needleAngle);
    // Base jarum ditarik panjang dari bawah poros melewati pusat (r = -150) agar over menembus ke bawah di belakang panel
    final pNeedleBase = polarToCartesian(cx, cy, -150.0 * scale, needleAngle);

    // Garis Utama Jarum Merah Tebal
    final needlePaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 2.4 * scale
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(pNeedleBase, pNeedleTip, needlePaint);

    // Titik Indikator Merah Menyala di Dekat Ujung Jarum
    final pDot = polarToCartesian(cx, cy, 260.0 * scale, needleAngle);
    canvas.drawCircle(pDot, 5.0 * scale, Paint()..color = const Color(0xFFFF0033));
    canvas.drawCircle(pDot, 2.5 * scale, Paint()..color = Colors.white.withOpacity(0.9));
  }

  @override
  bool shouldRepaint(covariant WaveformSampWhiteGaugePainter oldDelegate) {
    return oldDelegate.currentAmp != currentAmp;
  }
}

/// Custom Painter: Dual Waveform Logic (Volt Hijau Kotak di Atas & Curr Kuning di Bawah)
class WaveformSampLogicPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Garis Grid Horizontal Tipis
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 0.8;

    for (int i = 0; i <= 5; i++) {
      final y = size.height * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 1. Sinyal Atas: VOLT HIJAU (Gelombang Kotak Clock Rapat Simetris)
    final voltPath = Path();
    final double voltTopY = size.height * 0.08;
    final double voltBottomY = size.height * 0.44;
    const int voltCycles = 15;
    final double stepX = size.width / (voltCycles * 2);

    voltPath.moveTo(0, voltBottomY);
    for (int i = 0; i < voltCycles; i++) {
      final x1 = i * 2 * stepX;
      final x2 = x1 + stepX;
      final x3 = x2 + stepX;

      voltPath.lineTo(x1, voltTopY);
      voltPath.lineTo(x2, voltTopY);
      voltPath.lineTo(x2, voltBottomY);
      voltPath.lineTo(x3, voltBottomY);
    }

    final voltPaint = Paint()
      ..color = const Color(0xFF39FF14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(voltPath, voltPaint);

    // 2. Sinyal Bawah: CURR KUNING (Gelombang Pulsa Data Asimetris)
    final currPath = Path();
    final double currTopY = size.height * 0.52;
    final double currBottomY = size.height * 0.90;

    currPath.moveTo(0, currBottomY);

    // Pola Pulsa Data
    final pulses = [
      {'high': true, 'w': 0.22},
      {'high': false, 'w': 0.04},
      {'high': true, 'w': 0.05},
      {'high': false, 'w': 0.32},
      {'high': true, 'w': 0.15},
      {'high': false, 'w': 0.12},
      {'high': true, 'w': 0.10},
    ];

    double currentX = 0;
    for (final p in pulses) {
      final bool isHigh = p['high'] as bool;
      final double widthFrac = p['w'] as double;
      final double pulseWidth = size.width * widthFrac;
      final double targetY = isHigh ? currTopY : currBottomY;

      currPath.lineTo(currentX, targetY);
      currentX += pulseWidth;
      currPath.lineTo(currentX, targetY);
    }

    final currPaint = Paint()
      ..color = const Color(0xFFFFEB3B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(currPath, currPaint);
  }

  @override
  bool shouldRepaint(covariant WaveformSampLogicPainter oldDelegate) => false;
}
