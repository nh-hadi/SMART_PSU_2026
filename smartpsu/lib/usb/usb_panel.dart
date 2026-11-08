import 'package:flutter/material.dart';
import 'usb_models.dart';
import 'usb_page1_standard.dart';
import 'usb_page2_overview.dart';
import '../psu_udp_service.dart';

/// USB Panel View utama yang menggabungkan PageView Halaman 1 & Halaman 2
class UsbPanelView extends StatefulWidget {
  final Color activeColor;
  final String themeName;
  final Widget oscilloscopeWidget;

  const UsbPanelView({
    super.key,
    required this.activeColor,
    this.themeName = 'WIREFRAME',
    required this.oscilloscopeWidget,
  });

  @override
  State<UsbPanelView> createState() => _UsbPanelViewState();
}

class _UsbPanelViewState extends State<UsbPanelView> {
  int _selectedUsbChannel = 1;
  final PageController _rootPageController = PageController();
  late List<Map<String, dynamic>> _usbChannelsData;

  @override
  void initState() {
    super.initState();
    _usbChannelsData = List.from(defaultUsbChannelsData);
    PsuUdpService.instance.dataNotifier.addListener(_onDataUpdated);
  }

  void _onDataUpdated() {
    final cur = PsuUdpService.instance.dataNotifier.value;
    if (mounted) {
      setState(() {
        final double v = cur.v3;
        final double a = cur.i3 / 1000.0;
        final double w = v * a;
        _usbChannelsData[0] = {
          ..._usbChannelsData[0],
          'volt': '${v.toStringAsFixed(3)} V',
          'amp': '${a.toStringAsFixed(3)} A',
          'watt': '${w.toStringAsFixed(3)} W',
          'dp': '${cur.dp.toStringAsFixed(2)} V',
          'dm': '${cur.dm.toStringAsFixed(2)} V',
          'liveVolt': v,
          'liveAmp': a,
        };
      });
    }
  }

  @override
  void dispose() {
    PsuUdpService.instance.dataNotifier.removeListener(_onDataUpdated);
    _rootPageController.dispose();
    super.dispose();
  }

  void _navigateToPage(int page) {
    _rootPageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _rootPageController,
      children: [
        // Halaman 1: Normal Split View (Middle Panel + Oscilloscope)
        UsbPage1Standard(
          activeColor: widget.activeColor,
          themeName: widget.themeName,
          oscilloscopeWidget: widget.oscilloscopeWidget,
          channelsData: _usbChannelsData,
          selectedChannel: _selectedUsbChannel,
          onOpenOverview: () => _navigateToPage(1),
        ),

        // Halaman 2: Layar Penuh 4-Channel Overview
        UsbPage2Overview(
          channelsData: _usbChannelsData,
          themeName: widget.themeName,
          activeColor: widget.activeColor,
          onSelectChannel: (ch) {
            setState(() {
              _selectedUsbChannel = ch;
            });
            _navigateToPage(0);
          },
        ),
      ],
    );
  }
}
