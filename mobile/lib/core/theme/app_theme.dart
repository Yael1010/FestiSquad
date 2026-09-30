import 'package:flutter/material.dart';

abstract final class FestiColors {
  static const background = Color(0xFF060B16);
  static const surface = Color(0xFF0D1728);
  static const blue = Color(0xFF2563EB);
  static const cyan = Color(0xFF2EC5F4);
  static const muted = Color(0xFF94A6BE);
  static const border = Color(0xFF20364F);
  static const gradient = LinearGradient(colors: [blue, cyan]);
  static const success = Color(0xFF4ADE80);
  static const warning = Color(0xFFFBBF24);
  static const danger = Color(0xFFFF8D8D);
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
      visualDensity: VisualDensity.standard,
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontWeight: FontWeight.w800, height: 1.2),
        titleLarge: TextStyle(fontWeight: FontWeight.w800, height: 1.25),
        titleMedium: TextStyle(fontWeight: FontWeight.w700, height: 1.3),
        bodyLarge: TextStyle(height: 1.45),
        bodyMedium: TextStyle(height: 1.45),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: FestiColors.background,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0A111E),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: FestiColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: FestiColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: FestiColors.cyan, width: 2)),
        hintStyle: const TextStyle(color: FestiColors.muted),
      ),
      cardTheme: CardThemeData(
        color: FestiColors.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: FestiColors.border),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF17243A),
        contentTextStyle: TextStyle(color: Color(0xFFF2F6FF)),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        height: 68,
        backgroundColor: Color(0xFF080F1C),
        indicatorColor: Color(0xFF103952),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: FestiColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: FestiColors.surface,
        showDragHandle: true,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
        foregroundColor: FestiColors.cyan,
        side: const BorderSide(color: FestiColors.border),
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      )),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
    );
