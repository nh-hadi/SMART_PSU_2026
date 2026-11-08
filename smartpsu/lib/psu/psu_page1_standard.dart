import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

class PsuPage1View extends StatefulWidget {
  final Color activeColor;
  final String themeName;
  final Widget? oscilloscopeWidget;
  final double liveVolt;
  final double liveAmp;
  final bool ocpEnabled;
  final double ocpLimit;
  final Function(bool) onOcpEnabledChanged;
  final Function(double) onOcpLimitChanged;
  final VoidCallback? onNavigateToPage2;
  final VoidCallback? onNavigateToPage3;

  const PsuPage1View({
    super.key,
    required this.activeColor,
    this.themeName = 'FULL_COLOR',
    this.oscilloscopeWidget,
    required this.liveVolt,
    required this.liveAmp,
    required this.ocpEnabled,
    required this.ocpLimit,
    required this.onOcpEnabledChanged,
    required this.onOcpLimitChanged,
    this.onNavigateToPage2,
    this.onNavigateToPage3,
  });

  @override
  State<PsuPage1View> createState() => _PsuPage1ViewState();
}

class _PsuPage1ViewState extends State<PsuPage1View> {
  final PageController _subPageController = PageController();
  int _activeSubPageIndex = 0; // 0: DETAIL, 1: VOLT & AMP, 2: ANALOG AMMETER

  @override
  void dispose() {
    _subPageController.dispose();
    super.dispose();
  }

  String _getSubPageTitle() {
    switch (_activeSubPageIndex) {
      case 0:
        return 'PSU: DETAIL LAB';
      case 1:
        return 'PSU: VOLT & AMP JUMBO';
      case 2:
      default:
        return 'PSU: ANALOG AMMETER (1.0A)';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.oscilloscopeWidget == null) {
      return _buildPsuMiddlePanel();
    }

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: _buildPsuMiddlePanel(),
        ),
        const SizedBox(width: 4),
        Expanded(
          flex: 6,
          child: widget.oscilloscopeWidget!,
        ),
      ],
    );
  }

  Widget _buildPsuMiddlePanel() {
    final bool isFullColor = widget.themeName == 'FULL_COLOR';

    return Column(
      children: [
        // 1. Header Swipe Mode + Navigasi Halaman P2/P3
        Container(
          padding: const EdgeInsets.symmetric(vertical: 3.5, horizontal: 8),
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: isFullColor ? const Color(0xFF10131F) : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(5),
            border: isFullColor ? null : Border.all(color: Colors.white12, width: 0.6),
            boxShadow: isFullColor
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.power,
                    color: isFullColor ? const Color(0xFF00E5FF) : widget.activeColor,
                    size: 13,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _getSubPageTitle(),
                    style: TextStyle(
                      color: isFullColor ? const Color(0xFF00E5FF) : widget.activeColor,
                      fontSize: 8.5,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dot Indikator 3 Sub-Halaman
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (idx) {
                      final isActive = _activeSubPageIndex == idx;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: isActive ? 14 : 4,
                        height: 3.5,
                        decoration: BoxDecoration(
                          color: isActive
                              ? (isFullColor ? const Color(0xFF00E5FF) : widget.activeColor)
                              : Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: (isActive && isFullColor)
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF00E5FF).withOpacity(0.6),
                                    blurRadius: 6,
                                  ),
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                  if (widget.oscilloscopeWidget != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: widget.onNavigateToPage2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(right: 3),
                        decoration: BoxDecoration(
                          color: isFullColor ? const Color(0xFF261D3B) : widget.activeColor.withOpacity(0.2),
                          border: Border.all(
                            color: isFullColor ? const Color(0xFFC084FC).withOpacity(0.6) : widget.activeColor,
                            width: 0.8,
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'P2 [UI]',
                          style: TextStyle(
                            color: isFullColor ? const Color(0xFFE9D5FF) : widget.activeColor,
                            fontSize: 7.8,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onNavigateToPage3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isFullColor ? const Color(0xFF1E293B) : Colors.white10,
                          border: isFullColor ? null : Border.all(color: Colors.white24, width: 0.6),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'P3',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 7.8,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // 2. Display Utama (Bisa Di-swipe 3 Mode)
        Expanded(
          flex: 5,
          child: PageView(
            controller: _subPageController,
            onPageChanged: (idx) {
              setState(() => _activeSubPageIndex = idx);
            },
            children: [
              _buildPsuDefaultView(),
              _buildPsuVoltAmpOnlyView(),
              _buildPsuAnalogAmpView(),
            ],
          ),
        ),

        // 3. Panel SET OCP + SLIDER MAX 10A (Hanya tampil pada Halaman 0 Standar)
        if (_activeSubPageIndex == 0) ...[
          const SizedBox(height: 4),
          _buildOcpSliderPanel(isFullColor),
        ],
        const SizedBox(height: 4),

        // 4. Tombol Analisis AI Diagnostic
        _buildAiDiagnosticButton(isFullColor),
      ],
    );
  }

  // Widget Slider OCP dengan desain responsif Full Color
  Widget _buildOcpSliderPanel(bool isFullColor) {
    if (isFullColor) {
      return Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF10131F),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 20,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF007F).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'SET OCP',
                      style: TextStyle(
                        color: Color(0xFFFF007F),
                        fontSize: 7.5,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${widget.ocpLimit.toStringAsFixed(1)}A / 10A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: widget.ocpEnabled
                          ? const Color(0xFF00FF88).withOpacity(0.16)
                          : Colors.white10,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      widget.ocpEnabled ? 'PROTECT' : 'OFF',
                      style: TextStyle(
                        color: widget.ocpEnabled ? const Color(0xFF00FF88) : Colors.white38,
                        fontSize: 7,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: 0.58,
                    child: Switch(
                      value: widget.ocpEnabled,
                      activeColor: const Color(0xFF00FF88),
                      activeTrackColor: const Color(0xFF00FF88).withOpacity(0.3),
                      inactiveThumbColor: Colors.white38,
                      inactiveTrackColor: Colors.transparent,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (val) {
                        HapticFeedback.mediumImpact();
                        widget.onOcpEnabledChanged(val);
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 18,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2.5,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                  overlayShape: SliderComponentShape.noOverlay,
                  activeTrackColor: const Color(0xFFFF007F),
                  inactiveTrackColor: Colors.white12,
                  thumbColor: const Color(0xFFFF007F),
                ),
                child: Slider(
                  value: widget.ocpLimit,
                  min: 0.0,
                  max: 10.0,
                  divisions: 100,
                  onChanged: (val) {
                    widget.onOcpLimitChanged(val);
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Default Wireframe
    return AppTheme.buildPanel(
      height: 48,
      activeColor: widget.activeColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 20,
            child: Row(
              children: [
                const Text(
                  'SET OCP',
                  style: TextStyle(color: Colors.white, fontSize: 8, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 5),
                Text(
                  '${widget.ocpLimit.toStringAsFixed(1)}A / 10A',
                  style: const TextStyle(color: Colors.white, fontSize: 8.5, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  widget.ocpEnabled ? 'ON' : 'OFF',
                  style: TextStyle(color: widget.ocpEnabled ? Colors.white : Colors.white38, fontSize: 8, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                ),
                Transform.scale(
                  scale: 0.55,
                  child: Switch(
                    value: widget.ocpEnabled,
                    activeColor: Colors.white,
                    inactiveThumbColor: Colors.white38,
                    inactiveTrackColor: Colors.transparent,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (val) {
                      HapticFeedback.mediumImpact();
                      widget.onOcpEnabledChanged(val);
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 18,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4.5),
                overlayShape: SliderComponentShape.noOverlay,
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white24,
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: widget.ocpLimit,
                min: 0.0,
                max: 10.0,
                divisions: 100,
                onChanged: (val) {
                  widget.onOcpLimitChanged(val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tombol AI Diagnostic
  Widget _buildAiDiagnosticButton(bool isFullColor) {
    if (isFullColor) {
      return Container(
        height: 28,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00E5FF), Color(0xFF7928CA), Color(0xFFFF007F)],
          ),
          borderRadius: BorderRadius.circular(5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF007F).withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  duration: Duration(milliseconds: 1000),
                  content: Text('Trigger AI Analysis: Mengirim snapshot arus PSU...'),
                ),
              );
            },
            borderRadius: BorderRadius.circular(5),
            child: Container(
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                  SizedBox(width: 5),
                  Text(
                    'START AI POWER DIAGNOSIS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
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
      );
    }

    return AppTheme.buildPanel(
      height: 28,
      activeColor: widget.activeColor,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                duration: Duration(milliseconds: 1000),
                content: Text('Trigger AI Analysis: Mengirim snapshot arus PSU...'),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text(
                  '[ START AI ANALYSIS ]',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Tampilan Halaman 0: Tampilan Standar 3 Baris (Volt, Ampere, Watt)
  Widget _buildPsuDefaultView() {
    final watt = widget.liveVolt * widget.liveAmp;
    final mA = widget.liveAmp * 1000.0;
    final bool isFullColor = widget.themeName == 'FULL_COLOR';

    if (isFullColor) {
      return Column(
        children: [
          // 1. VOLTASE CARD (Neon Cyan)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: const Color(0xFF10131F),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.2), width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Icon(Icons.bolt, size: 10, color: Color(0xFF00E5FF)),
                      const SizedBox(width: 3),
                      const Text(
                        'OUTPUT VOLTAGE',
                        style: TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 8,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        '0 - 30.0 V',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 7.2,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
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
                              widget.liveVolt.toStringAsFixed(3),
                              style: const TextStyle(
                                color: Color(0xFF00E5FF),
                                fontSize: 36,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Text(
                              'V',
                              style: TextStyle(
                                color: Color(0xFF00E5FF),
                                fontSize: 14,
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
          ),
          const SizedBox(height: 3),

          // 2. ARUS BEBAN CARD (Electric Amber / Neon Rose)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: const Color(0xFF10131F),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFF6B00).withOpacity(0.25), width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B00).withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Icon(Icons.waves, size: 10, color: Color(0xFFFF6B00)),
                      const SizedBox(width: 3),
                      const Text(
                        'LOAD CURRENT',
                        style: TextStyle(
                          color: Color(0xFFFF6B00),
                          fontSize: 8,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${mA.toStringAsFixed(1)} mA',
                        style: const TextStyle(
                          color: Color(0xFFFF9E59),
                          fontSize: 7.5,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
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
                              widget.liveAmp.toStringAsFixed(3),
                              style: const TextStyle(
                                color: Color(0xFFFF6B00),
                                fontSize: 36,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Text(
                              'A',
                              style: TextStyle(
                                color: Color(0xFFFF6B00),
                                fontSize: 14,
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
          ),
          const SizedBox(height: 3),

          // 3. DAYA KONSUMSI CARD (Electric Yellow)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: const Color(0xFF10131F),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFFEA00).withOpacity(0.2), width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFEA00).withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: const [
                      Icon(Icons.speed, size: 10, color: Color(0xFFFFEA00)),
                      SizedBox(width: 3),
                      Text(
                        'POWER CONSUMPTION',
                        style: TextStyle(
                          color: Color(0xFFFFEA00),
                          fontSize: 8,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
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
                              watt.toStringAsFixed(2),
                              style: const TextStyle(
                                color: Color(0xFFFFEA00),
                                fontSize: 34,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Text(
                              'W',
                              style: TextStyle(
                                color: Color(0xFFFFEA00),
                                fontSize: 14,
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
          ),
        ],
      );
    }

    // Default Fallback Wireframe
    return Column(
      children: [
        Expanded(
          child: AppTheme.buildPanel(
            activeColor: widget.activeColor,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'VOLTASE OUTPUT',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 8.5,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        widget.liveVolt.toStringAsFixed(3),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'V',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),

        Expanded(
          child: AppTheme.buildPanel(
            activeColor: widget.activeColor,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ARUS BEBAN',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 8.5,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '${mA.toStringAsFixed(1)} mA',
                      style: TextStyle(
                        color: widget.activeColor.withOpacity(0.7),
                        fontSize: 8,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        widget.liveAmp.toStringAsFixed(3),
                        style: TextStyle(
                          color: widget.activeColor,
                          fontSize: 26,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'A',
                        style: TextStyle(
                          color: widget.activeColor,
                          fontSize: 13,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),

        Expanded(
          child: AppTheme.buildPanel(
            activeColor: widget.activeColor,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'DAYA KONSUMSI',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 8.5,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        watt.toStringAsFixed(2),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'W',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
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
    );
  }

  // Tampilan Halaman 1: Khusus Volt & Ampere Saja (Font Jumbo & Bersih)
  Widget _buildPsuVoltAmpOnlyView() {
    final bool isFullColor = widget.themeName == 'FULL_COLOR';

    if (isFullColor) {
      return Column(
        children: [
          // Blok Voltase Raksasa
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF10131F),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withOpacity(0.06),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withOpacity(0.16),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'OUTPUT VOLTAGE',
                          style: TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 8.5,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const Text(
                        '0.000 - 30.000 V',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 7.5,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
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
                              widget.liveVolt.toStringAsFixed(3),
                              style: const TextStyle(
                                color: Color(0xFF00E5FF),
                                fontSize: 52,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'V',
                              style: TextStyle(
                                color: Color(0xFF00E5FF),
                                fontSize: 22,
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
          ),
          const SizedBox(height: 4),

          // Blok Arus Raksasa
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF10131F),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B00).withOpacity(0.06),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B00).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'LOAD CURRENT',
                          style: TextStyle(
                            color: Color(0xFFFF6B00),
                            fontSize: 8.5,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Text(
                        '${(widget.liveAmp * 1000).toStringAsFixed(0)} mA',
                        style: const TextStyle(
                          color: Color(0xFFFF9E59),
                          fontSize: 7.5,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
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
                              widget.liveAmp.toStringAsFixed(3),
                              style: const TextStyle(
                                color: Color(0xFFFF6B00),
                                fontSize: 52,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'A',
                              style: TextStyle(
                                color: Color(0xFFFF6B00),
                                fontSize: 22,
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
          ),
        ],
      );
    }

    // Default Wireframe
    return Column(
      children: [
        Expanded(
          child: AppTheme.buildPanel(
            activeColor: widget.activeColor,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'VOLTAGE',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 8.5,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '0.000 - 30.000 V',
                      style: TextStyle(
                        color: Colors.white30,
                        fontSize: 7.5,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        widget.liveVolt.toStringAsFixed(3),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'V',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 16,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),

        Expanded(
          child: AppTheme.buildPanel(
            activeColor: widget.activeColor,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'CURRENT',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 8.5,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(widget.liveAmp * 1000).toStringAsFixed(0)} mA',
                      style: const TextStyle(
                        color: Colors.white30,
                        fontSize: 7.5,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        widget.liveAmp.toStringAsFixed(3),
                        style: TextStyle(
                          color: widget.activeColor,
                          fontSize: 34,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'A',
                        style: TextStyle(
                          color: widget.activeColor,
                          fontSize: 16,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Tampilan Halaman 2: Analog Ampere Meter Jarum Tunggal (Skala Max 1.0A)
  Widget _buildPsuAnalogAmpView() {
    final bool isFullColor = widget.themeName == 'FULL_COLOR';

    Widget buildContent() {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.speed, color: isFullColor ? const Color(0xFF00E5FF) : Colors.white70, size: 12),
                  const SizedBox(width: 4),
                  const Text(
                    'ANALOG AMMETER (1.0A MAX)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isFullColor ? const Color(0xFFFF007F).withOpacity(0.18) : Colors.redAccent.withOpacity(0.18),
                  border: isFullColor ? null : Border.all(color: Colors.redAccent, width: 0.6),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'LIMIT: ${widget.ocpLimit.toStringAsFixed(1)}A',
                  style: TextStyle(
                    color: isFullColor ? const Color(0xFFFF007F) : Colors.redAccent,
                    fontSize: 7.5,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
              child: CustomPaint(
                size: Size.infinite,
                painter: _AnalogMeterGaugePainter(
                  currentAmp: widget.liveAmp,
                  maxAmp: 1.0,
                  ocpLimit: widget.ocpLimit,
                  accentColor: isFullColor ? const Color(0xFF00E5FF) : widget.activeColor,
                ),
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: isFullColor ? const Color(0xFF161B2E) : Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(4),
              border: isFullColor ? null : Border.all(color: Colors.white12, width: 0.6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ARUS: ${widget.liveAmp.toStringAsFixed(3)} A',
                  style: TextStyle(
                    color: isFullColor ? const Color(0xFFFF6B00) : widget.activeColor,
                    fontSize: 9,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${(widget.liveAmp * 1000).toStringAsFixed(1)} mA',
                  style: TextStyle(
                    color: isFullColor ? const Color(0xFFFF9E59) : Colors.white70,
                    fontSize: 8.5,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  'VOLT: ${widget.liveVolt.toStringAsFixed(3)} V',
                  style: TextStyle(
                    color: isFullColor ? const Color(0xFF00E5FF) : Colors.white,
                    fontSize: 8.5,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (isFullColor) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF10131F),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withOpacity(0.06),
              blurRadius: 10,
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: buildContent(),
      );
    }

    return AppTheme.buildPanel(
      activeColor: widget.activeColor,
      child: buildContent(),
    );
  }
}

/// Custom Painter Pengukur Arus Jarum Analog Default (Analog Ammeter Gauge)
class _AnalogMeterGaugePainter extends CustomPainter {
  final double currentAmp;
  final double maxAmp;
  final double ocpLimit;
  final Color accentColor;

  const _AnalogMeterGaugePainter({
    required this.currentAmp,
    required this.maxAmp,
    required this.ocpLimit,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final center = Offset(size.width / 2, size.height * 0.95);
    final radius = math.min(size.width * 0.48, size.height * 0.88);

    const startAngleDeg = 205.0;
    const sweepAngleDeg = 130.0;
    const startRad = startAngleDeg * (math.pi / 180.0);
    const totalRad = sweepAngleDeg * (math.pi / 180.0);

    final dialRect = Rect.fromCircle(center: center, radius: radius);
    final dialBgPaint = Paint()
      ..color = const Color(0xFF0D1117)
      ..style = PaintingStyle.fill;
    final dialArcPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(dialRect, startRad, totalRad, false)
      ..close();
    canvas.drawPath(dialArcPath, dialBgPaint);

    final trackPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startRad,
      totalRad,
      false,
      trackPaint,
    );

    final clampedOcp = ocpLimit.clamp(0.0, maxAmp);
    final ocpFraction = clampedOcp / maxAmp;
    final ocpStartRad = startRad + (totalRad * ocpFraction);
    final ocpSweepRad = totalRad * (1.0 - ocpFraction);

    if (ocpSweepRad > 0) {
      final ocpPaint = Paint()
        ..color = const Color(0xFFFF007F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        ocpStartRad,
        ocpSweepRad,
        false,
        ocpPaint,
      );
    }

    const totalDivisions = 50;
    for (int i = 0; i <= totalDivisions; i++) {
      final fraction = i / totalDivisions;
      final angle = startRad + (totalRad * fraction);
      final isMajor = (i % 10 == 0);
      final isMedium = (i % 5 == 0 && !isMajor);

      final tickLength = isMajor ? 9.0 : (isMedium ? 6.0 : 3.5);
      final tickColor = (fraction * maxAmp > clampedOcp)
          ? const Color(0xFFFF007F)
          : (isMajor ? accentColor : (isMedium ? Colors.white60 : Colors.white30));

      final p1 = Offset(
        center.dx + (radius - 2) * math.cos(angle),
        center.dy + (radius - 2) * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + (radius - 2 - tickLength) * math.cos(angle),
        center.dy + (radius - 2 - tickLength) * math.sin(angle),
      );

      final tickPaint = Paint()
        ..color = tickColor
        ..strokeWidth = isMajor ? 1.6 : (isMedium ? 1.1 : 0.7);

      canvas.drawLine(p1, p2, tickPaint);

      if (isMajor) {
        final val = fraction * maxAmp;
        final textSpan = TextSpan(
          text: val.toStringAsFixed(1),
          style: TextStyle(
            color: tickColor,
            fontSize: 8.0,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        );
        final tp = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();

        final labelRadius = radius - 18.0;
        final labelPos = Offset(
          center.dx + labelRadius * math.cos(angle) - (tp.width / 2),
          center.dy + labelRadius * math.sin(angle) - (tp.height / 2),
        );
        tp.paint(canvas, labelPos);
      }
    }

    final unitSpan = const TextSpan(
      text: 'AMPERE (MAX 1.0A)',
      style: TextStyle(
        color: Colors.white38,
        fontSize: 7.0,
        letterSpacing: 1.0,
        fontWeight: FontWeight.bold,
        fontFamily: 'monospace',
      ),
    );
    final unitTp = TextPainter(text: unitSpan, textDirection: TextDirection.ltr)..layout();
    unitTp.paint(canvas, Offset(center.dx - (unitTp.width / 2), center.dy - (radius * 0.45)));

    final clampedCurrent = currentAmp.clamp(0.0, maxAmp);
    final currentFraction = clampedCurrent / maxAmp;
    final needleAngle = startRad + (totalRad * currentFraction);

    final needleLength = radius * 0.88;
    final needleTip = Offset(
      center.dx + needleLength * math.cos(needleAngle),
      center.dy + needleLength * math.sin(needleAngle),
    );

    canvas.drawLine(
      Offset(center.dx + 2, center.dy + 2),
      Offset(needleTip.dx + 2, needleTip.dy + 2),
      Paint()..color = Colors.black.withOpacity(0.5)..strokeWidth = 2.5..strokeCap = StrokeCap.round,
    );

    final isOverLimit = clampedCurrent >= clampedOcp;
    final needleColor = isOverLimit ? const Color(0xFFFF007F) : const Color(0xFFFF5252);
    canvas.drawLine(center, needleTip, Paint()..color = needleColor..strokeWidth = 2.0..strokeCap = StrokeCap.round);

    final tailTip = Offset(center.dx - 10 * math.cos(needleAngle), center.dy - 10 * math.sin(needleAngle));
    canvas.drawLine(center, tailTip, Paint()..color = Colors.white54..strokeWidth = 2.2..strokeCap = StrokeCap.round);

    canvas.drawCircle(center, 7.0, Paint()..color = const Color(0xFF1E2630));
    canvas.drawCircle(center, 7.0, Paint()..color = accentColor..style = PaintingStyle.stroke..strokeWidth = 1.2);
    canvas.drawCircle(center, 3.0, Paint()..color = needleColor);
  }

  @override
  bool shouldRepaint(covariant _AnalogMeterGaugePainter oldDelegate) {
    return oldDelegate.currentAmp != currentAmp ||
        oldDelegate.maxAmp != maxAmp ||
        oldDelegate.ocpLimit != ocpLimit ||
        oldDelegate.accentColor != accentColor;
  }
}
