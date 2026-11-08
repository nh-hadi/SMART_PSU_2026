import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import 'probe_models.dart';

class ProbePage1MultimeterView extends StatelessWidget {
  final Color activeColor;
  final String themeName;
  final String probeMode;
  final bool isProbeShort;
  final String probeStatusSubtitle;
  final String probeCurrentDisplayValue;
  final List<ProbeHistoryItem> probeHistory;
  final ValueChanged<String> onModeChanged;
  final VoidCallback onToggleShort;
  final VoidCallback onRecordMeasurement;
  final VoidCallback onClearHistory;
  final VoidCallback onNavigateToGraph;

  const ProbePage1MultimeterView({
    super.key,
    required this.activeColor,
    this.themeName = 'WIREFRAME',
    required this.probeMode,
    required this.isProbeShort,
    required this.probeStatusSubtitle,
    required this.probeCurrentDisplayValue,
    required this.probeHistory,
    required this.onModeChanged,
    required this.onToggleShort,
    required this.onRecordMeasurement,
    required this.onClearHistory,
    required this.onNavigateToGraph,
  });

  Widget _buildLargeProbeModeButton(String modeKey, String label, IconData icon) {
    final bool isSelected = probeMode == modeKey;
    final bool isFullColor = themeName == 'FULL_COLOR';

    Color activeBtnColor = const Color(0xFF00E5FF);
    List<Color> gradientColors = [const Color(0xFF00E5FF), const Color(0xFF0051FF)];
    if (modeKey == 'DIODA') {
      activeBtnColor = const Color(0xFFFF007F);
      gradientColors = [const Color(0xFFFF007F), const Color(0xFF7928CA)];
    }
    if (modeKey == 'RESISTOR') {
      activeBtnColor = const Color(0xFFFFEA00);
      gradientColors = [const Color(0xFFFFEA00), const Color(0xFFFF6B00)];
    }

    if (isFullColor) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onModeChanged(modeKey);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      gradientColors[0].withOpacity(0.28),
                      gradientColors[1].withOpacity(0.12),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : const Color(0xFF10131F),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? activeBtnColor : Colors.white12,
              width: isSelected ? 1.4 : 0.6,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeBtnColor.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? activeBtnColor : const Color(0xFF64748B),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
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

    // Wireframe Fallback
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onModeChanged(modeKey);
      },
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white24 : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white24,
            width: isSelected ? 1.4 : 0.8,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.white60,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 8.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isFullColor = themeName == 'FULL_COLOR';

    Color modeColor = const Color(0xFF00E5FF);
    String unitLabel = 'VDC';
    String rangeLabel = '0.000V ~ 30.000V';

    if (probeMode == 'DIODA') {
      modeColor = const Color(0xFFFF007F);
      unitLabel = '';
      rangeLabel = '0.000 ~ 2.000 (BUZZER <0.020)';
    } else if (probeMode == 'RESISTOR') {
      modeColor = const Color(0xFFFFEA00);
      unitLabel = 'OHM';
      rangeLabel = '0.00Ω ~ 10.0MΩ AUTO';
    }

    return Row(
      children: [
        // SISI KIRI: DISPLAY ANGKA JUMBO + SELECTOR MODE BESAR DI TENGAH
        Expanded(
          flex: 4,
          child: Column(
            children: [
              // 1. Display Angka Ukur Jumbo Real-time
              Expanded(
                flex: 5,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    onToggleShort();
                  },
                  child: isFullColor
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isProbeShort
                                ? const Color(0xFF220A12)
                                : const Color(0xFF10131F),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isProbeShort
                                  ? const Color(0xFFFF1744)
                                  : modeColor.withOpacity(0.3),
                              width: isProbeShort ? 1.6 : 0.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isProbeShort ? const Color(0xFFFF1744) : modeColor).withOpacity(0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Header Baris Info
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: (isProbeShort ? const Color(0xFFFF1744) : modeColor).withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isProbeShort ? Icons.warning_amber_rounded : Icons.sensors,
                                          size: 12,
                                          color: isProbeShort ? const Color(0xFFFF1744) : modeColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isProbeShort ? 'SHORT GND' : '$probeMode PROBE',
                                          style: TextStyle(
                                            color: isProbeShort ? const Color(0xFFFF1744) : modeColor,
                                            fontSize: 8.5,
                                            fontFamily: 'monospace',
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.04),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      rangeLabel,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 7.5,
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Angka Nilai Jumbo dengan Ruang Maksimal
                              Expanded(
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          isProbeShort
                                              ? (probeMode == 'DIODA' ? '000' : '0.000')
                                              : probeCurrentDisplayValue.split(' ').first,
                                          style: TextStyle(
                                            color: isProbeShort ? const Color(0xFFFF1744) : modeColor,
                                            fontSize: 64,
                                            fontFamily: 'monospace',
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.5,
                                            shadows: [
                                              Shadow(
                                                color: (isProbeShort ? const Color(0xFFFF1744) : modeColor).withOpacity(0.65),
                                                blurRadius: 16,
                                              ),
                                              Shadow(
                                                color: (isProbeShort ? const Color(0xFFFF1744) : modeColor).withOpacity(0.35),
                                                blurRadius: 30,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Builder(
                                          builder: (_) {
                                            final String unitText = isProbeShort
                                                ? (probeMode == 'RESISTOR' ? 'Ω' : (probeMode == 'VOLT' ? 'V' : ''))
                                                : (probeMode == 'DIODA'
                                                    ? ''
                                                    : (probeCurrentDisplayValue.contains(' ')
                                                        ? probeCurrentDisplayValue.split(' ').last
                                                        : unitLabel));

                                            if (unitText.isEmpty) {
                                              return const SizedBox.shrink();
                                            }

                                            return Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const SizedBox(width: 6),
                                                Text(
                                                  unitText,
                                                  style: TextStyle(
                                                    color: isProbeShort ? const Color(0xFFFF1744) : modeColor,
                                                    fontSize: 24,
                                                    fontFamily: 'monospace',
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Status Bawah
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (isProbeShort ? const Color(0xFFFF1744) : modeColor).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      isProbeShort ? 'BUZZER BEEP CONTINUOUS' : probeStatusSubtitle,
                                      style: TextStyle(
                                        color: isProbeShort ? const Color(0xFFFF5252) : const Color(0xFF94A3B8),
                                        fontSize: 7.5,
                                        fontFamily: 'monospace',
                                        fontWeight: isProbeShort ? FontWeight.w900 : FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      width: 6.5,
                                      height: 6.5,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isProbeShort ? const Color(0xFFFF1744) : const Color(0xFF00FF88),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (isProbeShort ? const Color(0xFFFF1744) : const Color(0xFF00FF88)).withOpacity(0.8),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isProbeShort ? Colors.red.withOpacity(0.18) : Colors.transparent,
                            border: Border.all(
                              color: isProbeShort ? Colors.redAccent : activeColor,
                              width: isProbeShort ? 2.0 : 1.2,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isProbeShort ? '⚠️ PERINGATAN: JALUR SHORT TO GROUND (GND)!' : probeStatusSubtitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isProbeShort ? Colors.redAccent : Colors.white60,
                                  fontSize: 8.5,
                                  fontFamily: 'monospace',
                                  fontWeight: isProbeShort ? FontWeight.w900 : FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  isProbeShort
                                      ? (probeMode == 'DIODA' ? '000' : '0.000 V')
                                      : probeCurrentDisplayValue,
                                  style: TextStyle(
                                    color: isProbeShort ? Colors.redAccent : Colors.white,
                                    fontSize: 44,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                isProbeShort ? '[ SHORT CIRCUIT DETECTED • BUZZER ACTIVE ]' : '[ AUTO-RANGE PROBE ACTIVE ]',
                                style: TextStyle(
                                  color: isProbeShort ? Colors.redAccent : Colors.white38,
                                  fontSize: 8,
                                  fontFamily: 'monospace',
                                  fontWeight: isProbeShort ? FontWeight.w900 : FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),

              // 2. SELECTOR MODE UKUR DI TENGAH
              isFullColor
                  ? Container(
                      height: 48,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10131F),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: _buildLargeProbeModeButton('VOLT', 'VOLT VDC', Icons.bolt)),
                          const SizedBox(width: 4),
                          Expanded(child: _buildLargeProbeModeButton('DIODA', 'DIODA', Icons.arrow_forward)),
                          const SizedBox(width: 4),
                          Expanded(child: _buildLargeProbeModeButton('RESISTOR', 'RESISTOR', Icons.all_inclusive)),
                        ],
                      ),
                    )
                  : AppTheme.buildPanel(
                      height: 48,
                      activeColor: activeColor,
                      child: Row(
                        children: [
                          Expanded(child: _buildLargeProbeModeButton('VOLT', 'VOLT VDC', Icons.bolt)),
                          const SizedBox(width: 4),
                          Expanded(child: _buildLargeProbeModeButton('DIODA', 'DIODA', Icons.arrow_forward)),
                          const SizedBox(width: 4),
                          Expanded(child: _buildLargeProbeModeButton('RESISTOR', 'RESISTOR', Icons.all_inclusive)),
                        ],
                      ),
                    ),
              const SizedBox(height: 4),

              // 3. Action Catat Hasil Ukur
              isFullColor
                  ? Container(
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFF7928CA), Color(0xFFFF007F)],
                        ),
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF007F).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 1.5),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onRecordMeasurement,
                          borderRadius: BorderRadius.circular(5),
                          child: Container(
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.add_circle, color: Colors.white, size: 13),
                                SizedBox(width: 5),
                                Text(
                                  'CATAT KE RIWAYAT UKUR',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8.5,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : AppTheme.buildPanel(
                      height: 30,
                      activeColor: activeColor,
                      child: GestureDetector(
                        onTap: onRecordMeasurement,
                        child: Container(
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add_circle_outline, color: Colors.white, size: 13),
                              SizedBox(width: 6),
                              Text(
                                '[ + CATAT KE RIWAYAT UKUR ]',
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
                      ),
                    ),
            ],
          ),
        ),
        const SizedBox(width: 4),

        // SISI KANAN: TABEL RIWAYAT BESAR
        Expanded(
          flex: 6,
          child: Column(
            children: [
              // Header Riwayat + Hint Swipe
              isFullColor
                  ? Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF141224), // Ambient dark purple
                            Color(0xFF0F172A), // Midnight slate
                            Color(0xFF101B2B), // Dark cyan slate
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white12, width: 0.6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00E5FF), Color(0xFF0051FF)],
                              ),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withOpacity(0.4),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.history, color: Colors.white, size: 11),
                                SizedBox(width: 4),
                                Text(
                                  'SMART LOG',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'RIWAYAT PENGUKURAN JALUR SERVIS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Spacer(),
                          // Badge Jumlah Data
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              '${probeHistory.length} ITEMS',
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 7.2,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: onNavigateToGraph,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF007F), Color(0xFF7928CA)],
                                ),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF007F).withOpacity(0.35),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: const [
                                  Text(
                                    'GRAFIK LOGIC',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 7.5,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  SizedBox(width: 3),
                                  Icon(Icons.arrow_forward_ios, size: 7.5, color: Colors.white),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : AppTheme.buildPanel(
                      height: 30,
                      activeColor: activeColor,
                      child: Row(
                        children: [
                          const Icon(Icons.history, color: Colors.white70, size: 13),
                          const SizedBox(width: 6),
                          const Text(
                            'TABEL RIWAYAT PENGUKURAN JALUR SERVIS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: onNavigateToGraph,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white38, width: 0.8),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Row(
                                children: const [
                                  Text(
                                    'GESER KE GRAFIK',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 7.5,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios, size: 7.5, color: Colors.white70),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              const SizedBox(height: 4),

              // Tabel Riwayat Besar
              Expanded(
                child: isFullColor
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF0F121E),
                              Color(0xFF090B12),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white.withOpacity(0.06), width: 0.8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.6),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: _buildHistoryListView(isFullColor),
                      )
                    : AppTheme.buildPanel(
                        activeColor: activeColor,
                        child: _buildHistoryListView(isFullColor),
                      ),
              ),
              const SizedBox(height: 4),

              // Clear Button
              isFullColor
                  ? Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10131F),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.white10, width: 0.6),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onClearHistory,
                          borderRadius: BorderRadius.circular(5),
                          child: Container(
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.delete_sweep_outlined, color: Color(0xFF94A3B8), size: 13),
                                SizedBox(width: 5),
                                Text(
                                  'BERSIHKAN SEMUA DATA RIWAYAT',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 8,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : AppTheme.buildPanel(
                      height: 28,
                      activeColor: activeColor,
                      child: GestureDetector(
                        onTap: onClearHistory,
                        child: Container(
                          alignment: Alignment.center,
                          child: const Text(
                            '[ BERSIHKAN SEMUA DATA RIWAYAT ]',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 8,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryListView(bool isFullColor) {
    if (probeHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFullColor ? const Color(0xFF1E293B).withOpacity(0.5) : Colors.white10,
              ),
              child: Icon(
                Icons.analytics_outlined,
                color: isFullColor ? const Color(0xFF64748B) : Colors.white24,
                size: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'BELUM ADA LOG PENGUKURAN TERSIMPAN',
              style: TextStyle(
                color: isFullColor ? const Color(0xFF64748B) : Colors.white30,
                fontSize: 8,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 2),
      itemCount: probeHistory.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final item = probeHistory[index];
        Color badgeColor = const Color(0xFF00E5FF);
        if (item.mode == 'DIODA') badgeColor = const Color(0xFFFF007F);
        if (item.mode == 'RES' || item.mode == 'RESISTOR') badgeColor = const Color(0xFFFFEA00);

        final bool isShortItem = item.value.contains('000') || item.note.toUpperCase().contains('SHORT');

        if (isFullColor) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isShortItem
                    ? [
                        const Color(0xFFFF1744).withOpacity(0.22),
                        const Color(0xFF1B0C14),
                      ]
                    : [
                        const Color(0xFF131828),
                        const Color(0xFF0E111C),
                      ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: isShortItem
                    ? const Color(0xFFFF1744).withOpacity(0.6)
                    : badgeColor.withOpacity(0.2),
                width: 0.7,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isShortItem ? const Color(0xFFFF1744) : badgeColor).withOpacity(0.08),
                  blurRadius: 5,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                // Nomor Urut Index
                Container(
                  width: 20,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '#${index + 1}',
                    style: TextStyle(
                      color: isShortItem ? const Color(0xFFFF8A80) : const Color(0xFF64748B),
                      fontSize: 8,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Chip Mode
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isShortItem
                        ? const Color(0xFFFF1744).withOpacity(0.25)
                        : badgeColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    item.mode,
                    style: TextStyle(
                      color: isShortItem ? const Color(0xFFFF5252) : badgeColor,
                      fontSize: 7.5,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Angka Ukur Nilai
                SizedBox(
                  width: 60,
                  child: Text(
                    item.value,
                    style: TextStyle(
                      color: isShortItem ? const Color(0xFFFF5252) : Colors.white,
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                      shadows: isShortItem
                          ? [
                              Shadow(
                                color: const Color(0xFFFF1744).withOpacity(0.8),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Jalur Komponen Servis
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Text(
                          'JALUR',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 6.5,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.note,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isShortItem ? const Color(0xFFFF8A80) : const Color(0xFFE2E8F0),
                            fontSize: 8.5,
                            fontFamily: 'monospace',
                            fontWeight: isShortItem ? FontWeight.w900 : FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Jam Pengukuran
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time, size: 8, color: Color(0xFF64748B)),
                      const SizedBox(width: 3),
                      Text(
                        item.time,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 7.2,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // Default Wireframe
        return Row(
          children: [
            Text(
              '#${index + 1} ',
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 8.5,
                fontFamily: 'monospace',
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white38, width: 0.8),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                item.mode,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 7.5,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              item.value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'JALUR: ${item.note}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 8.5,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            Text(
              item.time,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 7.5,
                fontFamily: 'monospace',
              ),
            ),
          ],
        );
      },
    );
  }
}
