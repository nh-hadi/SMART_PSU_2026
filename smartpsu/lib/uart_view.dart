import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';

class UartTerminalView extends StatefulWidget {
  final Color activeColor;

  const UartTerminalView({
    super.key,
    required this.activeColor,
  });

  @override
  State<UartTerminalView> createState() => _UartTerminalViewState();
}

class _UartTerminalViewState extends State<UartTerminalView> {
  final TextEditingController _cmdController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int _selectedBaudRate = 115200;
  bool _isHexMode = false;
  bool _autoScroll = true;
  bool _isConnected = true;

  final List<int> _baudRates = [9600, 19200, 38400, 57600, 115200, 230400, 460800, 921600];

  final List<Map<String, dynamic>> _logs = [
    {'time': '21:00:01', 'type': 'SYS', 'text': 'UART ESP12 Bridge initialized at 115200 8N1'},
    {'time': '21:00:02', 'type': 'RX', 'text': 'AT+GMR\r\nAT version:2.2.0.0\r\nSDK version:v3.4\r\nOK'},
    {'time': '21:00:05', 'type': 'TX', 'text': 'AT+SYSRAM?'},
    {'time': '21:00:05', 'type': 'RX', 'text': '+SYSRAM:38216\r\nOK'},
    {'time': '21:00:10', 'type': 'RX', 'text': '[INA3221] Ch1: 4.198V 1.342A | Ch2: 5.120V 1.850A'},
  ];

  @override
  void dispose() {
    _cmdController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendCommand([String? directText]) {
    final text = directText ?? _cmdController.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    setState(() {
      _logs.add({'time': timeStr, 'type': 'TX', 'text': text});
      if (directText == null) _cmdController.clear();
    });

    if (_autoScroll) {
      Timer(const Duration(milliseconds: 60), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
          );
        }
      });
    }

    // Mock response
    Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _logs.add({
          'time': timeStr,
          'type': 'RX',
          'text': text.startsWith('AT') ? 'OK' : 'ECHO: $text (ACK 0x06)',
        });
      });
      if (_autoScroll && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMacroChip(String label, String command) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _sendCommand(command);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white24, width: 0.8),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 7.5,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Toolbar
        AppTheme.buildPanel(
          height: 34,
          activeColor: widget.activeColor,
          child: Row(
            children: [
              const Icon(Icons.terminal, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              const Text(
                'UART SERIAL CONSOLE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8.5,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),

              // Status Connection
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: _isConnected ? Colors.greenAccent.withOpacity(0.15) : Colors.redAccent.withOpacity(0.15),
                  border: Border.all(color: _isConnected ? Colors.greenAccent : Colors.redAccent, width: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  _isConnected ? 'CONNECTED' : 'DISCONNECTED',
                  style: TextStyle(
                    color: _isConnected ? Colors.greenAccent : Colors.redAccent,
                    fontSize: 7,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),

              // Baudrate Dropdown
              const Text('BAUD: ', style: TextStyle(color: Colors.white60, fontSize: 8, fontFamily: 'monospace')),
              DropdownButton<int>(
                value: _selectedBaudRate,
                dropdownColor: const Color(0xFF161616),
                style: TextStyle(color: widget.activeColor, fontSize: 8.5, fontFamily: 'monospace'),
                underline: Container(height: 1, color: widget.activeColor),
                items: _baudRates.map((b) => DropdownMenuItem(value: b, child: Text('$b'))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedBaudRate = val);
                },
              ),
              const SizedBox(width: 8),

              // Hex Mode Toggle
              GestureDetector(
                onTap: () => setState(() => _isHexMode = !_isHexMode),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: _isHexMode ? widget.activeColor.withOpacity(0.2) : Colors.transparent,
                    border: Border.all(color: _isHexMode ? widget.activeColor : Colors.white24, width: 0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    'HEX',
                    style: TextStyle(
                      color: _isHexMode ? widget.activeColor : Colors.white60,
                      fontSize: 7.5,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // AutoScroll Toggle
              GestureDetector(
                onTap: () => setState(() => _autoScroll = !_autoScroll),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: _autoScroll ? widget.activeColor.withOpacity(0.2) : Colors.transparent,
                    border: Border.all(color: _autoScroll ? widget.activeColor : Colors.white24, width: 0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    'AUTOSCROLL',
                    style: TextStyle(
                      color: _autoScroll ? widget.activeColor : Colors.white60,
                      fontSize: 7.5,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Clear Console
              GestureDetector(
                onTap: () => setState(() => _logs.clear()),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24, width: 0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Text('CLEAR', style: TextStyle(color: Colors.white70, fontSize: 7.5, fontFamily: 'monospace')),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // Console Log Area
        Expanded(
          child: AppTheme.buildPanel(
            activeColor: widget.activeColor,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              itemCount: _logs.length,
              itemBuilder: (context, idx) {
                final log = _logs[idx];
                final type = log['type'] as String;
                Color typeColor = Colors.white70;
                if (type == 'TX') typeColor = Colors.cyanAccent;
                if (type == 'RX') typeColor = Colors.greenAccent;
                if (type == 'SYS') typeColor = Colors.amberAccent;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '[${log['time']}] ',
                        style: const TextStyle(color: Colors.white38, fontSize: 8, fontFamily: 'monospace'),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(color: typeColor, fontSize: 7.5, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          log['text'] as String,
                          style: TextStyle(
                            color: type == 'TX' ? Colors.cyanAccent : Colors.white,
                            fontSize: 8.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 4),

        // Quick Macro Shortcuts
        SizedBox(
          height: 24,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildMacroChip('AT', 'AT'),
              _buildMacroChip('RST', 'AT+RST'),
              _buildMacroChip('GMR (FW)', 'AT+GMR'),
              _buildMacroChip('RAM?', 'AT+SYSRAM?'),
              _buildMacroChip('INA_READ', 'CMD:INA_READ_ALL'),
              _buildMacroChip('ADC_RAW', 'CMD:ADC_GET_RAW'),
              _buildMacroChip('OCP_LIMIT_1A', 'CMD:SET_OCP=1.0'),
              _buildMacroChip('OCP_OFF', 'CMD:SET_OCP=0'),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // Bottom Input Bar
        AppTheme.buildPanel(
          height: 38,
          activeColor: widget.activeColor,
          child: Row(
            children: [
              const Text('TX > ', style: TextStyle(color: Colors.cyanAccent, fontSize: 9.5, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
              Expanded(
                child: TextField(
                  controller: _cmdController,
                  style: const TextStyle(color: Colors.white, fontSize: 9.5, fontFamily: 'monospace'),
                  decoration: const InputDecoration(
                    hintText: 'Ketik perintah UART / AT-Command...',
                    hintStyle: TextStyle(color: Colors.white30, fontSize: 9, fontFamily: 'monospace'),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (_) => _sendCommand(),
                ),
              ),
              GestureDetector(
                onTap: () => _sendCommand(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: widget.activeColor.withOpacity(0.2),
                    border: Border.all(color: widget.activeColor, width: 0.8),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    'KIRIM',
                    style: TextStyle(
                      color: widget.activeColor,
                      fontSize: 8.5,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
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
}
