import 'package:flutter/material.dart';

/// Paleta de AlertBot, calcada de los colores reales del chat de Telegram
/// del bot (medidos con un muestreo de píxeles sobre capturas del video de
/// referencia): el verde salvia del fondo del chat, el verde menta de las
/// burbujas/botones, y el verde oscuro de los acentos y el texto.
class AlertBotColores {
  static const verdePrincipal = Color(0xFF4F7A5C); // acento oscuro: AppBar, botones, texto de marca
  static const verdeOscuro = Color(0xFF35543F); // variante más oscura (snackbar, texto fuerte)
  static const verdeClaro = Color(0xFFE3F0DC); // fondo pálido detrás de íconos
  static const verdeMenta = Color(0xFFDCF0C7); // burbuja/botón resaltado (como el "Hola" saliente del chat)
  static const verdeGradiente = Color(0xFF9AC58C); // verde salvia del wallpaper del chat
  static const rojoPanico = Color(0xFFD32F2F);
  static const rojoPanicoClaro = Color(0xFFFCE9E9);
  static const fondo = Color(0xFFF1F7EC); // fondo de pantalla, versión clara del wallpaper
  static const textoSuave = Color(0xFF5B6B5E);
  static const borde = Color(0xFFD3E3C8);
}

/// El mismo degradé suave del wallpaper del chat, para el encabezado de
/// Inicio y otros bloques "hero".
const gradienteAlertBot = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [AlertBotColores.verdeGradiente, AlertBotColores.verdePrincipal],
);

const radioTarjeta = 20.0;
const radioBoton = 16.0;

List<BoxShadow> sombraTarjeta({Color? color}) => [
      BoxShadow(
        color: (color ?? Colors.black).withOpacity(0.06),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ];

ThemeData temaAlertBot() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AlertBotColores.fondo,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AlertBotColores.verdePrincipal,
      primary: AlertBotColores.verdePrincipal,
      error: AlertBotColores.rojoPanico,
      surface: AlertBotColores.fondo,
    ),
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: AlertBotColores.verdePrincipal,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radioTarjeta)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AlertBotColores.verdePrincipal,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AlertBotColores.verdePrincipal.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radioBoton)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AlertBotColores.verdePrincipal,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        side: const BorderSide(color: AlertBotColores.verdePrincipal),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radioBoton)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AlertBotColores.verdePrincipal,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AlertBotColores.borde),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AlertBotColores.borde),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AlertBotColores.verdePrincipal, width: 2),
      ),
      labelStyle: const TextStyle(color: AlertBotColores.textoSuave),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AlertBotColores.verdeOscuro,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.all(16),
    ),
    dividerTheme: const DividerThemeData(color: AlertBotColores.borde, space: 32),
  );
}
