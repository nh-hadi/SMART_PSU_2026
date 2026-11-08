import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Model Data Telemetri SmartPSU
class PsuTelemetryData {
  final double v1;
  final double i1;
  final double v2;
  final double i2;
  final double v3;
  final double i3;
  final double dm;
  final double dp;
  final double avo;
  final bool mosfet;
  final bool relay1;
  final bool relay2;
  final String i2cAddrs;
  final DateTime timestamp;

  const PsuTelemetryData({
    this.v1 = 0.0,
    this.i1 = 0.0,
    this.v2 = 0.0,
    this.i2 = 0.0,
    this.v3 = 0.0,
    this.i3 = 0.0,
    this.dm = 0.0,
    this.dp = 0.0,
    this.avo = 0.0,
    this.mosfet = false,
    this.relay1 = false,
    this.relay2 = false,
    this.i2cAddrs = '-',
    required this.timestamp,
  });

  factory PsuTelemetryData.fromJson(Map<String, dynamic> json) {
    double parseD(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    bool parseB(dynamic v) {
      if (v == null) return false;
      if (v is bool) return v;
      if (v is num) return v != 0;
      return v.toString() == '1' || v.toString().toLowerCase() == 'true';
    }

    return PsuTelemetryData(
      v1: parseD(json['v1']),
      i1: parseD(json['i1']),
      v2: parseD(json['v2']),
      i2: parseD(json['i2']),
      v3: parseD(json['v3']),
      i3: parseD(json['i3']),
      dm: parseD(json['dm']),
      dp: parseD(json['dp']),
      avo: parseD(json['avo']),
      mosfet: parseB(json['m']),
      relay1: parseB(json['r1']),
      relay2: parseB(json['r2']),
      i2cAddrs: json['i2c']?.toString() ?? '-',
      timestamp: DateTime.now(),
    );
  }
}

/// Service UDP Telemetri dan Kontrol Hardware
/// Dirancang ultra-hemat daya dan ramah CPU (mencegah HP panas).
class PsuUdpService {
  static final PsuUdpService instance = PsuUdpService._internal();
  PsuUdpService._internal();

  RawDatagramSocket? _socket;
  bool _isRunning = false;

  int _port = 4210;
  String _targetIp = '192.168.4.1'; // IP ESP12 Default AP Mode

  // Notifier hemat render (hanya rebuild listener saat ada data baru ter-throttle)
  final ValueNotifier<PsuTelemetryData> dataNotifier = ValueNotifier<PsuTelemetryData>(
    PsuTelemetryData(timestamp: DateTime.now()),
  );

  // Buffer Riwayat Arus & Voltase Realtime untuk Oscilloscope (Maksimal 120 sampel bergulir)
  // 1. Buffer PSU (CH2 INA3221)
  final List<double> ampHistory = List<double>.filled(120, 0.0, growable: true);
  final List<double> voltHistory = List<double>.filled(120, 0.0, growable: true);
  // 2. Buffer USB Charging (CH3 INA3221)
  final List<double> usbAmpHistory = List<double>.filled(120, 0.0, growable: true);
  final List<double> usbVoltHistory = List<double>.filled(120, 0.0, growable: true);
  final ValueNotifier<int> waveTickNotifier = ValueNotifier<int>(0);

  final ValueNotifier<bool> connectionNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<int> packetCountNotifier = ValueNotifier<int>(0);
  final ValueNotifier<String> ipNotifier = ValueNotifier<String>('192.168.4.1');

  Timer? _watchdogTimer;
  DateTime _lastPacketTime = DateTime.fromMillisecondsSinceEpoch(0);
  int _packetCounter = 0;

  // Throttle interval untuk UI (maks 15 FPS = ~66ms) agar CPU HP tidak panas
  int _lastUiEmitMs = 0;
  static const int UI_THROTTLE_MS = 66;

  bool get isConnected => connectionNotifier.value;
  int get port => _port;
  String get targetIp => _targetIp;

  void updateTargetIp(String newIp) {
    _targetIp = newIp.trim();
    ipNotifier.value = _targetIp;
  }

  Timer? _httpPollTimer;
  bool _isHttpPolling = false;

  Future<void> start({int port = 4210, String targetIp = '192.168.4.1'}) async {
    if (_isRunning) return;
    _port = port;
    _targetIp = targetIp;
    _isRunning = true;

    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _port, reuseAddress: true);
      _socket?.broadcastEnabled = true;

      _socket?.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket?.receive();
          if (datagram != null) {
            _handlePacket(datagram.data, datagram.address.address);
          }
        }
      });
    } catch (e) {
      debugPrint('[UDP Service] Bind error: $e');
    }

    // 1. Watchdog koneksi tiap 1 detik
    _watchdogTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      final diff = now.difference(_lastPacketTime).inMilliseconds;
      final connected = diff < 3000;
      if (connectionNotifier.value != connected) {
        connectionNotifier.value = connected;
      }
    });

    // 2. HTTP Polling Fallback (Hanya jika UDP belum menerima paket)
    _httpPollTimer = Timer.periodic(const Duration(milliseconds: 300), (_) async {
      // Jika UDP sudah lancar mengalir, jangan membebani ESP dengan HTTP poll berulang
      final isUdpAlive = DateTime.now().difference(_lastPacketTime).inMilliseconds < 1500;
      if (isUdpAlive || _isHttpPolling) return;
      _isHttpPolling = true;
      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(milliseconds: 800);
        final request = await client.getUrl(Uri.parse('http://$_targetIp/data'));
        final response = await request.close();
        if (response.statusCode == 200) {
          final contents = await response.transform(utf8.decoder).join();
          _handlePacket(Uint8List.fromList(utf8.encode(contents)), _targetIp);
        }
      } catch (_) {
        // Silent error agar tidak memenuhi console log saat ESP sedang sibuk
      } finally {
        _isHttpPolling = false;
      }
    });
  }

  void _handlePacket(Uint8List data, String senderAddress) {
    try {
      final msg = utf8.decode(data, allowMalformed: true).trim();
      if (!msg.startsWith('{') || !msg.endsWith('}')) return;

      final dynamic decoded = jsonDecode(msg);
      if (decoded is! Map<String, dynamic>) return;

      _packetCounter++;
      _lastPacketTime = DateTime.now();

      if (!connectionNotifier.value) {
        connectionNotifier.value = true;
      }

      // Update IP target otomatis jika menerima dari ESP
      if (senderAddress != '127.0.0.1' && senderAddress != '0.0.0.0') {
        if (_targetIp != senderAddress) {
          _targetIp = senderAddress;
          ipNotifier.value = senderAddress;
        }
      }

      final parsed = PsuTelemetryData.fromJson(decoded);

      // 1. Buffer Riwayat PSU (CH2: v2 & i2)
      final double psuAmp = parsed.i2 / 1000.0;
      final double psuVolt = parsed.v2;
      ampHistory.removeAt(0);
      ampHistory.add(psuAmp);
      voltHistory.removeAt(0);
      voltHistory.add(psuVolt);

      // 2. Buffer Riwayat USB Charging (CH3: v3 & i3)
      final double usbAmp = parsed.i3 / 1000.0;
      final double usbVolt = parsed.v3;
      usbAmpHistory.removeAt(0);
      usbAmpHistory.add(usbAmp);
      usbVoltHistory.removeAt(0);
      usbVoltHistory.add(usbVolt);

      waveTickNotifier.value = _packetCounter;

      // Update data telemetri ke UI secara langsung
      dataNotifier.value = parsed;
      packetCountNotifier.value = _packetCounter;
    } catch (e) {
      debugPrint('[Packet Parse Error] $e');
    }
  }

  /// Kirim perintah kontrol (MOSFET / RELAY 1 / RELAY 2 / ALL)
  Future<void> sendCommand(String target, bool state) async {
    final int val = state ? 1 : 0;
    String fastCmd = '';
    if (target == 'mosfet') fastCmd = 'm$val';
    else if (target == 'relay1') fastCmd = 'r1$val';
    else if (target == 'relay2') fastCmd = 'r2$val';
    else if (target == 'all') fastCmd = 'all$val';

    // 1. Kirim via UDP cepat
    if (_socket != null && fastCmd.isNotEmpty) {
      try {
        final bytes = utf8.encode(fastCmd);
        // Kirim unicast ke target ESP dan broadcast jika belum dapat IP
        final targetAddr = InternetAddress.tryParse(_targetIp);
        if (targetAddr != null) {
          _socket?.send(bytes, targetAddr, _port);
        }
        _socket?.send(bytes, InternetAddress('255.255.255.255'), _port);
      } catch (e) {
        debugPrint('[UDP Send Error] $e');
      }
    }

    // 2. Fallback HTTP jika diperlukan
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(milliseconds: 300);
      final uri = Uri.parse('http://$_targetIp/cmd?set=$target&val=$val');
      final request = await client.getUrl(uri);
      final response = await request.close();
      response.drain();
    } catch (_) {}
  }

  void stop() {
    _watchdogTimer?.cancel();
    _httpPollTimer?.cancel();
    _socket?.close();
    _socket = null;
    _isRunning = false;
    connectionNotifier.value = false;
  }
}
