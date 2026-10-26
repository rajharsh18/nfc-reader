import 'package:flutter/material.dart';

const ink = Color(0xFF10140F);
const paper = Color(0xFF1C261A);
const paperHigh = Color(0xFF243026);
const line = Color(0xFF3C4A34);
const lime = Color(0xFFD6F25C);
const limeInk = Color(0xFF172000);
const brass = Color(0xFFE4C27A);
const mist = Color(0xFF9AA894);
const foam = Color(0xFFF4F7EF);
const coral = Color(0xFFFF6B57);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: lime,
    brightness: Brightness.dark,
    primary: lime,
    onPrimary: limeInk,
    secondary: brass,
    onSecondary: const Color(0xFF2A2108),
    error: coral,
    onError: const Color(0xFF2D0906),
    surface: ink,
  );

  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: const BorderSide(color: line),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: ink,
    splashColor: lime.withValues(alpha: 0.12),
    textTheme: ThemeData(
      brightness: Brightness.dark,
    ).textTheme.apply(bodyColor: foam, displayColor: foam),
    appBarTheme: const AppBarTheme(
      backgroundColor: ink,
      foregroundColor: foam,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: const CardThemeData(
      color: paper,
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    dialogTheme: const DialogThemeData(backgroundColor: paper),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: paperHigh,
      contentTextStyle: TextStyle(color: foam),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: lime,
        foregroundColor: limeInk,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: foam,
        side: const BorderSide(color: line),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: lime,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: paper,
      hintStyle: const TextStyle(color: mist),
      labelStyle: const TextStyle(color: mist),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: lime, width: 1.4),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF171E16),
      indicatorColor: lime,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? lime : mist,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? limeInk : mist);
      }),
    ),
    dividerColor: line,
  );
}
