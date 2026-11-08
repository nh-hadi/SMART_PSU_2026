import 'package:flutter/material.dart';
import 'psu/psu_page1_standard.dart';
import 'psu/psu_page2_waveform.dart';
import 'psu/psu_page3_dashboard.dart';

export 'psu/psu.dart';

class PsuPanelView extends StatefulWidget {
  final Color activeColor;
  final String themeName;
  final Widget? oscilloscopeWidget;
  final double liveVolt;
  final double liveAmp;
  final bool ocpEnabled;
  final double ocpLimit;
  final Function(bool) onOcpEnabledChanged;
  final Function(double) onOcpLimitChanged;

  const PsuPanelView({
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
  });

  @override
  State<PsuPanelView> createState() => _PsuPanelViewState();
}

class _PsuPanelViewState extends State<PsuPanelView> {
  final PageController _rootPageController = PageController();

  @override
  void dispose() {
    _rootPageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _rootPageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Jika tidak ada oscilloscopeWidget yang dipass, langsung tampilkan PsuPage1View
    if (widget.oscilloscopeWidget == null) {
      return PsuPage1View(
        activeColor: widget.activeColor,
        themeName: widget.themeName,
        oscilloscopeWidget: null,
        liveVolt: widget.liveVolt,
        liveAmp: widget.liveAmp,
        ocpEnabled: widget.ocpEnabled,
        ocpLimit: widget.ocpLimit,
        onOcpEnabledChanged: widget.onOcpEnabledChanged,
        onOcpLimitChanged: widget.onOcpLimitChanged,
        onNavigateToPage2: () => _goToPage(1),
        onNavigateToPage3: () => _goToPage(2),
      );
    }

    return PageView(
      controller: _rootPageController,
      children: [
        // Halaman 1: Tampilan Standar (Panel 2 Kiri + Panel 3 Grafik Kanan)
        PsuPage1View(
          activeColor: widget.activeColor,
          themeName: widget.themeName,
          oscilloscopeWidget: widget.oscilloscopeWidget,
          liveVolt: widget.liveVolt,
          liveAmp: widget.liveAmp,
          ocpEnabled: widget.ocpEnabled,
          ocpLimit: widget.ocpLimit,
          onOcpEnabledChanged: widget.onOcpEnabledChanged,
          onOcpLimitChanged: widget.onOcpLimitChanged,
          onNavigateToPage2: () => _goToPage(1),
          onNavigateToPage3: () => _goToPage(2),
        ),

        // Halaman 2: LAYAR PENUH MULTI-INSTRUMENT DASHBOARD (Persis Gambar Referensi User)
        PsuPage3DashboardView(
          activeColor: widget.activeColor,
          themeName: widget.themeName,
          liveVolt: widget.liveVolt,
          liveAmp: widget.liveAmp,
          ocpLimit: widget.ocpLimit,
          onBack: () => _goToPage(0),
        ),

        // Halaman 3: LAYAR PENUH (Analog Meter + WaveFormSamp Logic)
        PsuPage2WaveformView(
          activeColor: widget.activeColor,
          liveVolt: widget.liveVolt,
          liveAmp: widget.liveAmp,
          ocpLimit: widget.ocpLimit,
          onBack: () => _goToPage(0),
        ),
      ],
    );
  }
}
