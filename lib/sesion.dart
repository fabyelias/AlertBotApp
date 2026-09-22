import 'package:shared_preferences/shared_preferences.dart';

/// Lo único que la app recuerda entre aperturas: el `idVecino` (token
/// secreto) que devolvió el registro. Con eso alcanza para saber a quién
/// consultar y en nombre de quién activar alertas.
class Sesion {
  static const _clave = 'id_vecino';

  static Future<String?> leerIdVecino() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_clave);
  }

  static Future<void> guardarIdVecino(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clave, id);
  }

  static Future<void> borrar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_clave);
  }
}
