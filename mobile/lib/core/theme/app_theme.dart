import 'package:flutter/material.dart';

abstract final class FestiColors {
  static const background = Color(0xFF060B16);
  static const surface = Color(0xFF0D1728);
  static const blue = Color(0xFF2563EB);
  static const cyan = Color(0xFF2EC5F4);
  static const muted = Color(0xFF94A6BE);
  static const border = Color(0xFF20364F);
  static const gradient = LinearGradient(colors: [blue, cyan]);
}

ThemeData buildAppTheme() => ThemeData(
      fontFamily: 'FestiSans',
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
          primary: FestiColors.cyan,
          secondary: FestiColors.blue,
          surface: FestiColors.surface,
          onSurface: Color(0xFFF2F6FF)),
      scaffoldBackgroundColor: FestiColors.background,
      appBarTheme: const AppBarTheme(
          backgroundColor: FestiColors.background, centerTitle: false),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0A111E),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: FestiColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: FestiColors.border)),
        hintStyle: const TextStyle(color: FestiColors.muted),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
        foregroundColor: FestiColors.cyan,
        side: const BorderSide(color: FestiColors.border),
        minimumSize: const Size(0, 52),
        shape: const StadiumBorder(),
      )),
    );
