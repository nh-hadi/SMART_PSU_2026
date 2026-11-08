import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../oscilloscope_view.dart';
import '../theme.dart';
import '../psu_udp_service.dart';

/// Halaman 1: Normal Split View USB (Middle Panel multi-mode + Oscilloscope Panel)
class UsbPage1Standard extends StatefulWidget {
  final Color activeColor;
  final String themeName;
  final Widget oscilloscopeWidget;
  final List<Map<String, dynamic>> channelsData;
  final int selectedChannel;
  final VoidCallback onOpenOverview;

  const UsbPage1Standard({
    super.key,
    required this.activeColor,
    required this.themeName,
    required this.oscilloscopeWidget,
    required this.channelsData,
    required this.selectedChannel,
    required this.onOpenOverview,
  });

  @override
  State<UsbPage1Standard> createState() => _UsbPage1StandardState();
}

class _UsbPage1StandardState extends State<UsbPage1Standard> {
  int _usbActivePageIndex = 0; // 0: DETAIL LENGKAP, 1: VOLT & ARUS JUMBO, 2: ANALOG GAUGE 3A
  final PageController _usbDisplayPageController = PageController();

  @override
  void dispose() {
    _usbDisplayPageController.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _currentChannelData {
    return widget.channelsData.firstWhere(
      (item) => item['ch'] == widget.selectedChannel,
      orElse: () => widget.channelsData[0],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Panel 2 USB: Bisa di-swipe 3 Mode Tampilan seperti PSU
        Expanded(
          flex: 4,
          child: _buildUsbMiddlePanel(),
        ),
        const SizedBox(width: 4),

        // Panel 3: Grafik Oscilloscope
        Expanded(
          flex: 6,
          child: widget.oscilloscopeWidget is OscilloscopePanelView
              ? OscilloscopePanelView(
                  activeColor: (widget.oscilloscopeWidget as OscilloscopePanelView).activeColor,
                  themeName: (widget.oscilloscopeWidget as OscilloscopePanelView).themeName,
                  graphMode: (widget.oscilloscopeWidget as OscilloscopePanelView).graphMode,
                  onGraphModeChanged: (widget.oscilloscopeWidget as OscilloscopePanelView).onGraphModeChanged,
                  currentAmp: (_currentChannelData['liveAmp'] as num?)?.toDouble() ?? 0.0,
                  currentVolt: (_currentChannelData['liveVolt'] as num?)?.toDouble() ?? 0.0,
                  currentWatt: ((_currentChannelData['liveVolt'] as num?)?.toDouble() ?? 0.0) *
                      ((_currentChannelData['liveAmp'] as num?)?.toDouble() ?? 0.0),
                  customAmpHistory: PsuUdpService.instance.usbAmpHistory,
                  customVoltHistory: PsuUdpService.instance.usbVoltHistory,
                )
              : widget.oscilloscopeWidget,
        ),
      ],
    );
  }

  // ==========================================
  // PANEL 2: MULTI-VIEW SWIPEABLE SEPERTI MODE PSU
  // ==========================================
  Widget _buildUsbMiddlePanel() {
    final cur = _currentChannelData;
    final bool isFullColor = widget.themeName == 'FULL_COLOR';

    return Column(
      children: [
        // 1. Header Sub-Halaman Swipe (Indikator Mode + Pilihan CH + Tombol 4-CH Grid)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 3.5, horizontal: 8),
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: isFullColor ? const Color(0xFF10131F) : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(4),
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
                    Icons.usb,
                    color: isFullColor ? const Color(0xFF00E5FF) : widget.activeColor,
                    size: 13,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _usbActivePageIndex == 0
                        ? 'USB ${cur['name']}: DETAIL'
                        : (_usbActivePageIndex == 1
                            ? 'USB ${cur['name']}: VOLT & AMP'
                            : 'USB ${cur['name']}: ANALOG METER'),
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
                  // 3 Dot Indikator Mode
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (idx) {
                      final isActive = _usbActivePageIndex == idx;
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
                  const SizedBox(width: 8),
                  // Tombol Fullscreen 4-CH
                  GestureDetector(
                    onTap: widget.onOpenOverview,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isFullColor ? const Color(0xFF1E293B) : Colors.white10,
                        border: isFullColor ? null : Border.all(color: Colors.white24, width: 0.6),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.grid_view, size: 9, color: Colors.white),
                          SizedBox(width: 3),
                          Text(
                            '4-CH',
                            style: TextStyle(color: Colors.white, fontSize: 7.8, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 2. Area Display Utama (Bisa Di-swipe 3 Halaman)
        Expanded(
          flex: 5,
          child: PageView(
            controller: _usbDisplayPageController,
            onPageChanged: (idx) {
              setState(() => _usbActivePageIndex = idx);
            },
            children: [
              // Halaman 0: Tampilan Standar Lengkap (Volt, Arus, Daya, mAh, Wh, D+, D-)
              _buildUsbDetailView(cur),
              // Halaman 1: Tampilan Volt & Ampere Saja (Font Jumbo Jelas)
              _buildUsbVoltAmpOnlyView(cur),
              // Halaman 2: Tampilan Analog Ampere Meter Jarum (Gaya Presisi)
              _buildUsbAnalogMeterView(cur),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // 3. Tombol Analisis AI Charging
        isFullColor
            ? Container(
                height: 38,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF7928CA), Color(0xFFFF007F)],
                  ),
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF007F).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: const Duration(milliseconds: 1000),
                          content: Text('Trigger AI Charging: Mendiagnosa ${cur['name']} [${cur['protocol']}]...'),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(5),
                    child: Container(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.auto_awesome, color: Colors.white, size: 15),
                          const SizedBox(width: 6),
                          Text(
                            'START AI DIAGNOSIS ${cur['name']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : AppTheme.buildPanel(
                height: 38,
                activeColor: widget.activeColor,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: const Duration(milliseconds: 1000),
                          content: Text('Trigger AI Charging: Mendiagnosa ${cur['name']} [${cur['protocol']}]...'),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            '[ START AI DIAGNOSIS ${cur['name']} ]',
                            style: const TextStyle(
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
              ),
      ],
    );
  }

  // Halaman 0: Tampilan Detail Lengkap Kiri-Kanan
  Widget _buildUsbDetailView(Map<String, dynamic> cur) {
    final bool isFullColor = widget.themeName == 'FULL_COLOR';

    if (isFullColor) {
      return Column(
        children: [
          // Baris 1: VOLT & AMPERE
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10131F),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E5FF).withOpacity(0.16),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'VOLTAGE',
                              style: TextStyle(
                                color: Color(0xFF00E5FF),
                                fontSize: 8,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
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
                                    (cur['liveVolt'] as double).toStringAsFixed(3),
                                    style: const TextStyle(
                                      color: Color(0xFF00E5FF),
                                      fontSize: 36,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  const Text(
                                    'V',
                                    style: TextStyle(
                                      color: Color(0xFF00E5FF),
                                      fontSize: 15,
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
                const SizedBox(width: 4),

                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10131F),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B00).withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B00).withOpacity(0.18),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'CURRENT',
                              style: TextStyle(
                                color: Color(0xFFFF6B00),
                                fontSize: 8,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
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
                                    (cur['liveAmp'] as double).toStringAsFixed(3),
                                    style: const TextStyle(
                                      color: Color(0xFFFF6B00),
                                      fontSize: 36,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  const Text(
                                    'A',
                                    style: TextStyle(
                                      color: Color(0xFFFF6B00),
                                      fontSize: 15,
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
            ),
          ),
          const SizedBox(height: 4),

          // Baris 2: DAYA WATT & KAPASITAS
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10131F),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFEA00).withOpacity(0.06),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEA00).withOpacity(0.18),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'POWER',
                              style: TextStyle(
                                color: Color(0xFFFFEA00),
                                fontSize: 8,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
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
                                    ((cur['liveVolt'] as double) * (cur['liveAmp'] as double)).toStringAsFixed(2),
                                    style: const TextStyle(
                                      color: Color(0xFFFFEA00),
                                      fontSize: 34,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  const Text(
                                    'W',
                                    style: TextStyle(
                                      color: Color(0xFFFFEA00),
                                      fontSize: 15,
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
                const SizedBox(width: 4),

                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10131F),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00FF88).withOpacity(0.06),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00FF88).withOpacity(0.18),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'CAPACITY',
                              style: TextStyle(
                                color: Color(0xFF00FF88),
                                fontSize: 8,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        cur['mah'].toString().replaceAll(' mAh', ''),
                                        style: const TextStyle(
                                          color: Color(0xFF00FF88),
                                          fontSize: 18,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      const Text(
                                        'mAh',
                                        style: TextStyle(
                                          color: Color(0xFF00FF88),
                                          fontSize: 10,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        cur['wh'].toString().replaceAll(' Wh', ''),
                                        style: const TextStyle(
                                          color: Color(0xFF38BDF8),
                                          fontSize: 18,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      const Text(
                                        'Wh',
                                        style: TextStyle(
                                          color: Color(0xFF38BDF8),
                                          fontSize: 10,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
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
            ),
          ),
          const SizedBox(height: 4),

          // Baris 3: DATA PINS D+ & D-
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10131F),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF38BDF8).withOpacity(0.16),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'DATA D+',
                              style: TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 7.2,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                cur['dp'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10131F),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF38BDF8).withOpacity(0.16),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'DATA D-',
                              style: TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 7.2,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                cur['dm'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
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
        ],
      );
    }

    // Default Fallback Wireframe
    return Column(
      children: [
        Expanded(
          flex: 6,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: AppTheme.buildPanel(
                        activeColor: widget.activeColor,
                        child: Text(
                          'VOLT VBUS\n[ ${cur['volt']} ]',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: AppTheme.buildPanel(
                        activeColor: widget.activeColor,
                        child: Text(
                          'ARUS CAS\n[ ${cur['amp']} ]',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: AppTheme.buildPanel(
                        activeColor: widget.activeColor,
                        child: Text(
                          'DAYA WATT\n[ ${cur['watt']} ]',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: AppTheme.buildPanel(
                        activeColor: widget.activeColor,
                        child: Text(
                          'KAPASITAS\n[ ${cur['mah']} ]\n[ ${cur['wh']} ]',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Expanded(
                child: AppTheme.buildPanel(
                  activeColor: widget.activeColor,
                  child: Text(
                    'DATA D+\n[ ${cur['dp']} ]',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: AppTheme.buildPanel(
                  activeColor: widget.activeColor,
                  child: Text(
                    'DATA D-\n[ ${cur['dm']} ]',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
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

  // Halaman 1: Tampilan Volt & Ampere Saja
  Widget _buildUsbVoltAmpOnlyView(Map<String, dynamic> cur) {
    final double liveVolt = cur['liveVolt'] as double;
    final double liveAmp = cur['liveAmp'] as double;
    final bool isFullColor = widget.themeName == 'FULL_COLOR';

    if (isFullColor) {
      return Column(
        children: [
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
                          'USB BUS VOLTAGE',
                          style: TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 8.5,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B2E),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          cur['protocol'] as String,
                          style: const TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 7.5,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                          ),
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
                              liveVolt.toStringAsFixed(3),
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
                          'CHARGING CURRENT',
                          style: TextStyle(
                            color: Color(0xFFFF6B00),
                            fontSize: 8.5,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B2E),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '${(liveAmp * 1000).toStringAsFixed(0)} mA',
                          style: const TextStyle(
                            color: Color(0xFFFF6B00),
                            fontSize: 7.5,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
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
                              liveAmp.toStringAsFixed(3),
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

    // Default Fallback Wireframe
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
                  children: [
                    const Text(
                      'USB VBUS',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 8.5,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      cur['protocol'] as String,
                      style: TextStyle(
                        color: widget.activeColor,
                        fontSize: 7.5,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
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
                        liveVolt.toStringAsFixed(3),
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
                      'CHARGING CURRENT',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 8.5,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(liveAmp * 1000).toStringAsFixed(0)} mA',
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
                        liveAmp.toStringAsFixed(3),
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

  // Halaman 2: Tampilan Analog Ampere Meter Jarum
  Widget _buildUsbAnalogMeterView(Map<String, dynamic> cur) {
    final double liveVolt = cur['liveVolt'] as double;
    final double liveAmp = cur['liveAmp'] as double;
    final bool isFullColor = widget.themeName == 'FULL_COLOR';

    Widget buildContent(BoxConstraints constraints) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.speed, color: isFullColor ? const Color(0xFF00E5FF) : Colors.white70, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'USB ANALOG AMMETER (3.0A MAX)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isFullColor ? const Color(0xFF00E5FF).withOpacity(0.18) : widget.activeColor.withOpacity(0.18),
                  border: isFullColor ? null : Border.all(color: widget.activeColor, width: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  '${cur['protocol']}',
                  style: TextStyle(
                    color: isFullColor ? const Color(0xFF00E5FF) : widget.activeColor,
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
                painter: UsbAnalogGaugePainter(
                  currentAmp: liveAmp,
                  maxAmp: 3.0,
                  accentColor: isFullColor ? const Color(0xFF00E5FF) : widget.activeColor,
                ),
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isFullColor ? const Color(0xFF161B2E) : Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(4),
              border: isFullColor ? null : Border.all(color: Colors.white12, width: 0.6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text('ARUS: ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 8, fontFamily: 'monospace')),
                    Text(
                      '${liveAmp.toStringAsFixed(3)} A',
                      style: TextStyle(
                        color: isFullColor ? const Color(0xFFFF007F) : widget.activeColor,
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${(liveAmp * 1000).toStringAsFixed(0)} mA',
                  style: const TextStyle(
                    color: Color(0xFFFF70A6),
                    fontSize: 9.5,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text('VOLT: ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 8, fontFamily: 'monospace')),
                    Text(
                      '${liveVolt.toStringAsFixed(3)} V',
                      style: TextStyle(
                        color: isFullColor ? const Color(0xFF00E5FF) : Colors.white,
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
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
        child: LayoutBuilder(builder: (context, constraints) => buildContent(constraints)),
      );
    }

    return AppTheme.buildPanel(
      activeColor: widget.activeColor,
      child: LayoutBuilder(
        builder: (context, constraints) => buildContent(constraints),
      ),
    );
  }
}

/// Custom Painter Pengukur Arus Jarum Analog USB (Ammeter Dial 3.0A)
class UsbAnalogGaugePainter extends CustomPainter {
  final double currentAmp;
  final double maxAmp;
  final Color accentColor;

  const UsbAnalogGaugePainter({
    required this.currentAmp,
    required this.maxAmp,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final center = Offset(size.width / 2, size.height * 0.95);
    final radius = math.min(size.width * 0.48, size.height * 0.88);

    const startAngleDeg = 205.0;
    const sweepAngleDeg = 130.0;
    final startRad = startAngleDeg * (math.pi / 180.0);
    final totalRad = sweepAngleDeg * (math.pi / 180.0);

    // 1. Dial Background
    final dialRect = Rect.fromCircle(center: center, radius: radius);
    final dialBgPaint = Paint()
      ..color = const Color(0xFF0D1117)
      ..style = PaintingStyle.fill;
    final dialArcPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(dialRect, startRad, totalRad, false)
      ..close();
    canvas.drawPath(dialArcPath, dialBgPaint);

    // 2. Dial Outer Track
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

    // 3. Tick Marks
    const totalDivisions = 30;
    for (int i = 0; i <= totalDivisions; i++) {
      final fraction = i / totalDivisions;
      final angle = startRad + (totalRad * fraction);
      final isMajor = (i % 10 == 0);
      final isMedium = (i % 5 == 0 && !isMajor);

      final tickLength = isMajor ? 8.5 : (isMedium ? 5.5 : 3.0);
      final tickColor = isMajor ? accentColor : (isMedium ? Colors.white60 : Colors.white30);

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
        ..strokeWidth = isMajor ? 1.5 : (isMedium ? 1.0 : 0.7);
      canvas.drawLine(p1, p2, tickPaint);

      if (isMajor) {
        final val = (fraction * maxAmp).toInt();
        final textSpan = TextSpan(
          text: '$val A',
          style: TextStyle(
            color: tickColor,
            fontSize: 7.5,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        );
        final tp = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();

        final labelRadius = radius - 17.0;
        final labelPos = Offset(
          center.dx + labelRadius * math.cos(angle) - (tp.width / 2),
          center.dy + labelRadius * math.sin(angle) - (tp.height / 2),
        );
        tp.paint(canvas, labelPos);
      }
    }

    // 4. Unit Span
    final unitSpan = const TextSpan(
      text: 'USB CURRENT (MAX 3.0A)',
      style: TextStyle(
        color: Colors.white38,
        fontSize: 7.0,
        letterSpacing: 1.0,
        fontWeight: FontWeight.bold,
        fontFamily: 'monospace',
      ),
    );
    final unitTp = TextPainter(
      text: unitSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    unitTp.paint(
      canvas,
      Offset(center.dx - (unitTp.width / 2), center.dy - (radius * 0.45)),
    );

    // 5. Needle
    final clampedCurrent = currentAmp.clamp(0.0, maxAmp);
    final currentFraction = clampedCurrent / maxAmp;
    final needleAngle = startRad + (totalRad * currentFraction);

    final needleLength = radius * 0.88;
    final needleTip = Offset(
      center.dx + needleLength * math.cos(needleAngle),
      center.dy + needleLength * math.sin(needleAngle),
    );

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx + 2, center.dy + 2),
      Offset(needleTip.dx + 2, needleTip.dy + 2),
      shadowPaint,
    );

    final needlePaint = Paint()
      ..color = const Color(0xFFFF5252)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, needleTip, needlePaint);

    final tailTip = Offset(
      center.dx - 10 * math.cos(needleAngle),
      center.dy - 10 * math.sin(needleAngle),
    );
    final tailPaint = Paint()
      ..color = Colors.white54
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, tailTip, tailPaint);

    final pivotBasePaint = Paint()..color = const Color(0xFF1E2630);
    canvas.drawCircle(center, 7.0, pivotBasePaint);

    final pivotBorderPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, 7.0, pivotBorderPaint);

    final pivotCenterPaint = Paint()..color = const Color(0xFFFF5252);
    canvas.drawCircle(center, 3.0, pivotCenterPaint);
  }

  @override
  bool shouldRepaint(covariant UsbAnalogGaugePainter oldDelegate) {
    return oldDelegate.currentAmp != currentAmp ||
        oldDelegate.maxAmp != maxAmp ||
        oldDelegate.accentColor != accentColor;
  }
}
