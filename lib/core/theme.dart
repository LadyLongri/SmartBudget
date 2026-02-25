import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightFinanceTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF4C86E9),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFEAF2FF),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 42,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
      titleLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    ),
  );

  static final ThemeData darkFinanceTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF192838),
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF0C131D),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 42,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
      titleLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    ),
  );
}
