/// Model data untuk channel USB
class UsbChannelData {
  final int ch;
  final String name;
  final String volt;
  final String amp;
  final String watt;
  final String mah;
  final String wh;
  final String dp;
  final String dm;
  final String protocol;
  final bool active;
  final double liveVolt;
  final double liveAmp;

  const UsbChannelData({
    required this.ch,
    required this.name,
    required this.volt,
    required this.amp,
    required this.watt,
    required this.mah,
    required this.wh,
    required this.dp,
    required this.dm,
    required this.protocol,
    required this.active,
    required this.liveVolt,
    required this.liveAmp,
  });

  Map<String, dynamic> toMap() => {
    'ch': ch,
    'name': name,
    'volt': volt,
    'amp': amp,
    'watt': watt,
    'mah': mah,
    'wh': wh,
    'dp': dp,
    'dm': dm,
    'protocol': protocol,
    'active': active,
    'liveVolt': liveVolt,
    'liveAmp': liveAmp,
  };

  factory UsbChannelData.fromMap(Map<String, dynamic> map) => UsbChannelData(
    ch: map['ch'] as int,
    name: map['name'] as String,
    volt: map['volt'] as String,
    amp: map['amp'] as String,
    watt: map['watt'] as String,
    mah: map['mah'] as String,
    wh: map['wh'] as String,
    dp: map['dp'] as String,
    dm: map['dm'] as String,
    protocol: map['protocol'] as String,
    active: map['active'] as bool? ?? true,
    liveVolt: (map['liveVolt'] as num).toDouble(),
    liveAmp: (map['liveAmp'] as num).toDouble(),
  );
}

/// Sample data awal untuk 4 channel USB
final List<Map<String, dynamic>> defaultUsbChannelsData = [
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
    'liveVolt': 5.120,
    'liveAmp': 1.850,
  },
  {
    'ch': 2,
    'name': 'CH 2 (PD 20W)',
    'volt': '9.080 V',
    'amp': '2.210 A',
    'watt': '20.06 W',
    'mah': '850 mAh',
    'wh': '7.65 Wh',
    'dp': '0.00 V',
    'dm': '0.00 V',
    'protocol': 'PD 3.0 (9V)',
    'active': true,
    'liveVolt': 9.080,
    'liveAmp': 2.210,
  },
  {
    'ch': 3,
    'name': 'CH 3 (AUTO)',
    'volt': '5.040 V',
    'amp': '0.000 A',
    'watt': '0.000 W',
    'mah': '0 mAh',
    'wh': '0.00 Wh',
    'dp': '0.00 V',
    'dm': '0.00 V',
    'protocol': 'STANDBY',
    'active': false,
    'liveVolt': 5.040,
    'liveAmp': 0.000,
  },
  {
    'ch': 4,
    'name': 'CH 4 (NORMAL)',
    'volt': '5.180 V',
    'amp': '0.980 A',
    'watt': '5.076 W',
    'mah': '2310 mAh',
    'wh': '11.96 Wh',
    'dp': '1.98 V',
    'dm': '1.98 V',
    'protocol': 'DCP 1.5A',
    'active': true,
    'liveVolt': 5.180,
    'liveAmp': 0.980,
  },
];
