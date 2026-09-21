import 'package:flutter/material.dart';

/// Paleta de AlertBot: verde barrial + blanco, el mismo espíritu del bot
/// de Telegram (escudo, casita, seguridad de cercanía).
class AlertBotColores {
  static const verdePrincipal = Color(0xFF1E7A46);
  static const verdeOscuro = Color(0xFF0F4C2C);
  static const verdeClaro = Color(0xFFE8F5EC);
  static const rojoPanico = Color(0xFFD32F2F);
  static const fondo = Color(0xFFF7FAF8);
  static const textoSuave = Color(0xFF5B6B62);
}

ThemeData temaAlertBot() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AlertBotColores.fondo,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AlertBotColores.verdePrincipal,
      primary: AlertBotColores.verdePrincipal,
      surface: AlertBotColores.fondo,
    ),
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: AlertBotColores.verdePrincipal,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AlertBotColores.verdePrincipal,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDCE6DF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDCE6DF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AlertBotColores.verdePrincipal, width: 2),
      ),
    ),
  );
}
