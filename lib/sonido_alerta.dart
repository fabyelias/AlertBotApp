import 'package:shared_preferences/shared_preferences.dart';

/// Una opción de sonido de alerta. `canal` es el id del canal de
/// notificaciones de Android (y el nombre del recurso en
/// android/app/src/main/res/raw/) — null significa "el sonido por
/// defecto de AlertBot", sin canal propio.
class SonidoAlerta {
  final String? canal;
  final String nombre;
  final String descripcion;

  const SonidoAlerta({required this.canal, required this.nombre, required this.descripcion});
}

/// Sonidos disponibles para las alertas — pensados para sonar distinto
/// a una notificación cualquiera, con estilo de sirena de patrullero,
/// algo que ningún vecino confunda con un mensaje común.
const sonidosDisponibles = [
  SonidoAlerta(canal: null, nombre: 'Sonido por defecto', descripcion: 'El aviso estándar de notificaciones'),
  SonidoAlerta(
    canal: 'alertbot_sirena_clasica',
    nombre: 'Sirena clásica',
    descripcion: 'Sirena continua, en subida y bajada',
  ),
  SonidoAlerta(
    canal: 'alertbot_sirena_corta',
    nombre: 'Sirena corta (yelp)',
    descripcion: 'Igual, pero más rápida y corta',
  ),
  SonidoAlerta(
    canal: 'alertbot_sirena_dostonos',
    nombre: 'Sirena dos tonos',
    descripcion: 'Alterna entre dos tonos fijos',
  ),
];

class PreferenciaSonido {
  static const _clave = 'canal_sonido_alerta';

  /// El canal elegido, o null si es "por defecto" (o si todavía no
  /// eligió ninguno — incluso comportamiento).
  static Future<String?> leer() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_clave);
  }

  static Future<void> guardar(String? canal) async {
    final prefs = await SharedPreferences.getInstance();
    if (canal == null) {
      await prefs.remove(_clave);
    } else {
      await prefs.setString(_clave, canal);
    }
  }
}
