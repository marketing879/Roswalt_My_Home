import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryMaroon = Color(0xFF543813);
  static const Color darkMaroon = Color(0xFF543813);
  static const Color lightMaroon = Color(0xFFB22222);
  static const Color goldAccent = Color(0xFFB8860B);
  static const Color goldLight = Color(0xFFD4AF37);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCardBg = Color(0xFF1E1E1E);
  static const Color creamBg = Color(0xFFFFF8F1);
  static const Color creamCard = Color(0xFFFFF8F1);

  static List<BoxShadow> clayShadow({
    Color? color,
    double intensity = 1.0,
  }) {
    final c = color ?? primaryMaroon;
    return [
      BoxShadow(
        color: c.withOpacity(0.22 * intensity),
        blurRadius: 22 * intensity,
        spreadRadius: 2,
        offset: Offset(6 * intensity, 8 * intensity),
      ),
      BoxShadow(
        color: const Color(0xFFF0F0F0).withOpacity(0.85),
        blurRadius: 10,
        spreadRadius: -2,
        offset: const Offset(-4, -4),
      ),
    ];
  }

  static List<BoxShadow> clayCardShadow({bool isDark = false}) {
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.5),
          blurRadius: 20,
          spreadRadius: 2,
          offset: const Offset(6, 8),
        ),
        BoxShadow(
          color: const Color(0xFFF0F0F0).withOpacity(0.04),
          blurRadius: 6,
          spreadRadius: -1,
          offset: const Offset(-3, -3),
        ),
      ];
    }
    return [
      BoxShadow(
        color: const Color(0xFFB8860B).withOpacity(0.2),
        blurRadius: 20,
        spreadRadius: 3,
        offset: const Offset(6, 8),
      ),
      BoxShadow(
        color: const Color(0xFF543813).withOpacity(0.08),
        blurRadius: 12,
        spreadRadius: 1,
        offset: const Offset(3, 4),
      ),
      BoxShadow(
        color: const Color(0xFFF0F0F0).withOpacity(0.9),
        blurRadius: 8,
        spreadRadius: -2,
        offset: const Offset(-4, -4),
      ),
    ];
  }

  static List<BoxShadow> clayButtonShadow() {
    return [
      BoxShadow(
        color: const Color(0xFF735C00).withOpacity(0.3),
        blurRadius: 10,
        offset: const Offset(4, 4),
      ),
      BoxShadow(
        color: const Color(0xFFF0F0F0).withOpacity(0.2),
        blurRadius: 6,
        offset: const Offset(-2, -2),
      ),
    ];
  }

  static ThemeData lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryMaroon,
      scaffoldBackgroundColor: creamBg,
      colorScheme: const ColorScheme.light(
        primary: primaryMaroon,
        secondary: goldAccent,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryMaroon,
        foregroundColor: const Color(0xFFF0F0F0),
        elevation: 0,
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryMaroon,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primaryMaroon,
        secondary: goldAccent,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF3A2509),
        foregroundColor: const Color(0xFFF0F0F0),
        elevation: 0,
      ),
    );
  }
}

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}