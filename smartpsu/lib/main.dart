import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';
import 'psu_panel.dart';
import 'oscilloscope_view.dart';
import 'usb_view.dart';
import 'probe_view.dart';
import 'uart_view.dart';
import 'settings_view.dart';
import 'hardware_test_view.dart';
import 'psu_udp_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Kunci orientasi ke Landscape murni
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Mode Immersive Sticky: Navigasi & Status Bar tersembunyi total
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const SmartPsuApp());
}

class SmartPsuApp extends StatelessWidget {
  const SmartPsuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartPSU Analyzer',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        scrollbars: false,
        overscroll: false,
      ),
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const AbstractLayoutScreen(),
    );
  }
}

class AbstractLayoutScreen extends StatefulWidget {
  const AbstractLayoutScreen({super.key});

  @override
  State<AbstractLayoutScreen> createState() => _AbstractLayoutScreenState();
}

class _AbstractLayoutScreenState extends State<AbstractLayoutScreen> {
  // OCP state
  bool _ocpEnabled = true;
  double _ocpLimit = 2.0;

  // Active Menu: 'USB', 'PSU', 'PROBE', 'UART', 'SETTINGS'
  String _activeMenu = 'PSU';

  // Oscilloscope waveform mode: 'ARUS', 'VOLTASE', 'DAYA', 'SEMUA'
  String _graphMode = 'ARUS';

  // Theme & font (Default: FULL_COLOR)
  String _themeName = 'FULL_COLOR'; // 'FULL_COLOR', 'WIREFRAME', 'CYBER_BLUE', 'MATRIX_GREEN', 'AMBER_WARM'
  String _selectedFont = 'monospace';
  String _marqueeText = 'NURHADI-SMARTPSU PRO V1.0.0- IDS STORE TECHNOLOGY';
  int _marqueeSpeedSeconds = 18;

  // Sidebar toggle & auto-hide handle
  bool _sidebarExpanded = true;
  bool _showArrowHandle = true;
  Timer? _arrowHideTimer;

  // Screen management
  static const MethodChannel _screenChannel = MethodChannel('com.smartpsu/screen_manager');
  bool _keepScreenAwake = true;
  bool _isScreenDimmed = false;
  int _dimTimeoutSeconds = 0;
  DateTime _lastUserActivity = DateTime.now();
  Timer? _autoDimTimer;

  // Live telemetry via UDP Service
  final PsuUdpService _udpService = PsuUdpService.instance;
  double _psuLiveVolt = 0.0;
  double _psuLiveAmp = 0.0;
  bool _isConnected = false;

  Color get _activeThemeColor => AppTheme.getColor(_themeName);

  @override
  void initState() {
    super.initState();
    _applyKeepAwake(_keepScreenAwake);
    _autoDimTimer = Timer.periodic(const Duration(seconds: 1), (_) => _checkAutoDim());
    _resetArrowAutoHideTimer();

    // Start UDP Service & dengarkan data live secara efisien
    _udpService.start(port: 4210);

    _udpService.connectionNotifier.addListener(_onConnectionChanged);
    _udpService.dataNotifier.addListener(_onTelemetryChanged);
  }

  void _onConnectionChanged() {
    if (mounted) {
      setState(() {
        _isConnected = _udpService.isConnected;
      });
    }
  }

  double _usbLiveVolt = 0.0;
  double _usbLiveAmp = 0.0;
  double _usbDp = 0.0;
  double _usbDm = 0.0;

  void _onTelemetryChanged() {
    final cur = _udpService.dataNotifier.value;
    if (mounted) {
      setState(() {
        // CH2 -> PSU
        _psuLiveVolt = cur.v2;
        _psuLiveAmp = cur.i2 / 1000.0; // mA ke A

        // CH3 -> USB Charging
        _usbLiveVolt = cur.v3;
        _usbLiveAmp = cur.i3 / 1000.0; // mA ke A
        _usbDp = cur.dp;
        _usbDm = cur.dm;
      });
    }
  }

  @override
  void dispose() {
    _udpService.connectionNotifier.removeListener(_onConnectionChanged);
    _udpService.dataNotifier.removeListener(_onTelemetryChanged);
    _autoDimTimer?.cancel();
    _arrowHideTimer?.cancel();
    super.dispose();
  }

  void _resetArrowAutoHideTimer() {
    _arrowHideTimer?.cancel();
    if (!_showArrowHandle) {
      setState(() => _showArrowHandle = true);
    }
    _arrowHideTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        setState(() => _showArrowHandle = false);
      }
    });
  }

  Future<void> _applyKeepAwake(bool enable) async {
    try {
      await _screenChannel.invokeMethod('keepOn', {'enable': enable});
    } catch (_) {}
  }

  void _onUserInteraction() {
    _lastUserActivity = DateTime.now();
    if (_isScreenDimmed) {
      setState(() => _isScreenDimmed = false);
      try {
        _screenChannel.invokeMethod('setDimLevel', {'brightness': -1.0});
      } catch (_) {}
    }
  }

  void _checkAutoDim() {
    if (!_keepScreenAwake || _dimTimeoutSeconds <= 0 || _isScreenDimmed) return;
    final diff = DateTime.now().difference(_lastUserActivity).inSeconds;
    if (diff >= _dimTimeoutSeconds) {
      setState(() => _isScreenDimmed = true);
      try {
        _screenChannel.invokeMethod('setDimLevel', {'brightness': 0.01});
      } catch (_) {}
    }
  }

  Widget _buildMenuItem({
    required String id,
    required String label,
    required IconData icon,
  }) {
    final bool isSelected = _activeMenu == id;
    final bool isFullColor = _themeName == 'FULL_COLOR';

    Color itemColor;
    if (isFullColor) {
      switch (id) {
        case 'USB':
          itemColor = const Color(0xFF00E5FF); // Electric Cyan
          break;
        case 'PSU':
          itemColor = const Color(0xFFFF007F); // Neon Rose / Magenta
          break;
        case 'PROBE':
          itemColor = const Color(0xFF00FF88); // Neon Mint / Emerald
          break;
        case 'UART':
          itemColor = const Color(0xFFFFEA00); // Electric Yellow
          break;
        case 'TEST':
          itemColor = const Color(0xFFFF6D00); // Neon Deep Orange / Hardware
          break;
        case 'SETTINGS':
        default:
          itemColor = const Color(0xFFA855F7); // Neon Purple
          break;
      }
    } else {
      itemColor = _activeThemeColor;
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _activeMenu = id);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: isFullColor
            ? const BoxDecoration(color: Colors.transparent) // Murni tanpa background panel apapun
            : BoxDecoration(
                color: isSelected ? _activeThemeColor.withOpacity(0.18) : Colors.transparent,
                border: Border.all(
                  color: isSelected ? itemColor : Colors.white24,
                  width: isSelected ? 1.2 : 0.8,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? itemColor
                  : (isFullColor ? const Color(0xFF475569) : Colors.white60), // Muted slate saat nonaktif
              size: isSelected && isFullColor ? 22 : 20,
              shadows: (isFullColor && isSelected)
                  ? [
                      Shadow(
                        color: itemColor.withOpacity(0.85),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? itemColor
                    : (isFullColor ? const Color(0xFF64748B) : Colors.white70),
                fontSize: isSelected && isFullColor ? 9.5 : 9,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal,
                fontFamily: 'monospace',
                letterSpacing: 0.8,
                shadows: (isFullColor && isSelected)
                    ? [
                        Shadow(
                          color: itemColor.withOpacity(0.75),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveContent() {
    switch (_activeMenu) {
      case 'SETTINGS':
        return SettingsView(
          activeColor: _activeThemeColor,
          themeName: _themeName,
          selectedFont: _selectedFont,
          keepScreenAwake: _keepScreenAwake,
          dimTimeoutSeconds: _dimTimeoutSeconds,
          marqueeText: _marqueeText,
          marqueeSpeedSeconds: _marqueeSpeedSeconds,
          onThemeChanged: (val) => setState(() => _themeName = val),
          onFontChanged: (val) => setState(() => _selectedFont = val),
          onKeepScreenAwakeChanged: (val) {
            setState(() => _keepScreenAwake = val);
            _applyKeepAwake(val);
          },
          onDimTimeoutChanged: (val) => setState(() => _dimTimeoutSeconds = val),
          onMarqueeTextChanged: (val) => setState(() => _marqueeText = val),
          onMarqueeSpeedChanged: (val) => setState(() => _marqueeSpeedSeconds = val),
        );
      case 'PROBE':
        return ProbePanelView(
          activeColor: _activeThemeColor,
          themeName: _themeName,
        );
      case 'UART':
        return UartTerminalView(activeColor: _activeThemeColor);
      case 'TEST':
        return HardwareTestView(
          activeColor: _activeThemeColor,
          themeName: _themeName,
        );
      case 'USB':
        return UsbPanelView(
          activeColor: _activeThemeColor,
          themeName: _themeName,
          oscilloscopeWidget: OscilloscopePanelView(
            activeColor: _activeThemeColor,
            themeName: _themeName,
            graphMode: _graphMode,
            onGraphModeChanged: (mode) => setState(() => _graphMode = mode),
          ),
        );
      case 'PSU':
      default:
        return PsuPanelView(
          activeColor: _activeThemeColor,
          themeName: _themeName,
          liveVolt: _psuLiveVolt,
          liveAmp: _psuLiveAmp,
          ocpEnabled: _ocpEnabled,
          ocpLimit: _ocpLimit,
          onOcpEnabledChanged: (val) => setState(() => _ocpEnabled = val),
          onOcpLimitChanged: (val) => setState(() => _ocpLimit = val),
          oscilloscopeWidget: OscilloscopePanelView(
            activeColor: _activeThemeColor,
            themeName: _themeName,
            graphMode: _graphMode,
            onGraphModeChanged: (mode) => setState(() => _graphMode = mode),
            currentAmp: _psuLiveAmp,
            currentVolt: _psuLiveVolt,
            currentWatt: _psuLiveVolt * _psuLiveAmp,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _onUserInteraction(),
      onPointerMove: (_) => _onUserInteraction(),
      child: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  children: [
                    // TOP BAR
                    _themeName == 'FULL_COLOR'
                        ? Container(
                            height: 32,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF141224), // Ambient dark purple-slate
                                  Color(0xFF0F172A), // Midnight slate
                                  Color(0xFF101C2B), // Ambient dark cyan-slate
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            child: Row(
                              children: [
                                // 1. PALING KIRI: BADGE IDS STORE TECHNOLOGY
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF00E5FF), Color(0xFF0051FF)],
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00E5FF).withOpacity(0.35),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.memory, color: Colors.white, size: 12),
                                      SizedBox(width: 4),
                                      Text(
                                        'IDS STORE TECHNOLOGY',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.2,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // 2. SEBELAHNYA: BADGE SMARTPSU PRO
                                Container(
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
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.bolt, color: Colors.white, size: 12),
                                      SizedBox(width: 3.5),
                                      Text(
                                        'SMARTPSU PRO',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.2,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const Spacer(),

                                // SISI KANAN: STATUS KONEKSI ELEGAN
                                ValueListenableBuilder<bool>(
                                  valueListenable: _udpService.connectionNotifier,
                                  builder: (context, connected, _) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: connected
                                              ? [const Color(0xFF00E676), const Color(0xFF00B0FF)]
                                              : [const Color(0xFFFF1744), const Color(0xFFFF5252)],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (connected ? const Color(0xFF00E676) : Colors.redAccent).withOpacity(0.35),
                                            blurRadius: 6,
                                            spreadRadius: 0.5,
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            connected ? Icons.wifi : Icons.wifi_off,
                                            color: Colors.black,
                                            size: 11,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            connected ? 'CONNECTED' : 'OFFLINE',
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 8.5,
                                              fontFamily: 'monospace',
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          )
                        : AppTheme.buildPanel(
                            height: 32,
                            activeColor: _activeThemeColor,
                            child: Row(
                              children: [
                                Expanded(
                                  child: ClipRect(
                                    child: _RunningTextMarquee(
                                      text: _marqueeText,
                                      color: _activeThemeColor,
                                      speedSeconds: _marqueeSpeedSeconds,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _isConnected
                                        ? Colors.greenAccent.withOpacity(0.15)
                                        : Colors.redAccent.withOpacity(0.15),
                                    border: Border.all(
                                      color: _isConnected ? Colors.greenAccent : Colors.redAccent,
                                      width: 0.8,
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _isConnected ? Icons.wifi : Icons.wifi_off,
                                        color: _isConnected ? Colors.greenAccent : Colors.redAccent,
                                        size: 9,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _isConnected ? 'CONNECTED' : 'OFFLINE',
                                        style: TextStyle(
                                          color: _isConnected ? Colors.greenAccent : Colors.redAccent,
                                          fontSize: 7.5,
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
                    const SizedBox(height: 4),

                    // MAIN WORKSPACE
                    Expanded(
                      child: Row(
                        children: [
                          if (_sidebarExpanded) ...[
                            SizedBox(
                              width: 58,
                              child: _themeName == 'FULL_COLOR'
                                  ? Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10131F),
                                        borderRadius: BorderRadius.circular(5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.4),
                                            blurRadius: 8,
                                            offset: const Offset(1, 1),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
                                      child: Column(
                                        children: [
                                          _buildMenuItem(id: 'USB', label: 'USB', icon: Icons.usb),
                                          const SizedBox(height: 5),
                                          _buildMenuItem(id: 'PSU', label: 'PSU', icon: Icons.flash_on),
                                          const SizedBox(height: 5),
                                          _buildMenuItem(id: 'PROBE', label: 'PROBE', icon: Icons.tune),
                                          const SizedBox(height: 5),
                                          _buildMenuItem(id: 'UART', label: 'UART', icon: Icons.terminal),
                                          const SizedBox(height: 5),
                                          _buildMenuItem(id: 'TEST', label: 'TEST', icon: Icons.build_circle),
                                          const Spacer(),
                                          _buildMenuItem(id: 'SETTINGS', label: 'SET', icon: Icons.settings),
                                        ],
                                      ),
                                    )
                                  : AppTheme.buildPanel(
                                      activeColor: _activeThemeColor,
                                      child: Column(
                                        children: [
                                          _buildMenuItem(id: 'USB', label: 'USB', icon: Icons.usb),
                                          const SizedBox(height: 5),
                                          _buildMenuItem(id: 'PSU', label: 'PSU', icon: Icons.flash_on),
                                          const SizedBox(height: 5),
                                          _buildMenuItem(id: 'PROBE', label: 'PROBE', icon: Icons.tune),
                                          const SizedBox(height: 5),
                                          _buildMenuItem(id: 'UART', label: 'UART', icon: Icons.terminal),
                                          const SizedBox(height: 5),
                                          _buildMenuItem(id: 'TEST', label: 'TEST', icon: Icons.build_circle),
                                          const Spacer(),
                                          _buildMenuItem(id: 'SETTINGS', label: 'SET', icon: Icons.settings),
                                        ],
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Expanded(child: _buildActiveContent()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Area Deteksi Khusus Swipe dari Tepi Kiri
            if (!_sidebarExpanded)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 35,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragUpdate: (details) {
                    if (details.primaryDelta != null && details.primaryDelta! > 3) {
                      _resetArrowAutoHideTimer();
                    }
                  },
                ),
              )
            else
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 75,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragUpdate: (details) {
                    if (details.primaryDelta != null && details.primaryDelta!.abs() > 3) {
                      _resetArrowAutoHideTimer();
                    }
                  },
                ),
              ),

            // Tombol Segitiga Buka/Tutup Menu Auto-Hide
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubic,
              left: _sidebarExpanded ? 64 : 0,
              top: 0,
              bottom: 0,
              child: AnimatedOpacity(
                opacity: _showArrowHandle ? 0.95 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      setState(() {
                        _sidebarExpanded = !_sidebarExpanded;
                        _resetArrowAutoHideTimer();
                      });
                    },
                    child: Container(
                      width: 20,
                      height: 58,
                      decoration: BoxDecoration(
                        color: const Color(0xFF161616),
                        border: Border.all(
                          color: _activeThemeColor,
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.only(
                          topRight: const Radius.circular(8),
                          bottomRight: const Radius.circular(8),
                          topLeft: _sidebarExpanded ? const Radius.circular(3) : Radius.zero,
                          bottomLeft: _sidebarExpanded ? const Radius.circular(3) : Radius.zero,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _activeThemeColor.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(1, 0),
                          ),
                        ],
                      ),
                      child: Center(
                        child: CustomPaint(
                          size: const Size(9, 14),
                          painter: _TrianglePainter(
                            color: _activeThemeColor,
                            pointLeft: _sidebarExpanded,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Overlay Screen Dimmed
            if (_isScreenDimmed)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _onUserInteraction,
                  child: Container(
                    color: Colors.black.withOpacity(0.85),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.touch_app, color: Colors.white38, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'LAYAR MEREDUP (SENTUH DI MANA SAJA UNTUK BANGUN)',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                            fontFamily: 'monospace',
                            letterSpacing: 1.0,
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
    );
  }
}

/// Custom Painter Segitiga Presisi
class _TrianglePainter extends CustomPainter {
  final Color color;
  final bool pointLeft;

  const _TrianglePainter({
    required this.color,
    required this.pointLeft,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path();
    if (pointLeft) {
      path.moveTo(0, size.height / 2);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(size.width, size.height / 2);
      path.lineTo(0, 0);
      path.lineTo(0, size.height);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.pointLeft != pointLeft;
  }
}

/// Widget Teks Berjalan Animasi Halus Tanpa Jeda
class _RunningTextMarquee extends StatefulWidget {
  final String text;
  final Color color;
  final int speedSeconds;
  final bool isFullColor;

  const _RunningTextMarquee({
    required this.text,
    required this.color,
    this.speedSeconds = 18,
    this.isFullColor = false,
  });

  @override
  State<_RunningTextMarquee> createState() => _RunningTextMarqueeState();
}

class _RunningTextMarqueeState extends State<_RunningTextMarquee> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _periodWidth = 0;
  static const double _gapWidth = 60.0;

  @override
  void initState() {
    super.initState();
    _calculatePeriodWidth();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.speedSeconds),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant _RunningTextMarquee oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speedSeconds != widget.speedSeconds) {
      _controller.duration = Duration(seconds: widget.speedSeconds);
      if (_controller.isAnimating) {
        _controller.repeat();
      }
    }
    if (oldWidget.text != widget.text) {
      _calculatePeriodWidth();
    }
  }

  void _calculatePeriodWidth() {
    final textPainter = TextPainter(
      text: TextSpan(
        text: widget.text,
        style: TextStyle(
          color: widget.color,
          fontSize: 9.2,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    setState(() {
      _periodWidth = textPainter.width + _gapWidth;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_periodWidth <= 0) return const SizedBox.shrink();

    final textStyle = TextStyle(
      color: widget.isFullColor ? const Color(0xFF00F5D4) : widget.color,
      fontSize: 9.2,
      fontFamily: 'monospace',
      fontWeight: FontWeight.w900,
      letterSpacing: 0.9,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offset = -(_controller.value * _periodWidth);
        return OverflowBox(
          minWidth: 0,
          maxWidth: double.infinity,
          alignment: Alignment.centerLeft,
          child: Transform.translate(
            offset: Offset(offset, 0),
            child: child,
          ),
        );
      },
      child: RepaintBoundary(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.text, style: textStyle),
            const SizedBox(width: _gapWidth),
            Text(widget.text, style: textStyle),
            const SizedBox(width: _gapWidth),
            Text(widget.text, style: textStyle),
            const SizedBox(width: _gapWidth),
          ],
        ),
      ),
    );
  }
}
