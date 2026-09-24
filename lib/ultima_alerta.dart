import 'package:shared_preferences/shared_preferences.dart';

/// Guarda la última alerta que llegó por push, apenas llega (aunque el
/// vecino no toque la notificación) — así, si abre la app por cualquier
/// otro lado (ícono, volver de otra app), igual la ve. Se guarda desde
/// el handler de segundo plano de Firebase, que corre incluso con la
/// app cerrada.
class UltimaAlerta {
  static const _claveTipo = 'ultima_alerta_tipo';
  static const _claveTitulo = 'ultima_alerta_titulo';
  static const _claveCuerpo = 'ultima_alerta_cuerpo';
  static const _claveAlertaId = 'ultima_alerta_id';

  static Future<void> guardar({
    required String tipo,
    String? titulo,
    String? cuerpo,
    int? alertaId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveTipo, tipo);
    if (titulo != null) {
      await prefs.setString(_claveTitulo, titulo);
    } else {
      await prefs.remove(_claveTitulo);
    }
    if (cuerpo != null) {
      await prefs.setString(_claveCuerpo, cuerpo);
    } else {
      await prefs.remove(_claveCuerpo);
    }
    if (alertaId != null) {
      await prefs.setInt(_claveAlertaId, alertaId);
    } else {
      await prefs.remove(_claveAlertaId);
    }
  }

  /// Devuelve la última alerta guardada (tipo, titulo, cuerpo, alertaId),
  /// o null si no hay ninguna pendiente de ver.
  static Future<Map<String, dynamic>?> leer() async {
    final prefs = await SharedPreferences.getInstance();
    final tipo = prefs.getString(_claveTipo);
    if (tipo == null) return null;
    return {
      'tipo': tipo,
      'titulo': prefs.getString(_claveTitulo),
      'cuerpo': prefs.getString(_claveCuerpo),
      'alertaId': prefs.getInt(_claveAlertaId),
    };
  }

  /// Se llama cuando el vecino ya la vio (tocó la notificación, o la
  /// descartó desde el aviso en Inicio) — así no vuelve a aparecer.
  static Future<void> borrar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_claveTipo);
    await prefs.remove(_claveTitulo);
    await prefs.remove(_claveCuerpo);
    await prefs.remove(_claveAlertaId);
  }
}
