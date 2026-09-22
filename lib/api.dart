import 'dart:convert';
import 'package:http/http.dart' as http;

/// El servidor respondió con un error (o con algo que la app no entiende).
/// Los fallos de red (sin conexión, timeout) NO son esto: se propagan como
/// las excepciones originales, así las pantallas distinguen "el servidor
/// dijo que no" de "no pude llegar al servidor".
class ErrorApi implements Exception {
  final int codigo;
  final String mensaje;
  const ErrorApi(this.codigo, this.mensaje);

  @override
  String toString() => 'ErrorApi($codigo): $mensaje';
}

/// Cliente contra el backend de AlertBot (el mismo servidor de Railway que
/// ya usa el bot de Telegram y el comando de voz de Siri). Las rutas viven
/// en api_app.py del repo del bot.
///
/// El vecino no tiene usuario ni contraseña: al registrarse el servidor le
/// devuelve un token secreto (acá le decimos `idVecino`) que la app guarda
/// (ver sesion.dart) y manda en cada pedido después.
class AlertBotApi {
  static const String baseUrl = 'https://alertbot-production-eee7.up.railway.app';
  static const Duration _espera = Duration(seconds: 15);
  static const _headersJson = {'Content-Type': 'application/json'};

  static Map<String, dynamic> _cuerpo(http.Response resp) {
    try {
      final data = jsonDecode(resp.body);
      return data is Map<String, dynamic> ? data : {};
    } on FormatException {
      return {};
    }
  }

  static ErrorApi _error(http.Response resp) => ErrorApi(
        resp.statusCode,
        _cuerpo(resp)['error']?.toString() ?? 'Error ${resp.statusCode}',
      );

  /// Envía la solicitud de alta de un vecino nuevo. El backend le avisa
  /// al administrador por Telegram para que apruebe o rechace, igual que
  /// hoy hace con los registros que llegan desde el bot. Devuelve el
  /// `idVecino` con el que hay que consultar el estado y activar alertas.
  static Future<String> registrarVecino({
    required String nombre,
    required String apellido,
    required String direccion,
    required double lat,
    required double lon,
    String? tokenPush,
  }) async {
    final resp = await http
        .post(
          Uri.parse('$baseUrl/api/registro'),
          headers: _headersJson,
          body: jsonEncode({
            'nombre': nombre,
            'apellido': apellido,
            'direccion': direccion,
            'lat': lat,
            'lon': lon,
            if (tokenPush != null) 'token_push': tokenPush,
          }),
        )
        .timeout(_espera);
    if (resp.statusCode != 201) throw _error(resp);

    final id = _cuerpo(resp)['id_vecino'];
    if (id is! String) {
      throw ErrorApi(resp.statusCode, 'Respuesta inesperada del servidor');
    }
    return id;
  }

  /// Estado del vecino según el admin: 'pendiente', 'aprobado',
  /// 'rechazado' o 'baja'. Devuelve 'desconocido' si el servidor no
  /// reconoce el token (por ejemplo, si se borró la base de datos).
  static Future<String> consultarEstado(String idVecino) async {
    final resp = await http
        .get(Uri.parse('$baseUrl/api/estado/${Uri.encodeComponent(idVecino)}'))
        .timeout(_espera);
    final cuerpo = _cuerpo(resp);
    // Solo el 404 con el JSON de error de nuestro backend significa "token
    // desconocido"; un 404 pelado (ruta inexistente, servidor viejo) no
    // debe hacerle creer a la app que el vecino dejó de existir.
    if (resp.statusCode == 404 && cuerpo.containsKey('error')) return 'desconocido';
    if (resp.statusCode != 200) throw _error(resp);
    return cuerpo['estado'] as String? ?? 'pendiente';
  }

  /// Activa una alerta de pánico para el vecino ya aprobado. `categoria`
  /// es una de: robo, sospechoso, medica, otro. Si el servidor rechaza el
  /// pedido lanza [ErrorApi] (403 = el vecino no está aprobado).
  static Future<void> activarPanico({
    required String idVecino,
    required String categoria,
  }) async {
    final resp = await http
        .post(
          Uri.parse('$baseUrl/api/panico'),
          headers: _headersJson,
          body: jsonEncode({'id_vecino': idVecino, 'categoria': categoria}),
        )
        .timeout(_espera);
    if (resp.statusCode != 200) throw _error(resp);
  }
}
