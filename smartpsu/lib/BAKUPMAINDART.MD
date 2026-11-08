import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Kunci orientasi ke Landscape murni
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Mode Immersive Sticky: Navigasi & Status Bar tersembunyi total, muncul hanya saat di-swipe
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
  // Mock state untuk toggle switch OCP & batas limit (Max 10A)
  bool _ocpEnabled = true;
  double _ocpLimit = 2.0;

  // Menu Aktif: 'USB', 'PSU', 'PROBE', 'SETTINGS'
  String _activeMenu = 'PSU';

  // Mode kurva grafik yang ditampilkan: 'ARUS', 'VOLT', 'DAYA', 'SEMUA'
  String _graphMode = 'ARUS';

  // Mode Pengukuran Probe: 'VOLT', 'DIODA', 'RESISTOR'
  String _probeMode = 'VOLT';

  // Indikator Short Circuit (Nilai mendekati 0.000 V / Hambatan Drop ke GND)
  bool _isProbeShort = false;

  // Riwayat Pengukuran Probe AVO
  final List<Map<String, String>> _probeHistory = [
    {'time': '16:20:05', 'mode': 'DIODA', 'value': '0.412', 'note': 'VDD_MAIN OK'},
    {'time': '16:21:12', 'mode': 'VOLT', 'value': '3.780 V', 'note': 'VREG_LDO5'},
    {'time': '16:22:45', 'mode': 'RES', 'value': '10.2 kΩ', 'note': 'PULL-UP I2C'},
    {'time': '16:24:01', 'mode': 'DIODA', 'value': '000', 'note': 'SHORT TO GND'},
  ];

  // State Pengaturan (SETTINGS)
  String _esp12Ip = '192.168.4.1';
  String _esp12Port = '4210';
  String _aiServerUrl = 'https://api.smartpsu.ai/v1/diagnose';
  String _selectedFont = 'monospace';
  String _firmwareVersion = 'v1.0.4-ESP12';
  // State Tema Tampilan (THEME PALETTE)
  String _themeName = 'WIREFRAME'; // 'WIREFRAME', 'CYBER_BLUE', 'MATRIX_GREEN', 'AMBER_WARM'

  // State Sidebar Menu (Bisa buka / tutup dengan tombol panah segitiga auto-hide)
  bool _sidebarExpanded = true;
  bool _showArrowHandle = true;
  Timer? _arrowHideTimer;

  // State Developer Mode
  bool _devUnlocked = false; // Terbuka setelah memasukkan password yang benar
  bool _devModeEnabled = true;
  bool _showRawPackets = false;
  bool _simulateHardware = true;

  // State Manajemen Layar (Keep Screen Awake & Auto Dim Tanpa Lock)
  static const MethodChannel _screenChannel = MethodChannel('com.smartpsu/screen_manager');
  bool _keepScreenAwake = true;
  bool _isScreenDimmed = false;
  int _dimTimeoutSeconds = 0; // Default 0: Jangan Redup (agar layar tidak redup sendiri saat dipakai)
  DateTime _lastUserActivity = DateTime.now();
  Timer? _autoDimTimer;

  // State 4-Channel USB Charging Control
  int _selectedUsbChannel = 1;
  final PageController _usbPageController = PageController();
  final List<Map<String, dynamic>> _usbChannelsData = [
    {
      'ch': 1,
      'name': 'CH 1 (QC 3.0)',
      'volt': '5.120 V',
      'amp': '1.850 A',
      'watt': '9.472 W',
      'mah': '1420 mAh',
      'wh': '7.10 Wh',
      'dp': '2.71 V',
      'dm': '2.71 V',
      'protocol': 'APPLE 2.4A',
      'active': true,
    },
    {
      'ch': 2,
      'name': 'CH 2 (PD 20W)',
      'volt': '9.080 V',
      'amp': '2.210 A',
      'watt': '20.066 W',
      'mah': '850 mAh',
      'wh': '7.65 Wh',
      'dp': '0.02 V',
      'dm': '0.02 V',
      'protocol': 'PD 3.0 (9V)',
      'active': true,
    },
    {
      'ch': 3,
      'name': 'CH 3 (TURBO)',
      'volt': '5.200 V',
      'amp': '1.540 A',
      'watt': '8.008 W',
      'mah': '960 mAh',
      'wh': '4.99 Wh',
      'dp': '2.00 V',
      'dm': '2.00 V',
      'protocol': 'QC 2.0',
      'active': true,
    },
    {
      'ch': 4,
      'name': 'CH 4 (STD 5V)',
      'volt': '5.180 V',
      'amp': '0.980 A',
      'watt': '5.076 W',
      'mah': '2310 mAh',
      'wh': '11.96 Wh',
      'dp': '1.98 V',
      'dm': '1.98 V',
      'protocol': 'DCP 1.5A',
      'active': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _applyKeepAwake(_keepScreenAwake);
    // Jalankan timer periodik setiap 1 detik untuk mendeteksi timeout auto-dim
    _autoDimTimer = Timer.periodic(const Duration(seconds: 1), (_) => _checkAutoDim());
    _resetArrowAutoHideTimer();
  }

  @override
  void dispose() {
    _autoDimTimer?.cancel();
    _arrowHideTimer?.cancel();
    _psuPageController.dispose();
    _probePageController.dispose();
    _usbPageController.dispose();
    super.dispose();
  }

  void _resetArrowAutoHideTimer() {
    _arrowHideTimer?.cancel();
    if (!_showArrowHandle) {
      setState(() => _showArrowHandle = true);
    }
    // Baik sidebar terbuka atau tertutup, tombol segitiga otomatis memudar setelah 3.5 detik
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
        _screenChannel.invokeMethod('setDimLevel', {'brightness': -1.0}); // Reset ke normal
      } catch (_) {}
    }
  }

  void _checkAutoDim() {
    if (!_keepScreenAwake || _dimTimeoutSeconds <= 0 || _isScreenDimmed) return;
    final diff = DateTime.now().difference(_lastUserActivity).inSeconds;
    if (diff >= _dimTimeoutSeconds) {
      setState(() => _isScreenDimmed = true);
      try {
        _screenChannel.invokeMethod('setDimLevel', {'brightness': 0.01}); // Redupkan ke level minimum
      } catch (_) {}
    }
  }

  // Controller untuk swipe / geser tampilan Panel PSU (0: Standard 3 Baris, 1: Volt & Ampere Saja, 2: Analog Ampere Meter)
  final PageController _psuPageController = PageController();
  int _psuActivePageIndex = 0;
  double _psuLiveVolt = 4.200;
  double _psuLiveAmp = 1.340;

  // Controller untuk swipe / geser antara Panel Multimeter Besar & Panel Grafik di menu PROBE
  final PageController _probePageController = PageController();
  int _probeActivePageIndex = 0;

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
              // ==========================================
              // TOP BAR: TEKS BERJALAN (KIRI) & STATUS KONEKSI (KANAN)
              // ==========================================
              _buildPanel(
                height: 32,
                child: Row(
                  children: [
                    // Sisi Kiri: Running Text Berjalan Mulus
                    Expanded(
                      child: ClipRect(
                        child: _RunningTextMarquee(
                          text: '★ NURHADI  |  IDS STORE TECHNOLOGY  |  WWW.NURHADI.CLOUD  |  SMART-PSU ANALYZER HARDWARE SYSTEM  ★',
                          color: _activeThemeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Pemisah Vertikal Halus
                    Container(
                      width: 1,
                      height: 14,
                      color: Colors.white24,
                    ),
                    const SizedBox(width: 8),

                    // Sisi Kanan: Status Ikon WiFi, UDP, Hardware
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon WiFi + IP
                        const Icon(Icons.wifi, color: Colors.greenAccent, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '$_esp12Ip:$_esp12Port',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 8.5,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Chip UDP Connected
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withOpacity(0.15),
                            border: Border.all(color: Colors.greenAccent, width: 0.8),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.link, color: Colors.greenAccent, size: 9),
                              SizedBox(width: 3),
                              Text(
                                'UDP CONNECTED',
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 7.5,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Chip INA3221
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            border: Border.all(color: Colors.white24, width: 0.8),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Text(
                            'INA3221',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 7.5,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),

              // ==========================================
              // MAIN WORKSPACE (PANEL UTAMA)
              // ==========================================
              Expanded(
                child: Row(
                  children: [
                    // ------------------------------------------
                    // 1. PANEL PALING KIRI: ICON MENU (BISA TUTUP TOTAL TANPA SISA)
                    // ------------------------------------------
                    if (_sidebarExpanded) ...[
                      SizedBox(
                        width: 58,
                        child: _buildPanel(
                          child: Column(
                            children: [
                              // 1. Menu USB
                              _buildMenuItem(
                                id: 'USB',
                                label: 'USB',
                                icon: Icons.usb,
                              ),
                              const SizedBox(height: 8),

                              // 2. Menu PSU (Icon Petir)
                              _buildMenuItem(
                                id: 'PSU',
                                label: 'PSU',
                                icon: Icons.flash_on,
                              ),
                              const SizedBox(height: 8),

                              // 3. Menu PROBE (Icon Probe / Jarum Tester AVO)
                              _buildMenuItem(
                                id: 'PROBE',
                                label: 'PROBE',
                                icon: Icons.tune,
                              ),

                              const Spacer(),

                              // 4. Menu SET (Paling Bawah)
                              _buildMenuItem(
                                id: 'SETTINGS',
                                label: 'SET',
                                icon: Icons.settings,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],

                    // ------------------------------------------
                    // JIKA MENU SETTINGS: TAMPILAN PENGATURAN PENUH
                    // ------------------------------------------
                    if (_activeMenu == 'SETTINGS')
                      Expanded(
                        child: _buildSettingsPanel(),
                      )
                    // ------------------------------------------
                    // JIKA MENU PROBE: SWIPEABLE PAGEVIEW (BISA DIGESER)
                    // ------------------------------------------
                    else if (_activeMenu == 'PROBE')
                      Expanded(
                        child: PageView(
                          controller: _probePageController,
                          onPageChanged: (idx) {
                            setState(() => _probeActivePageIndex = idx);
                          },
                          children: [
                            _buildProbeFullscreenView(),
                            _buildProbeGraphView(),
                          ],
                        ),
                      )
                    // ------------------------------------------
                    // JIKA MENU USB: SWIPEABLE PAGEVIEW PENUH (SEPERTI PROBE)
                    // ------------------------------------------
                    else if (_activeMenu == 'USB')
                      Expanded(
                        child: PageView(
                          controller: _usbPageController,
                          children: [
                            // Halaman 1: Mode Normal (Detail CH Terpilih + Grafik USB)
                            Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: _buildUsbDetailView(),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  flex: 6,
                                  child: _buildMainOscilloscopePanel(),
                                ),
                              ],
                            ),
                            // Halaman 2: Layar Penuh 4 Channel (Tanpa Grafik Samping)
                            _buildUsbAllChannelsOverview(),
                          ],
                        ),
                      )
                    else ...[
                      // ------------------------------------------
                      // JIKA MENU PSU: TAMPILAN NORMAL (TENGAH + KANAN GRAFIK)
                      // ------------------------------------------
                      Expanded(
                        flex: 4,
                        child: _buildPsuMiddlePanel(),
                      ),
                      const SizedBox(width: 4),

                      // Panel Kanan Grafik
                      Expanded(
                        flex: 6,
                        child: _buildMainOscilloscopePanel(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // Area Deteksi Khusus Swipe dari Tepi Kiri (Saat sidebar tertutup: geser ke kanan untuk memunculkan tombol buka)
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
                // Terdeteksi swipe dari tepi kiri ke arah kanan
                _resetArrowAutoHideTimer();
              }
            },
          ),
        )
      else
        // Area Deteksi Khusus Swipe di Area Panel Menu Kiri (Saat sidebar terbuka: geser jari untuk memunculkan tombol tutup)
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 75,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragUpdate: (details) {
              if (details.primaryDelta != null && details.primaryDelta!.abs() > 3) {
                // Terdeteksi swipe di area panel menu
                _resetArrowAutoHideTimer();
              }
            },
          ),
        ),

      // Tombol Buka / Tutup Panel Menu Kiri (Menyatu di Sisi Tengah Layar)
      // Otomatis tersembunyi baik saat menu terbuka maupun tertutup, dan hanya muncul saat di-swipe
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
                      pointLeft: _sidebarExpanded, // Jika terbuka tunjuk ke kiri (tutup), jika tertutup tunjuk ke kanan (buka)
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),

      // Overlay Black saat layar redup (menyerap sentuhan pertama untuk langsung bangun)
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

  // ==========================================
  // PANEL TENGAH KHUSUS MODE PSU (Power Supply)
  // Bisa digeser (Swipe PageView):
  // 0: Standar (Volt, Ampere/mA, Daya Watt)
  // 1: Volt & Ampere Saja (Ukuran Lebih Besar & Fokus)
  // 2: Analog Ampere Meter Jarum (Gaya Meter Klasik Presisi)
  // ==========================================
  Widget _buildPsuMiddlePanel() {
    return Column(
      children: [
        // Indikator Sub-Halaman Geser Panel PSU
        Container(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
          margin: const EdgeInsets.only(bottom: 3),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.white12, width: 0.6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.swipe, color: _activeThemeColor, size: 10),
                  const SizedBox(width: 4),
                  Text(
                    _psuActivePageIndex == 0
                        ? 'PSU: DETAIL LENGKAP'
                        : (_psuActivePageIndex == 1 ? 'PSU: VOLT & AMPERE' : 'PSU: ANALOG AMPERE METER'),
                    style: TextStyle(
                      color: _activeThemeColor,
                      fontSize: 7.5,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (idx) {
                  final isActive = _psuActivePageIndex == idx;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: isActive ? 12 : 5,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive ? _activeThemeColor : Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),

        // Area Display Utama (Bisa Di-swipe)
        Expanded(
          flex: 5,
          child: PageView(
            controller: _psuPageController,
            onPageChanged: (idx) {
              setState(() => _psuActivePageIndex = idx);
            },
            children: [
              // Halaman 0: Tampilan Standar 3 Baris (Volt, Ampere, Watt)
              _buildPsuDefaultView(),
              // Halaman 1: Tampilan Khusus Volt & Ampere Saja (Besar & Jelas)
              _buildPsuVoltAmpOnlyView(),
              // Halaman 2: Tampilan Analog Ampere Meter Jarum
              _buildPsuAnalogAmpView(),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // 2B: Panel SET OCP + SLIDER MAX 10A
        _buildPanel(
          height: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 24,
                child: Row(
                  children: [
                    const Text(
                      'SET OCP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_ocpLimit.toStringAsFixed(1)}A / 10A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _ocpEnabled ? 'ON' : 'OFF',
                      style: TextStyle(
                        color: _ocpEnabled ? Colors.white : Colors.white38,
                        fontSize: 8.5,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Transform.scale(
                      scale: 0.6,
                      child: Switch(
                        value: _ocpEnabled,
                        activeColor: Colors.white,
                        inactiveThumbColor: Colors.white38,
                        inactiveTrackColor: Colors.transparent,
                        onChanged: (val) {
                          HapticFeedback.mediumImpact();
                          setState(() => _ocpEnabled = val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 24,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape: SliderComponentShape.noOverlay,
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: _ocpLimit,
                    min: 0.0,
                    max: 10.0,
                    divisions: 100,
                    onChanged: (val) {
                      setState(() => _ocpLimit = val);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // 2C: Tombol Analisis AI
        _buildPanel(
          height: 40,
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
                      'PANEL 2C: [ START AI ANALYSIS ]',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
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

  // Tampilan Halaman 0: Tampilan Standar 3 Baris (Volt, Ampere, Watt)
  Widget _buildPsuDefaultView() {
    final watt = _psuLiveVolt * _psuLiveAmp;
    final mA = _psuLiveAmp * 1000.0;
    return Column(
      children: [
        Expanded(
          child: _buildPanel(
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
                Text(
                  '${_psuLiveVolt.toStringAsFixed(3)} V',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: _buildPanel(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'ARUS BEBAN (mA / A)',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 8.5,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${mA.toStringAsFixed(1)} mA  /  ${_psuLiveAmp.toStringAsFixed(3)} A',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _activeThemeColor,
                    fontSize: 13,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: _buildPanel(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'KONSUMSI DAYA (WATT)',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 8.5,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${watt.toStringAsFixed(3)} W',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
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
    final mA = _psuLiveAmp * 1000.0;
    return Column(
      children: [
        // Blok Voltase Jumbo
        Expanded(
          child: _buildPanel(
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
                        _psuLiveVolt.toStringAsFixed(3),
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

        // Blok Ampere Jumbo
        Expanded(
          child: _buildPanel(
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
                      '${mA.toStringAsFixed(0)} mA',
                      style: TextStyle(
                        color: _activeThemeColor,
                        fontSize: 8.5,
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
                        _psuLiveAmp.toStringAsFixed(3),
                        style: TextStyle(
                          color: _activeThemeColor,
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
                          color: _activeThemeColor,
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

  // Tampilan Halaman 2: Analog Ampere Meter Jarum (Gaya Analog Presisi)
  Widget _buildPsuAnalogAmpView() {
    return _buildPanel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              // Header Analog Meter
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.speed, color: Colors.white70, size: 12),
                      const SizedBox(width: 4),
                      const Text(
                        'ANALOG AMMETER',
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
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.18),
                      border: Border.all(color: Colors.redAccent, width: 0.6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      'LIMIT: ${_ocpLimit.toStringAsFixed(1)}A',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 7,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              // Gauge Canvas Jarum Analog
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _AnalogMeterGaugePainter(
                      currentAmp: _psuLiveAmp,
                      maxAmp: 5.0,
                      ocpLimit: _ocpLimit,
                      accentColor: _activeThemeColor,
                    ),
                  ),
                ),
              ),

              // Baris Info Nilai Digital di Bawah Jarum
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: Colors.white12, width: 0.8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'V: ${_psuLiveVolt.toStringAsFixed(2)} V',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 8,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(_psuLiveAmp * 1000).toStringAsFixed(0)} mA',
                      style: TextStyle(
                        color: _activeThemeColor,
                        fontSize: 8,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_psuLiveAmp.toStringAsFixed(3)} A',
                      style: TextStyle(
                        color: _activeThemeColor,
                        fontSize: 9,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  // ==========================================
  // PANEL KHUSUS MODE USB (DETAIL CH & FULLSCREEN 4-CH OVERVIEW)
  // ==========================================

  // Halaman 1 USB: Detail Channel Terpilih (Lengkap dengan Volt, Arus, Daya, mAh, D+, D-, AI)
  Widget _buildUsbDetailView() {
    final cur = _usbChannelsData.firstWhere(
      (item) => item['ch'] == _selectedUsbChannel,
      orElse: () => _usbChannelsData[0],
    );

    return Column(
      children: [
        // Label Info Channel Aktif
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            border: Border.all(color: _activeThemeColor.withOpacity(0.4), width: 0.8),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            '${cur['name']} [${cur['protocol']}]',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _activeThemeColor,
              fontSize: 8.5,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Bagian Atas: Pengukuran Utama USB (Volt, Arus, Daya, Kapasitas)
        Expanded(
          flex: 6,
          child: Row(
            children: [
              // Kolom Kiri: VOLT, ARUS
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: _buildPanel(
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
                      child: _buildPanel(
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

              // Kolom Kanan: DAYA, KAPASITAS
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: _buildPanel(
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
                      child: _buildPanel(
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

        // Panel D+ & D- Berdampingan Kiri-Kanan di Bawah
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Expanded(
                child: _buildPanel(
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
                child: _buildPanel(
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
        const SizedBox(height: 4),

        // Tombol Analisis AI Charging
        _buildPanel(
          height: 38,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: const Duration(milliseconds: 1000),
                    content: Text('Trigger AI Charging: Mendiagnosa CH ${_selectedUsbChannel} [${cur['protocol']}]...'),
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
                      '[ START AI DIAGNOSIS CH $_selectedUsbChannel ]',
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

  // Halaman 2 USB: Overview 4 Channel Charging Control (Layar Penuh, Navigasi Murni Geser / Swipe)
  Widget _buildUsbAllChannelsOverview() {
    return Column(
      children: [
        // Grid 4 Channel (2x2 Grid Penuh)
        Expanded(
          child: Column(
            children: [
              // Baris 1: CH1 & CH2
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _buildUsbChannelCard(_usbChannelsData[0])),
                    const SizedBox(width: 4),
                    Expanded(child: _buildUsbChannelCard(_usbChannelsData[1])),
                  ],
                ),
              ),
              const SizedBox(height: 4),

              // Baris 2: CH3 & CH4
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _buildUsbChannelCard(_usbChannelsData[2])),
                    const SizedBox(width: 4),
                    Expanded(child: _buildUsbChannelCard(_usbChannelsData[3])),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Kartu Kompak Tiap Channel di Panel Overview (Semua 4 CH Aktif & Seragam)
  Widget _buildUsbChannelCard(Map<String, dynamic> data) {
    final bool isSelected = _selectedUsbChannel == data['ch'];

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedUsbChannel = data['ch'] as int;
        });
        _usbPageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(
            color: _activeThemeColor,
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Baris 1: Header Channel, Nama Port, & Status LED Aktif
            Row(
              children: [
                // Nomor Channel Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: _activeThemeColor, width: 0.8),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    'CH ${data['ch']}',
                    style: TextStyle(
                      color: _activeThemeColor,
                      fontSize: 8.5,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Nama Port
                Expanded(
                  child: Text(
                    data['name'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Status ACTIVE Hijau (Semua 4 CH Aktif)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(
                      color: Colors.greenAccent,
                      width: 0.8,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 6.8,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),

            // Baris 2: Nilai Utama (Voltase, Arus, Daya) dalam Panel Grid
            Expanded(
              child: Row(
                children: [
                  // Box Voltase
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        border: Border.all(color: Colors.white24, width: 0.8),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'VOLTASE',
                            style: TextStyle(color: Colors.white54, fontSize: 6.5, fontFamily: 'monospace'),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            data['volt'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Box Arus
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        border: Border.all(color: Colors.white24, width: 0.8),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'ARUS CAS',
                            style: TextStyle(color: Colors.white54, fontSize: 6.5, fontFamily: 'monospace'),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            data['amp'] as String,
                            style: const TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 10,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Box Daya
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        border: Border.all(color: Colors.white24, width: 0.8),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'DAYA WATT',
                            style: TextStyle(color: Colors.white54, fontSize: 6.5, fontFamily: 'monospace'),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            data['watt'] as String,
                            style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 10,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
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

            // Baris 3: Telemetri Sinyal Data (D+, D-, Kapasitas mAh, Protokol Handshake)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.white12, width: 0.8),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Row(
                children: [
                  Text(
                    'D+: ${data['dp']}',
                    style: const TextStyle(color: Colors.white70, fontSize: 7.2, fontFamily: 'monospace'),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'D-: ${data['dm']}',
                    style: const TextStyle(color: Colors.white70, fontSize: 7.2, fontFamily: 'monospace'),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${data['mah']}',
                    style: const TextStyle(color: Colors.white60, fontSize: 7.2, fontFamily: 'monospace'),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      '${data['protocol']}',
                      style: TextStyle(
                        color: _activeThemeColor,
                        fontSize: 6.8,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // PANEL GRAFIK OSCILLOSCOPE UTAMA (Untuk PSU & USB)
  // ==========================================
  Widget _buildMainOscilloscopePanel() {
    return Column(
      children: [
        // Toolbar Pilihan Waveform
        _buildPanel(
          height: 32,
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
              const Text(
                '[200 Hz LIVE]',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 8,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // Canvas Area
        Expanded(
          child: _buildPanel(
            child: Text(
              'PANEL 3: GRAFIK OSCILLOSCOPE (MODE: $_graphMode)\n\n'
              '$_graphModeDescription',
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
      ],
    );
  }

  // ==========================================
  // MENU PROBE - HALAMAN 1: MULTIMETER LEBAR PENUH & TABEL BESAR (BISA DIGESER)
  // ==========================================
  Widget _buildProbeFullscreenView() {
    return Row(
      children: [
        // SISI KIRI: DISPLAY ANGKA JUMBO + SELECTOR MODE BESAR DI TENGAH
        Expanded(
          flex: 4,
          child: Column(
            children: [
              // 1. Display Angka Ukur Jumbo Real-time (Dengan Indikator Merah 0.000 Saat Short)
              Expanded(
                flex: 5,
                child: GestureDetector(
                  onTap: () {
                    // Klik panel angka untuk simulasi short circuit / normal
                    setState(() => _isProbeShort = !_isProbeShort);
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _isProbeShort ? Colors.red.withOpacity(0.18) : Colors.transparent,
                      border: Border.all(
                        color: _isProbeShort ? Colors.redAccent : Colors.white70,
                        width: _isProbeShort ? 2.0 : 1.2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isProbeShort ? '⚠️ PERINGATAN: JALUR SHORT TO GROUND (GND)!' : _probeStatusSubtitle,
                          style: TextStyle(
                            color: _isProbeShort ? Colors.redAccent : Colors.white60,
                            fontSize: 8.5,
                            fontFamily: 'monospace',
                            fontWeight: _isProbeShort ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isProbeShort
                              ? (_probeMode == 'DIODA' ? '000' : '0.000 V')
                              : _probeCurrentDisplayValue,
                          style: TextStyle(
                            color: _isProbeShort ? Colors.redAccent : Colors.white,
                            fontSize: 40,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isProbeShort ? '[ SHORT CIRCUIT DETECTED • BUZZER ACTIVE ]' : '[ AUTO-RANGE PROBE ACTIVE ]',
                          style: TextStyle(
                            color: _isProbeShort ? Colors.redAccent : Colors.white38,
                            fontSize: 8,
                            fontFamily: 'monospace',
                            fontWeight: _isProbeShort ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // 3. SELECTOR MODE UKUR DI TENGAH (UKURAN BESAR & LEGA)
              _buildPanel(
                height: 52,
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

              // 4. Action Catat Hasil Ukur
              _buildPanel(
                height: 38,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _probeHistory.insert(0, {
                        'time': 'LIVE',
                        'mode': _probeMode == 'RESISTOR' ? 'RES' : _probeMode,
                        'value': _probeCurrentDisplayValue,
                        'note': 'MANUAL CAPTURE',
                      });
                    });
                  },
                  child: Container(
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_circle_outline, color: Colors.white, size: 14),
                        SizedBox(width: 6),
                        Text(
                          '[ + CATAT KE RIWAYAT UKUR ]',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
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

        // SISI KANAN: TABEL RIWAYAT BESAR (DENGAN INDIKATOR SWIPE KE GRAFIK)
        Expanded(
          flex: 6,
          child: Column(
            children: [
              // Header Riwayat + Hint Swipe
              _buildPanel(
                height: 32,
                child: Row(
                  children: [
                    const Icon(Icons.history, color: Colors.white70, size: 14),
                    const SizedBox(width: 6),
                    const Text(
                      'TABEL RIWAYAT PENGUKURAN JALUR SERVIS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        _probePageController.animateToPage(
                          1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
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
                                fontSize: 8,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 8, color: Colors.white70),
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
                child: _buildPanel(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _probeHistory.length,
                    separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 6),
                    itemBuilder: (context, index) {
                      final item = _probeHistory[index];
                      return Row(
                        children: [
                          Text(
                            '#${index + 1} ',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 9,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white38, width: 0.8),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              item['mode']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8.5,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item['value']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'JALUR: ${item['note']!}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const Spacer(),
                          Text(
                            item['time']!,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 8,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // Clear Button
              _buildPanel(
                height: 36,
                child: GestureDetector(
                  onTap: () {
                    setState(() => _probeHistory.clear());
                  },
                  child: Container(
                    alignment: Alignment.center,
                    child: const Text(
                      '[ BERSIHKAN SEMUA DATA RIWAYAT ]',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 8.5,
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

  // ==========================================
  // MENU PROBE - HALAMAN 2: GRAFIK SIGNAL LOGIC PROBE (DIGESER DARI KANAN)
  // ==========================================
  Widget _buildProbeGraphView() {
    return Column(
      children: [
        _buildPanel(
          height: 32,
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  _probePageController.animateToPage(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
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
                        'GESER KEMBALI KE MULTIMETER',
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

        Expanded(
          child: _buildPanel(
            child: const Text(
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
      ],
    );
  }

  Widget _buildProbeModeButton(String modeKey, String label) {
    final bool isSelected = _probeMode == modeKey;
    return GestureDetector(
      onTap: () {
        setState(() => _probeMode = modeKey);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white24 : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white38,
            width: isSelected ? 1.2 : 0.8,
          ),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 8.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }

  Widget _buildLargeProbeModeButton(String modeKey, String label, IconData icon) {
    final bool isSelected = _probeMode == modeKey;
    return GestureDetector(
      onTap: () {
        setState(() => _probeMode = modeKey);
      },
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white24 : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white24,
            width: isSelected ? 1.5 : 0.8,
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
                color: isSelected ? Colors.white : Colors.white70,
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

  String get _probeCurrentDisplayValue {
    switch (_probeMode) {
      case 'DIODA':
        return '0.428';
      case 'RESISTOR':
        return '4.70 kΩ';
      case 'VOLT':
      default:
        return '3.824 V';
    }
  }

  String get _probeStatusSubtitle {
    switch (_probeMode) {
      case 'DIODA':
        return 'NILAI JATUH TEGANGAN (DIODE DROP)';
      case 'RESISTOR':
        return 'RESISTANSI JALUR / HAMBATAN DALAM';
      case 'VOLT':
      default:
        return 'TEGANGAN TITIK UJI (TEST POINT VDC)';
    }
  }

  Widget _buildGraphFilterButton(String label) {
    final bool isSelected = _graphMode == label;
    return GestureDetector(
      onTap: () {
        setState(() => _graphMode = label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white24 : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white38,
            width: isSelected ? 1.2 : 0.8,
          ),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 8.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }

  String get _graphModeDescription {
    switch (_graphMode) {
      case 'ARUS':
        return '[ FOKUS ANALISIS ARUS: Pulsa Booting HP | Short Spikes | Leakage mA/uA ]';
      case 'VOLTASE':
        return '[ FOKUS ANALISIS VOLTASE: Drop Tegangan Jalur VBUS / BATT Under Load ]';
      case 'DAYA':
        return '[ FOKUS KONSUMSI DAYA: Akumulasi Beban Power PMIC ]';
      case 'SEMUA':
      default:
        return '[ MULTI-WAVEFORM: Tampilan Sinkron Kurva Voltase + Arus + Daya ]';
    }
  }

  Widget _buildMenuItem({
    required String id,
    required String label,
    required IconData icon,
  }) {
    final bool isSelected = _activeMenu == id;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _activeMenu = id);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white24 : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white24,
            width: isSelected ? 1.2 : 0.8,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white60,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'monospace',
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // PANEL UTAMA MENU SETTINGS (PENGATURAN SISTEM - VERTICAL SCROLL TANPA GARIS SCROLL)
  // ==========================================
  Widget _buildSettingsPanel() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
            // ----------------------------------------
            // BARIS 1: KONEKSI HARDWARE UDP & SERVER AI DIAGNOSIS
            // ----------------------------------------
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. KONEKSI UDP / HARDWARE
                Expanded(
                  child: _buildSettingCard(
                    title: 'KONEKSI HARDWARE ESP12 (UDP)',
                    icon: Icons.wifi,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('IP TARGET : $_esp12Ip', style: const TextStyle(color: Colors.white70, fontSize: 8.5, fontFamily: 'monospace')),
                        Text('UDP PORT  : $_esp12Port', style: const TextStyle(color: Colors.white70, fontSize: 8.5, fontFamily: 'monospace')),
                        Text('PROTOCOL  : BINARY STREAM (INA3221)', style: const TextStyle(color: Colors.white70, fontSize: 8.5, fontFamily: 'monospace')),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(duration: Duration(milliseconds: 1000), content: Text('Ping ke ESP12: Response 2ms (Connected)')),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(border: Border.all(color: Colors.white38), borderRadius: BorderRadius.circular(3)),
                            child: const Text('[ TES KONEKSI KE ESP12 ]', style: TextStyle(color: Colors.white, fontSize: 8.5, fontFamily: 'monospace')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // 2. SERVER ENDPOINT AI DIAGNOSIS
                Expanded(
                  child: _buildSettingCard(
                    title: 'API SERVER AI DIAGNOSIS',
                    icon: Icons.psychology,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ENDPOINT : $_aiServerUrl', style: const TextStyle(color: Colors.white70, fontSize: 8, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis),
                        const Text('AI MODEL : GEMINI-FLASH HARDWARE DIAGNOSTICS', style: TextStyle(color: Colors.white70, fontSize: 8, fontFamily: 'monospace')),
                        const Text('STATUS   : ACTIVE (READY FOR INFERENCE)', style: TextStyle(color: Colors.white70, fontSize: 8, fontFamily: 'monospace')),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(duration: Duration(milliseconds: 1000), content: Text('API Server Handshake: OK (Status 200)')),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(border: Border.all(color: Colors.white38), borderRadius: BorderRadius.circular(3)),
                            child: const Text('[ TES KONEKSI SERVER AI ]', style: TextStyle(color: Colors.white, fontSize: 8.5, fontFamily: 'monospace')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // ----------------------------------------
            // BARIS 2: TEMA / TAMPILAN & OTA FIRMWARE HARDWARE
            // ----------------------------------------
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 3. PERSONALISASI TEMA & FONT TAMPILAN
                Expanded(
                  child: _buildSettingCard(
                    title: 'GANTI TEMA & WARNA TAMPILAN',
                    icon: Icons.palette,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PILIHAN TEMA WARNA:', style: TextStyle(color: Colors.white70, fontSize: 8, fontFamily: 'monospace')),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildThemeOptionButton('WIREFRAME', 'PUTIH LAB', Colors.white),
                            const SizedBox(width: 4),
                            _buildThemeOptionButton('CYBER_BLUE', 'CYBER CYAN', Colors.cyanAccent),
                            const SizedBox(width: 4),
                            _buildThemeOptionButton('MATRIX_GREEN', 'MATRIX HIJAU', Colors.greenAccent),
                            const SizedBox(width: 4),
                            _buildThemeOptionButton('AMBER_WARM', 'AMBER ORANGE', Colors.amberAccent),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('PILIHAN GAYA FONT:', style: TextStyle(color: Colors.white70, fontSize: 8, fontFamily: 'monospace')),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildFontOptionButton('MONOSPACE'),
                            const SizedBox(width: 4),
                            _buildFontOptionButton('DIGITAL 7-SEG'),
                            const SizedBox(width: 4),
                            _buildFontOptionButton('ROBOTO'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // 4. UPLOAD FIRMWARE / UPDATE OTA SISTEM HARDWARE
                Expanded(
                  child: _buildSettingCard(
                    title: 'FIRMWARE UPDATE (OTA ESP12)',
                    icon: Icons.system_update_alt,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('VERSI AKTIF : $_firmwareVersion', style: const TextStyle(color: Colors.white70, fontSize: 8.5, fontFamily: 'monospace')),
                        const Text('TARGET CHIP : ESP8266 / ESP12-E / ESP12-F', style: TextStyle(color: Colors.white70, fontSize: 8.5, fontFamily: 'monospace')),
                        const Text('METODE UP   : WIRELESS OTA (.bin binary upload)', style: TextStyle(color: Colors.white70, fontSize: 8, fontFamily: 'monospace')),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(duration: Duration(milliseconds: 1500), content: Text('OTA Updater: Memilih file firmware .bin dan upload ke ESP12...')),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              border: Border.all(color: Colors.white, width: 1.0),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.cloud_upload, color: Colors.white, size: 12),
                                SizedBox(width: 6),
                                Text('[ UPLOAD FIRMWARE BARU (.BIN) ]', style: TextStyle(color: Colors.white, fontSize: 8.5, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
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
            const SizedBox(height: 4),

            // ----------------------------------------
            // BARIS 2B: MANAJEMEN DAYA LAYAR (KEEP AWAKE & AUTO REDUP TANPA LOCK)
            // ----------------------------------------
            _buildSettingCard(
              title: 'MANAJEMEN LAYAR & STANDBY AUTO-REDUP (ANTI-LOCK)',
              icon: Icons.light_mode_outlined,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('JAGA LAYAR SELALU HIDUP:', style: TextStyle(color: Colors.white70, fontSize: 7.5, fontFamily: 'monospace')),
                  const SizedBox(width: 4),
                  SizedBox(
                    height: 18,
                    child: Transform.scale(
                      scale: 0.6,
                      child: Switch(
                        value: _keepScreenAwake,
                        activeColor: Colors.cyanAccent,
                        onChanged: (val) {
                          setState(() => _keepScreenAwake = val);
                          _applyKeepAwake(val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Layar HP tidak akan pernah terkunci (lock screen) selama aplikasi terbuka.\n'
                    'Layar hanya akan meredup (hemat baterai/burn-in) dan langsung hidup kembali saat disentuh:',
                    style: TextStyle(color: Colors.white60, fontSize: 7.5, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text('WAKTU AUTO-REDUP: ', style: TextStyle(color: Colors.white70, fontSize: 8, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      _buildDimTimeoutButton(30, '30 DETIK'),
                      const SizedBox(width: 4),
                      _buildDimTimeoutButton(60, '1 MENIT'),
                      const SizedBox(width: 4),
                      _buildDimTimeoutButton(120, '2 MENIT'),
                      const SizedBox(width: 4),
                      _buildDimTimeoutButton(300, '5 MENIT'),
                      const SizedBox(width: 4),
                      _buildDimTimeoutButton(0, 'JANGAN REDUP'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // ----------------------------------------
            // BARIS 3: DEVELOPER & DIAGNOSTICS MODE (HANYA MUNCUL JIKA PASSWORD BENAR)
            // ----------------------------------------
            if (_devUnlocked) ...[
              _buildSettingCard(
                title: 'DEVELOPER & DIAGNOSTIK DEBUG MODE',
                icon: Icons.terminal,
                titleColor: Colors.amberAccent,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() => _devUnlocked = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(duration: Duration(milliseconds: 1000), content: Text('Developer Mode Dikunci Kembali.')),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(border: Border.all(color: Colors.redAccent, width: 0.8), borderRadius: BorderRadius.circular(3)),
                        child: const Text('[ KUNCI / KELUAR DEV ]', style: TextStyle(color: Colors.redAccent, fontSize: 7, fontFamily: 'monospace')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 20,
                      child: Transform.scale(
                        scale: 0.65,
                        child: Switch(
                          value: _devModeEnabled,
                          activeColor: Colors.amberAccent,
                          onChanged: (val) {
                            setState(() => _devModeEnabled = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Toggle 1: Hardware Simulator
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('SIMULATOR HARDWARE (NO ESP12)', style: TextStyle(color: Colors.white70, fontSize: 7.5, fontFamily: 'monospace')),
                              SizedBox(
                                height: 18,
                                child: Transform.scale(
                                  scale: 0.6,
                                  child: Switch(
                                    value: _simulateHardware,
                                    activeColor: Colors.cyanAccent,
                                    onChanged: (val) => setState(() => _simulateHardware = val),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Toggle 2: Raw UDP Stream
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('STREAM RAW UDP PACKET (HEX)', style: TextStyle(color: Colors.white70, fontSize: 7.5, fontFamily: 'monospace')),
                              SizedBox(
                                height: 18,
                                child: Transform.scale(
                                  scale: 0.6,
                                  child: Switch(
                                    value: _showRawPackets,
                                    activeColor: Colors.greenAccent,
                                    onChanged: (val) => setState(() => _showRawPackets = val),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Log Console & Actions
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Console Box
                        Expanded(
                          flex: 7,
                          child: Container(
                            height: 65,
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              border: Border.all(color: Colors.white24, width: 0.8),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: SingleChildScrollView(
                              child: Text(
                                _showRawPackets
                                    ? '[UDP:4210] RECV 16B: 0x53 0x50 0x01 0x04 0x2A 0x0F 0x00 0x3E\n'
                                      '[INA3221] CH1: 3.824V | CH2: 0.412A | CH3: 5.080V\n'
                                      '[FPS] Render Loop: 60.1 FPS | Buffer: 1200 Samples\n'
                                      '[IRQ] OCP Comparator: NORMAL (Threshold: 2.0A)\n'
                                      '[SIM] Injected Bootloop Waveform active...'
                                    : '[DEV] Debug logger siap.\n'
                                      '[DEV] ESP12 I2C Clock: 400kHz Fast Mode\n'
                                      '[DEV] Shunt Resistor: R100 (0.100 Ohm)\n'
                                      '[DEV] Buffer Ring: 4096 bytes allocated.',
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 7.5,
                                  fontFamily: 'monospace',
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Quick Action Buttons
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      duration: Duration(milliseconds: 1000),
                                      content: Text('[DEV] Injeksi Test Pulsa Short Spikes (5A) dikirim!'),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 5),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.amberAccent.withOpacity(0.15),
                                    border: Border.all(color: Colors.amberAccent, width: 0.9),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: const Text(
                                    '[ TEST PULSA 5A ]',
                                    style: TextStyle(color: Colors.amberAccent, fontSize: 8, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      duration: Duration(milliseconds: 1000),
                                      content: Text('[DEV] Ring Buffer di-reset ke 0 sample.'),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 5),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white38, width: 0.8),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: const Text(
                                    '[ CLEAR BUFFER ]',
                                    style: TextStyle(color: Colors.white70, fontSize: 8, fontFamily: 'monospace'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),

              // BARIS 4: KALIBRASI SENSOR
              _buildSettingCard(
                title: 'KALIBRASI SENSOR SHUNT RESISTOR & OFFSET',
                icon: Icons.tune,
                child: Row(
                  children: const [
                    Expanded(
                      child: Text(
                        'SHUNT CH1 (PSU): 100 mΩ (R100) ±0.5%\n'
                        'OFFSET TEGANGAN: +0.002 V',
                        style: TextStyle(color: Colors.white70, fontSize: 7.5, fontFamily: 'monospace', height: 1.3),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'SHUNT CH2 (USB): 50 mΩ (R050) ±0.5%\n'
                        'OFFSET ARUS    : -0.001 A',
                        style: TextStyle(color: Colors.white70, fontSize: 7.5, fontFamily: 'monospace', height: 1.3),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'MAX SAMPLE RATE: 1000 Hz\n'
                        'CONVERSION TIME: 588 µs / CH',
                        style: TextStyle(color: Colors.white70, fontSize: 7.5, fontFamily: 'monospace', height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
            ] else ...[
              // ----------------------------------------
              // TOMBOL KECIL PALING BAWAH: MASUK DEVELOPER MODE
              // ----------------------------------------
              GestureDetector(
                onTap: _showDeveloperPasswordDialog,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    border: Border.all(color: Colors.white24, width: 0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.lock_outline, color: Colors.white54, size: 12),
                      SizedBox(width: 6),
                      Text(
                        '[ KLIK UNTUK MASUK KE DEVELOPER MODE (PASSWORD PROTECTED) ]',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 8,
                          fontFamily: 'monospace',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      );
  }

  // Dialog Input Password Developer Mode
  void _showDeveloperPasswordDialog() {
    final TextEditingController pwdController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF141414),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: _activeThemeColor, width: 1.2),
            borderRadius: BorderRadius.circular(6),
          ),
          title: Row(
            children: const [
              Icon(Icons.shield_outlined, color: Colors.amberAccent, size: 16),
              SizedBox(width: 8),
              Text(
                'AKSES DEVELOPER MODE',
                style: TextStyle(color: Colors.amberAccent, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Masukkan password otentikasi teknisi untuk membuka panel developer & konfigurasi biner UDP:',
                style: TextStyle(color: Colors.white70, fontSize: 8.5, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: pwdController,
                obscureText: true,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: 'Password (default: 8888)',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 9, fontFamily: 'monospace'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white30), borderRadius: BorderRadius.circular(4)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _activeThemeColor), borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('BATAL', style: TextStyle(color: Colors.white54, fontSize: 9, fontFamily: 'monospace')),
            ),
            TextButton(
              onPressed: () {
                final input = pwdController.text.trim();
                // Password default: '8888' atau 'admin'
                if (input == '8888' || input == 'admin') {
                  Navigator.of(ctx).pop();
                  setState(() => _devUnlocked = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      duration: Duration(milliseconds: 1500),
                      backgroundColor: Colors.green,
                      content: Text('Akses Diberikan: Panel Developer Mode Terbuka!'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      duration: Duration(milliseconds: 1500),
                      backgroundColor: Colors.redAccent,
                      content: Text('Password Salah! Akses ditolak.'),
                    ),
                  );
                }
              },
              child: const Text('[ BUKA PANEL ]', style: TextStyle(color: Colors.amberAccent, fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDimTimeoutButton(int seconds, String label) {
    final bool isSelected = _dimTimeoutSeconds == seconds;
    return GestureDetector(
      onTap: () {
        setState(() {
          _dimTimeoutSeconds = seconds;
          _lastUserActivity = DateTime.now();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white24 : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white24,
            width: isSelected ? 1.2 : 0.8,
          ),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 7.2,
            fontFamily: 'monospace',
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required IconData icon,
    Color? titleColor,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(
          color: _activeThemeColor,
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: titleColor ?? Colors.white, size: 13),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: titleColor ?? Colors.white,
                  fontSize: 8.8,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (trailing != null) ...[
                const Spacer(),
                trailing,
              ],
            ],
          ),
          const Divider(color: Colors.white24, height: 8),
          const SizedBox(height: 2),
          child,
        ],
      ),
    );
  }

  Widget _buildFontOptionButton(String fontLabel) {
    final bool isSelected = _selectedFont == fontLabel;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedFont = fontLabel);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white24 : Colors.transparent,
            border: Border.all(color: isSelected ? Colors.white : Colors.white24, width: isSelected ? 1.2 : 0.8),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            fontLabel,
            textAlign: TextAlign.center,
            style: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontSize: 7, fontFamily: 'monospace', fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOptionButton(String key, String label, Color accentColor) {
    final bool isSelected = _themeName == key;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _themeName = key);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? accentColor.withOpacity(0.2) : Colors.transparent,
            border: Border.all(
              color: isSelected ? accentColor : Colors.white24,
              width: isSelected ? 1.5 : 0.8,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? accentColor : Colors.white60,
              fontSize: 6.8,
              fontFamily: 'monospace',
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Color get _activeThemeColor {
    switch (_themeName) {
      case 'CYBER_BLUE':
        return Colors.cyanAccent;
      case 'MATRIX_GREEN':
        return Colors.greenAccent;
      case 'AMBER_WARM':
        return Colors.amberAccent;
      case 'WIREFRAME':
      default:
        return Colors.white70;
    }
  }

  Widget _buildPanel({double? height, required Widget child}) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(
          color: _activeThemeColor,
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: child,
    );
  }
}

/// Custom Painter Segitiga Presisi (Solid Vector Triangle)
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
      // Menunjuk ke kiri: Pucuk di kiri tengah (0, h/2), dasar di kanan atas (w, 0) dan kanan bawah (w, h)
      path.moveTo(0, size.height / 2);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else {
      // Menunjuk ke kanan: Pucuk di kanan tengah (w, h/2), dasar di kiri atas (0, 0) dan kiri bawah (0, h)
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

/// Widget Teks Berjalan Animasi Halus Tanpa Jeda (Infinite Seamless Loop)
class _RunningTextMarquee extends StatefulWidget {
  final String text;
  final Color color;

  const _RunningTextMarquee({
    required this.text,
    required this.color,
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
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant _RunningTextMarquee oldWidget) {
    super.didUpdateWidget(oldWidget);
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
      // Periode pergeseran tepat = lebar teks + jarak antar teks (gap)
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
      color: widget.color,
      fontSize: 9.2,
      fontFamily: 'monospace',
      fontWeight: FontWeight.bold,
      letterSpacing: 0.8,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Bergeser tepat 1 periode (_periodWidth), saat _controller.value = 1.0 posisi teks kedua tepat di posisi teks pertama
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

/// Custom Painter Pengukur Arus Jarum Analog (Analog Ammeter Gauge)
/// Didesain dengan akurasi visual tinggi, skala busur, tick marks utama & minor,
/// zona aman/bahaya OCP, serta jarum presisi dengan drop shadow.
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

    // Titik poros jarum di bawah tengah layar busur
    final center = Offset(size.width / 2, size.height * 0.95);
    final radius = math.min(size.width * 0.48, size.height * 0.88);

    // Rentang sudut busur jarum: 140 derajat (mulai dari 200° sampai 340°)
    const startAngleDeg = 205.0;
    const sweepAngleDeg = 130.0;
    const startRad = startAngleDeg * (math.pi / 180.0);
    const totalRad = sweepAngleDeg * (math.pi / 180.0);

    // 1. Gambar Background Busur Dial (Gradasi gelap)
    final dialRect = Rect.fromCircle(center: center, radius: radius);
    final dialBgPaint = Paint()
      ..color = const Color(0xFF0D1117)
      ..style = PaintingStyle.fill;
    final dialArcPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(dialRect, startRad, totalRad, false)
      ..close();
    canvas.drawPath(dialArcPath, dialBgPaint);

    // 2. Busur Luar Skala Normal (Abu-abu / Theme Color)
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

    // 3. Busur Zona Bahaya OCP (Merah Transparan pada bagian > ocpLimit)
    final clampedOcp = ocpLimit.clamp(0.0, maxAmp);
    final ocpFraction = clampedOcp / maxAmp;
    final ocpStartRad = startRad + (totalRad * ocpFraction);
    final ocpSweepRad = totalRad * (1.0 - ocpFraction);

    if (ocpSweepRad > 0) {
      final ocpPaint = Paint()
        ..color = Colors.redAccent.withOpacity(0.85)
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

    // 4. Tick Marks (Garis Skala Utama & Minor) & Angka Skala
    const totalDivisions = 25; // Setiap 0.2A untuk 5A max
    for (int i = 0; i <= totalDivisions; i++) {
      final fraction = i / totalDivisions;
      final angle = startRad + (totalRad * fraction);
      final isMajor = (i % 5 == 0); // Setiap 1A

      final tickLength = isMajor ? 9.0 : 4.5;
      final tickColor = (fraction * maxAmp > clampedOcp)
          ? Colors.redAccent
          : (isMajor ? accentColor : Colors.white38);

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
        ..strokeWidth = isMajor ? 1.5 : 0.9;
      canvas.drawLine(p1, p2, tickPaint);

      // Label Angka pada Skala Utama (0, 1, 2, 3, 4, 5)
      if (isMajor) {
        final val = (fraction * maxAmp).toInt();
        final textSpan = TextSpan(
          text: '$val',
          style: TextStyle(
            color: tickColor,
            fontSize: 8.5,
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

    // 5. Teks Satuan [ AMPERE ] di Tengah Busur
    final unitSpan = TextSpan(
      text: 'AMPERE (A)',
      style: TextStyle(
        color: Colors.white38,
        fontSize: 7.5,
        letterSpacing: 1.2,
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

    // 6. Gambar Jarum Bergerak (Needle)
    final clampedCurrent = currentAmp.clamp(0.0, maxAmp);
    final currentFraction = clampedCurrent / maxAmp;
    final needleAngle = startRad + (totalRad * currentFraction);

    final needleLength = radius * 0.88;
    final needleTip = Offset(
      center.dx + needleLength * math.cos(needleAngle),
      center.dy + needleLength * math.sin(needleAngle),
    );

    // Bayangan jarum untuk kesan kedalaman 3D
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx + 2, center.dy + 2),
      Offset(needleTip.dx + 2, needleTip.dy + 2),
      shadowPaint,
    );

    // Garis Utama Jarum (Warna Merah / Oranye Menyala)
    final isOverLimit = clampedCurrent >= clampedOcp;
    final needleColor = isOverLimit ? Colors.redAccent : const Color(0xFFFF5252);

    final needlePaint = Paint()
      ..color = needleColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, needleTip, needlePaint);

    // Ekor jarum pendek ke belakang poros
    final tailTip = Offset(
      center.dx - 10 * math.cos(needleAngle),
      center.dy - 10 * math.sin(needleAngle),
    );
    final tailPaint = Paint()
      ..color = Colors.white54
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, tailTip, tailPaint);

    // 7. Poros Jarum (Center Pivot Cap / Baut Poros)
    final pivotBasePaint = Paint()..color = const Color(0xFF1E2630);
    canvas.drawCircle(center, 7.0, pivotBasePaint);

    final pivotBorderPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, 7.0, pivotBorderPaint);

    final pivotCenterPaint = Paint()..color = needleColor;
    canvas.drawCircle(center, 3.0, pivotCenterPaint);
  }

  @override
  bool shouldRepaint(covariant _AnalogMeterGaugePainter oldDelegate) {
    return oldDelegate.currentAmp != currentAmp ||
        oldDelegate.maxAmp != maxAmp ||
        oldDelegate.ocpLimit != ocpLimit ||
        oldDelegate.accentColor != accentColor;
  }
}
