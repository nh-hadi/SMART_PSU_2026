class ProbeHistoryItem {
  final String time;
  final String mode;
  final String value;
  final String note;

  const ProbeHistoryItem({
    required this.time,
    required this.mode,
    required this.value,
    required this.note,
  });

  Map<String, String> toMap() {
    return {
      'time': time,
      'mode': mode,
      'value': value,
      'note': note,
    };
  }

  factory ProbeHistoryItem.fromMap(Map<String, String> map) {
    return ProbeHistoryItem(
      time: map['time'] ?? '',
      mode: map['mode'] ?? '',
      value: map['value'] ?? '',
      note: map['note'] ?? '',
    );
  }
}
