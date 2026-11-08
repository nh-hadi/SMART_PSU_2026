import 'package:flutter/material.dart';

class AppTheme {
  static Color getColor(String themeName) {
    switch (themeName) {
      case 'FULL_COLOR':
        return const Color(0xFFFF007F); // Neon Rose / Rainbow vibrant accent
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

  static Widget buildPanel({
    double? height,
    required Widget child,
    required Color activeColor,
  }) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(
          color: activeColor,
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
