import 'package:flutter/material.dart';
import 'probe_models.dart';
import 'probe_page1_multimeter.dart';
import 'probe_page2_graph.dart';
import '../psu_udp_service.dart';

class ProbePanelView extends StatefulWidget {
  final Color activeColor;
  final String themeName;

  const ProbePanelView({
    super.key,
    required this.activeColor,
    this.themeName = 'WIREFRAME',
  });

  @override
  State<ProbePanelView> createState() => _ProbePanelViewState();
}

class _ProbePanelViewState extends State<ProbePanelView> {
  final PageController _probePageController = PageController();
  int _probeActivePageIndex = 0;

  String _probeMode = 'VOLT'; // 'VOLT', 'DIODA', 'RESISTOR'
  bool _isProbeShort = false;

  final List<ProbeHistoryItem> _probeHistory = [
    const ProbeHistoryItem(time: '16:20:05', mode: 'DIODA', value: '0.412', note: 'VDD_MAIN OK'),
    const ProbeHistoryItem(time: '16:21:12', mode: 'VOLT', value: '3.780 V', note: 'VREG_LDO5'),
    const ProbeHistoryItem(time: '16:22:45', mode: 'RES', value: '10.2 kΩ', note: 'PULL-UP I2C'),
    const ProbeHistoryItem(time: '16:24:01', mode: 'DIODA', value: '000', note: 'SHORT TO GND'),
  ];

  @override
  void initState() {
    super.initState();
    PsuUdpService.instance.dataNotifier.addListener(_onDataUpdated);
  }

  void _onDataUpdated() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    PsuUdpService.instance.dataNotifier.removeListener(_onDataUpdated);
    _probePageController.dispose();
    super.dispose();
  }

  String get _probeStatusSubtitle {
    switch (_probeMode) {
      case 'DIODA':
        return 'PENGUKURAN DIODA (FORWARD BIAS)';
      case 'RESISTOR':
        return 'PENGUJIAN HAMBATAN JALUR RESISTOR';
      case 'VOLT':
      default:
        return 'PENGUKURAN TEGANGAN DC PROBE (INA3221 CH1)';
    }
  }

  String get _probeCurrentDisplayValue {
    // Mode VOLT Probe dihubungkan ke sensor INA3221 CH1 (v1)
    final liveV1 = PsuUdpService.instance.dataNotifier.value.v1;
    switch (_probeMode) {
      case 'DIODA':
        return '0.458';
      case 'RESISTOR':
        return '4.70 kΩ';
      case 'VOLT':
      default:
        return '${liveV1.toStringAsFixed(3)} V';
    }
  }

  void _recordMeasurement() {
    setState(() {
      _probeHistory.insert(
        0,
        ProbeHistoryItem(
          time: 'LIVE',
          mode: _probeMode == 'RESISTOR' ? 'RES' : _probeMode,
          value: _probeCurrentDisplayValue,
          note: 'MANUAL CAPTURE',
        ),
      );
    });
  }

  void _clearHistory() {
    setState(() => _probeHistory.clear());
  }

  void _goToPage(int page) {
    _probePageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _probePageController,
      onPageChanged: (idx) {
        setState(() => _probeActivePageIndex = idx);
      },
      children: [
        // Halaman 1: MULTIMETER PROBE LENGKAP
        ProbePage1MultimeterView(
          activeColor: widget.activeColor,
          themeName: widget.themeName,
          probeMode: _probeMode,
          isProbeShort: _isProbeShort,
          probeStatusSubtitle: _probeStatusSubtitle,
          probeCurrentDisplayValue: _probeCurrentDisplayValue,
          probeHistory: _probeHistory,
          onModeChanged: (mode) => setState(() => _probeMode = mode),
          onToggleShort: () => setState(() => _isProbeShort = !_isProbeShort),
          onRecordMeasurement: _recordMeasurement,
          onClearHistory: _clearHistory,
          onNavigateToGraph: () => _goToPage(1),
        ),

        // Halaman 2: GRAFIK SIGNAL LOGIC PROBE
        ProbePage2GraphView(
          activeColor: widget.activeColor,
          themeName: widget.themeName,
          probeMode: _probeMode,
          onNavigateBack: () => _goToPage(0),
        ),
      ],
    );
  }
}
