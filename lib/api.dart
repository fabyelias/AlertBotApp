import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

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

/// Datos del vecino que devuelve /api/estado, además del estado de
/// aprobación: sirven para saludarlo por nombre y para decidir si se le
/// muestran las funciones de titular (Mi dirección, Mi familia).
class PerfilVecino {
  final String estado;
  final String nombre;
  final String apellido;
  final String direccion;
  final bool esTitular;
  const PerfilVecino({
    required this.estado,
    required this.nombre,
    required this.apellido,
    required this.direccion,
    required this.esTitular,
  });
}

/// Un vecino haciendo ronda ahora mismo en el barrio.
class VecinoEnRonda {
  final String nombre;
  final String apellido;
  const VecinoEnRonda({required this.nombre, required this.apellido});
}

class EstadoRondas {
  final bool activa; // true = el vecino que consulta tiene una ronda propia activa
  final List<VecinoEnRonda> activas; // todos los vecinos en ronda ahora
  const EstadoRondas({required this.activa, required this.activas});
}

/// Un integrante ya sumado a la familia del titular.
class IntegranteFamilia {
  final String nombre;
  final String apellido;
  const IntegranteFamilia({required this.nombre, required this.apellido});
}

class InfoFamilia {
  final bool esTitular;
  final List<IntegranteFamilia> integrantes;
  final int cupoUsado;
  final int cupoMaximo;
  const InfoFamilia({
    required this.esTitular,
    this.integrantes = const [],
    this.cupoUsado = 0,
    this.cupoMaximo = 0,
  });
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
  // Subir/bajar una foto o video tarda más que un pedido de JSON chico,
  // sobre todo con una conexión de barrio floja.
  static const Duration _esperaArchivo = Duration(seconds: 60);
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

  /// Perfil completo del vecino: estado de aprobación, nombre, dirección
  /// y si es titular de su familia (de eso depende si se le muestran las
  /// funciones de Mi dirección y Mi familia).
  static Future<PerfilVecino> consultarPerfil(String idVecino) async {
    final resp = await http
        .get(Uri.parse('$baseUrl/api/estado/${Uri.encodeComponent(idVecino)}'))
        .timeout(_espera);
    final cuerpo = _cuerpo(resp);
    if (resp.statusCode == 404 && cuerpo.containsKey('error')) {
      return const PerfilVecino(estado: 'desconocido', nombre: '', apellido: '', direccion: '', esTitular: false);
    }
    if (resp.statusCode != 200) throw _error(resp);
    return PerfilVecino(
      estado: cuerpo['estado'] as String? ?? 'pendiente',
      nombre: cuerpo['nombre'] as String? ?? '',
      apellido: cuerpo['apellido'] as String? ?? '',
      direccion: cuerpo['direccion'] as String? ?? '',
      esTitular: cuerpo['es_titular'] as bool? ?? true,
    );
  }

  /// Si el vecino tiene una ronda propia activa, y quiénes están haciendo
  /// ronda ahora mismo en el barrio.
  static Future<EstadoRondas> consultarRondas(String idVecino) async {
    final resp = await http
        .get(Uri.parse('$baseUrl/api/rondas/estado/${Uri.encodeComponent(idVecino)}'))
        .timeout(_espera);
    if (resp.statusCode != 200) throw _error(resp);
    final cuerpo = _cuerpo(resp);
    final lista = (cuerpo['activas'] as List?) ?? const [];
    return EstadoRondas(
      activa: cuerpo['activa'] as bool? ?? false,
      activas: lista
          .whereType<Map>()
          .map((m) => VecinoEnRonda(nombre: m['nombre']?.toString() ?? '', apellido: m['apellido']?.toString() ?? ''))
          .toList(),
    );
  }

  /// Marca al vecino en ronda y avisa a los demás. Lanza [ErrorApi] con
  /// código 409 si ya tenía una ronda activa.
  static Future<void> iniciarRonda(String idVecino) async {
    final resp = await http
        .post(Uri.parse('$baseUrl/api/rondas/iniciar'), headers: _headersJson, body: jsonEncode({'id_vecino': idVecino}))
        .timeout(_espera);
    if (resp.statusCode != 200) throw _error(resp);
  }

  /// Cierra la ronda activa, con una novedad de texto libre opcional.
  /// Lanza [ErrorApi] con código 409 si no tenía ninguna ronda activa.
  static Future<void> finalizarRonda(String idVecino, {String? novedad}) async {
    final resp = await http
        .post(
          Uri.parse('$baseUrl/api/rondas/finalizar'),
          headers: _headersJson,
          body: jsonEncode({'id_vecino': idVecino, if (novedad != null && novedad.isNotEmpty) 'novedad': novedad}),
        )
        .timeout(_espera);
    if (resp.statusCode != 200) throw _error(resp);
  }

  /// Datos de familia del vecino. Si no es titular, solo trae `esTitular:
  /// false` (la gestión es solo del titular).
  static Future<InfoFamilia> consultarFamilia(String idVecino) async {
    final resp = await http
        .get(Uri.parse('$baseUrl/api/familia/${Uri.encodeComponent(idVecino)}'))
        .timeout(_espera);
    if (resp.statusCode != 200) throw _error(resp);
    final cuerpo = _cuerpo(resp);
    final esTitular = cuerpo['es_titular'] as bool? ?? false;
    if (!esTitular) return const InfoFamilia(esTitular: false);
    final lista = (cuerpo['integrantes'] as List?) ?? const [];
    return InfoFamilia(
      esTitular: true,
      integrantes: lista
          .whereType<Map>()
          .map((m) => IntegranteFamilia(nombre: m['nombre']?.toString() ?? '', apellido: m['apellido']?.toString() ?? ''))
          .toList(),
      cupoUsado: cuerpo['cupo_usado'] as int? ?? 0,
      cupoMaximo: cuerpo['cupo_maximo'] as int? ?? 0,
    );
  }

  /// Genera un link de invitación de un solo uso para sumar un integrante
  /// a la familia. Lanza [ErrorApi] 403 si el vecino no es titular, o 409
  /// si ya llegó al máximo de integrantes.
  static Future<String> generarInvitacionFamilia(String idVecino) async {
    final resp = await http
        .post(Uri.parse('$baseUrl/api/familia/invitar'), headers: _headersJson, body: jsonEncode({'id_vecino': idVecino}))
        .timeout(_espera);
    if (resp.statusCode != 200) throw _error(resp);
    final link = _cuerpo(resp)['link'];
    if (link is! String) throw ErrorApi(resp.statusCode, 'Respuesta inesperada del servidor');
    return link;
  }

  /// Actualiza la dirección del vecino (y la de toda su familia). Lanza
  /// [ErrorApi] 403 si el vecino no es titular. Devuelve la cantidad de
  /// integrantes de la familia también afectados por el cambio.
  static Future<int> actualizarDireccion({
    required String idVecino,
    required String direccion,
    required double lat,
    required double lon,
  }) async {
    final resp = await http
        .post(
          Uri.parse('$baseUrl/api/direccion'),
          headers: _headersJson,
          body: jsonEncode({'id_vecino': idVecino, 'direccion': direccion, 'lat': lat, 'lon': lon}),
        )
        .timeout(_espera);
    if (resp.statusCode != 200) throw _error(resp);
    return _cuerpo(resp)['integrantes_afectados'] as int? ?? 0;
  }

  /// Sube una foto o video para compartir con los vecinos — mismo destino
  /// que si se lo hubieran mandado al bot por Telegram. `tipoMime` tiene
  /// que ser uno de los que acepta el backend (image/jpeg, image/png,
  /// image/webp, video/mp4, video/quicktime, video/3gpp). Devuelve el id
  /// de la alerta creada.
  static Future<int> enviarFoto({
    required String idVecino,
    required List<int> bytes,
    required String nombreArchivo,
    required String tipoMime,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/foto'))
      ..fields['id_vecino'] = idVecino
      ..files.add(http.MultipartFile.fromBytes(
        'archivo',
        bytes,
        filename: nombreArchivo,
        contentType: MediaType.parse(tipoMime),
      ));
    final enviado = await request.send().timeout(_esperaArchivo);
    final resp = await http.Response.fromStream(enviado);
    if (resp.statusCode != 200) throw _error(resp);
    return _cuerpo(resp)['alerta_id'] as int? ?? 0;
  }
}
