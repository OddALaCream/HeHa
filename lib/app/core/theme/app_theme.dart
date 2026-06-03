import 'package:flutter/material.dart';

/// Paleta y tema de la aplicacion: minimalista, monocromo blanco y negro.
class AppTheme {
  const AppTheme._();

  static const Color black = Colors.black;
  static const Color white = Colors.white;
  static const Color grey = Color(0xFF606060);
  static const Color lightGrey = Color(0xFFE8E8E8);
  static const Color panelGrey = Color(0xFFF6F6F6);
  static const Color borderGrey = Color(0xFFD0D0D0);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: white,
        colorScheme: const ColorScheme.light(
          primary: black,
          secondary: black,
          surface: white,
          onSurface: black,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: black,
          selectionColor: lightGrey,
          selectionHandleColor: black,
        ),
      );
}
