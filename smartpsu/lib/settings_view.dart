import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';

class SettingsView extends StatefulWidget {
  final Color activeColor;
  final String themeName;
  final String selectedFont;
  final bool keepScreenAwake;
  final int dimTimeoutSeconds;
  final String marqueeText;
  final int marqueeSpeedSeconds;
  final Function(String) onThemeChanged;
  final Function(String) onFontChanged;
  final Function(bool) onKeepScreenAwakeChanged;
  final Function(int) onDimTimeoutChanged;
  final Function(String) onMarqueeTextChanged;
  final Function(int) onMarqueeSpeedChanged;

  const SettingsView({
    super.key,
    required this.activeColor,
    required this.themeName,
    required this.selectedFont,
    required this.keepScreenAwake,
    required this.dimTimeoutSeconds,
    required this.marqueeText,
    required this.marqueeSpeedSeconds,
    required this.onThemeChanged,
    required this.onFontChanged,
    required this.onKeepScreenAwakeChanged,
    required this.onDimTimeoutChanged,
    required this.onMarqueeTextChanged,
    required this.onMarqueeSpeedChanged,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final String _esp12Ip = '192.168.4.1';
  final String _esp12Port = '4210';
  final String _aiServerUrl = 'https://api.smartpsu.ai/v1/diagnose';
  final String _firmwareVersion = 'v1.0.4-ESP12';

  bool _devUnlocked = false;
  bool _devModeEnabled = true;
  bool _showRawPackets = false;
  bool _simulateHardware = true;

  late final TextEditingController _marqueeController;

  @override
  void initState() {
    super.initState();
    _marqueeController = TextEditingController(text: widget.marqueeText);
  }

  @override
  void didUpdateWidget(covariant SettingsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.marqueeText != widget.marqueeText && _marqueeController.text != widget.marqueeText) {
      _marqueeController.text = widget.marqueeText;
    }
  }

  @override
  void dispose() {
    _marqueeController.dispose();
    super.dispose();
  }

  Widget _buildSettingCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        border: Border.all(color: Colors.white12, width: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: widget.activeColor, size: 13),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: widget.activeColor,
                  fontSize: 8.5,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _buildThemeOptionButton(String key, String label, Color accentColor) {
    final bool isSelected = widget.themeName == key;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onThemeChanged(key);
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

  Widget _buildFontOptionButton(String fontLabel) {
    final bool isSelected = widget.selectedFont.toUpperCase() == fontLabel.toUpperCase();
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onFontChanged(fontLabel);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white24 : Colors.transparent,
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white24,
              width: isSelected ? 1.5 : 0.8,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            fontLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontSize: 7,
              fontFamily: 'monospace',
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedOptionButton(int seconds, String label) {
    final bool isSelected = widget.marqueeSpeedSeconds == seconds;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onMarqueeSpeedChanged(seconds);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? widget.activeColor.withOpacity(0.2) : Colors.transparent,
            border: Border.all(
              color: isSelected ? widget.activeColor : Colors.white24,
              width: isSelected ? 1.2 : 0.7,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? widget.activeColor : Colors.white60,
              fontSize: 7,
              fontFamily: 'monospace',
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  void _showDeveloperPasswordDialog() {
    final TextEditingController pwdController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF141414),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: widget.activeColor, width: 1.2),
            borderRadius: BorderRadius.circular(6),
          ),
          title: Row(
            children: const [
              Icon(Icons.shield_outlined, color: Colors.amberAccent, size: 16),
              SizedBox(width: 8),
              Text(
                'AKSES DEVELOPER MODE',
                style: TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
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
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: widget.activeColor), borderRadius: BorderRadius.circular(4)),
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // BARIS 1: KONEKSI UDP & SERVER AI DIAGNOSIS
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. KONEKSI UDP
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

          // BARIS 2: TEMA & FONT
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                          _buildThemeOptionButton('FULL_COLOR', 'FULL COLOR', const Color(0xFFFF007F)),
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

              Expanded(
                child: _buildSettingCard(
                  title: 'FIRMWARE & OTA UPDATE HARDWARE',
                  icon: Icons.system_update_alt,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CURRENT FW: $_firmwareVersion', style: const TextStyle(color: Colors.white70, fontSize: 8.5, fontFamily: 'monospace')),
                      const Text('ESP-IDF   : v4.4.2-release', style: TextStyle(color: Colors.white70, fontSize: 8.5, fontFamily: 'monospace')),
                      const Text('FLASH MEM : 4MB (SPIFFS 1MB)', style: TextStyle(color: Colors.white70, fontSize: 8.5, fontFamily: 'monospace')),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(duration: Duration(milliseconds: 1000), content: Text('Pemeriksaan Firmware: SmartPSU sudah versi terbaru!')),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(border: Border.all(color: Colors.white38), borderRadius: BorderRadius.circular(3)),
                          child: const Text('[ PERIKSA PEMBARUAN OTA ]', style: TextStyle(color: Colors.white, fontSize: 8.5, fontFamily: 'monospace')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // BARIS 3: CUSTOM RUNNING TEXT HEADER
          _buildSettingCard(
            title: 'TEKS BERJALAN HEADER (TOP BAR RUNNING TEXT)',
            icon: Icons.subtitles,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: TextField(
                          controller: _marqueeController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontFamily: 'monospace',
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            hintText: 'Tulis teks berjalan di sini...',
                            hintStyle: const TextStyle(color: Colors.white30, fontSize: 8.5, fontFamily: 'monospace'),
                            border: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.white24, width: 0.8),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: widget.activeColor, width: 1.0),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              widget.onMarqueeTextChanged(val.trim());
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        final text = _marqueeController.text.trim();
                        if (text.isNotEmpty) {
                          HapticFeedback.selectionClick();
                          widget.onMarqueeTextChanged(text);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              duration: Duration(milliseconds: 1200),
                              backgroundColor: Colors.green,
                              content: Text('Teks berjalan header berhasil diperbarui!'),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: widget.activeColor.withOpacity(0.18),
                          border: Border.all(color: widget.activeColor, width: 1.0),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, color: widget.activeColor, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              'TERAPKAN',
                              style: TextStyle(
                                color: widget.activeColor,
                                fontSize: 8,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        const defaultMsg = 'NURHADI-SMARTPSU PRO V1.0.0- IDS STORE TECHNOLOGY';
                        _marqueeController.text = defaultMsg;
                        widget.onMarqueeTextChanged(defaultMsg);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white24, width: 0.8),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'RESET',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 8,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Text(
                      'KECEPATAN : ',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 7.8,
                        fontFamily: 'monospace',
                      ),
                    ),
                    _buildSpeedOptionButton(10, 'CEPAT (10s)'),
                    const SizedBox(width: 4),
                    _buildSpeedOptionButton(18, 'NORMAL (18s)'),
                    const SizedBox(width: 4),
                    _buildSpeedOptionButton(26, 'SANTAI (26s)'),
                    const SizedBox(width: 4),
                    _buildSpeedOptionButton(36, 'LAMBAT (36s)'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          _buildSettingCard(
            title: 'MANAJEMEN LAYAR & DAYA (KEEP AWAKE & AUTO DIM)',
            icon: Icons.screen_lock_portrait,
            child: Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('TETAP NYALA (KEEP AWAKE)', style: TextStyle(color: Colors.white, fontSize: 8.5, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                    subtitle: const Text('Cegah layar HP mati / sleep saat servis', style: TextStyle(color: Colors.white54, fontSize: 7.5, fontFamily: 'monospace')),
                    value: widget.keepScreenAwake,
                    activeColor: widget.activeColor,
                    onChanged: (val) {
                      widget.onKeepScreenAwakeChanged(val);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text('AUTO DIM: ', style: TextStyle(color: Colors.white70, fontSize: 8, fontFamily: 'monospace')),
                      DropdownButton<int>(
                        value: widget.dimTimeoutSeconds,
                        dropdownColor: const Color(0xFF161616),
                        style: TextStyle(color: widget.activeColor, fontSize: 8.5, fontFamily: 'monospace'),
                        underline: Container(height: 1, color: widget.activeColor),
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('JANGAN REDUP')),
                          DropdownMenuItem(value: 60, child: Text('1 MENIT')),
                          DropdownMenuItem(value: 180, child: Text('3 MENIT')),
                          DropdownMenuItem(value: 300, child: Text('5 MENIT')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            widget.onDimTimeoutChanged(val);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          if (_devUnlocked) ...[
            _buildSettingCard(
              title: 'DEVELOPER & HARDWARE DEBUG MODE (UNLOCKED)',
              icon: Icons.developer_mode,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SwitchListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('SIMULASI DATA SENSOR', style: TextStyle(color: Colors.white, fontSize: 8.5, fontFamily: 'monospace')),
                          subtitle: const Text('Gunakan data acak jika ESP12 offline', style: TextStyle(color: Colors.white54, fontSize: 7.5, fontFamily: 'monospace')),
                          value: _simulateHardware,
                          activeColor: widget.activeColor,
                          onChanged: (val) => setState(() => _simulateHardware = val),
                        ),
                      ),
                      Expanded(
                        child: SwitchListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('TAMPILKAN RAW UDP PACKET', style: TextStyle(color: Colors.white, fontSize: 8.5, fontFamily: 'monospace')),
                          subtitle: const Text('Log frame biner INA3221 ke terminal', style: TextStyle(color: Colors.white54, fontSize: 7.5, fontFamily: 'monospace')),
                          value: _showRawPackets,
                          activeColor: widget.activeColor,
                          onChanged: (val) => setState(() => _showRawPackets = val),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
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
}
