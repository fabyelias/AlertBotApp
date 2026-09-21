import 'dart:convert';
import 'package:http/http.dart' as http;

/// Cliente contra el backend de AlertBot (el mismo servidor de Railway que
/// ya usa el bot de Telegram y el comando de voz de Siri).
///
/// IMPORTANTE: los métodos de este archivo asumen que el backend ya tiene
/// las rutas /api/registro, /api/estado y /api/panico — todavía no
/// existen (ver el README del repo). Hasta que las construyamos, estas
/// llamadas van a fallar; quedan listas para conectar apenas el backend
/// esté pronto, sin tener que tocar las pantallas de la app.
class AlertBotApi {
  static const String baseUrl = 'https://alertbot-production-eee7.up.railway.app';

  /// Envía la solicitud de alta de un vecino nuevo. El backend le avisa
  /// al administrador por Telegram para que apruebe o rechace, igual que
  /// hoy hace con los registros que llegan desde el bot.
  static Future<Map<String, dynamic>> registrarVecino({
    required String nombre,
    required String apellido,
    required String direccion,
    required double lat,
    required double lon,
    required String tokenPush,
  }) async {
    final resp = await http.post(
      Uri.parse('$baseUrl/api/registro'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'apellido': apellido,
        'direccion': direccion,
        'lat': lat,
        'lon': lon,
        'token_push': tokenPush,
      }),
    );
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  /// Consulta si el vecino ya fue aprobado por el admin.
  static Future<String> consultarEstado(String idVecino) async {
    final resp = await http.get(Uri.parse('$baseUrl/api/estado/$idVecino'));
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return data['estado'] as String? ?? 'pendiente';
  }

  /// Activa una alerta de pánico para el vecino ya aprobado.
  static Future<bool> activarPanico({
    required String idVecino,
    required String categoria,
  }) async {
    final resp = await http.post(
      Uri.parse('$baseUrl/api/panico'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_vecino': idVecino, 'categoria': categoria}),
    );
    return resp.statusCode == 200;
  }
}
