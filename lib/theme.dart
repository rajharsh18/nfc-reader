import 'package:flutter/material.dart';

const ink = Color(0xFF070E1A);
const paper = Color(0xFF101C30);
const paperHigh = Color(0xFF16263F);
const line = Color(0xFF2C4260);
const blue = Color(0xFF1070F8);
const onBlue = Color(0xFFFFFFFF);
const sky = Color(0xFF8EBEFF);
const mist = Color(0xFF93A7C4);
const foam = Color(0xFFF4F7FC);
const coral = Color(0xFFFF6B57);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: blue,
    brightness: Brightness.dark,
    primary: blue,
    onPrimary: onBlue,
    secondary: sky,
    onSecondary: const Color(0xFF071426),
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
    splashColor: blue.withValues(alpha: 0.16),
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
        backgroundColor: blue,
        foregroundColor: onBlue,
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
        foregroundColor: blue,
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
        borderSide: const BorderSide(color: blue, width: 1.4),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF0C1626),
      indicatorColor: blue,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? blue : mist,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? onBlue : mist);
      }),
    ),
    dividerColor: line,
  );
}
