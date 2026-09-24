import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Una notificación (push de Pánico, Ronda o Foto/clip) guardada en el
/// celular, tal cual llegó — se arma una sola vez al recibirla y no
/// vuelve a pedirle nada al backend.
class NotificacionGuardada {
  final String tipo; // 'panico' | 'ronda' | 'foto'
  final String? titulo;
  final String? cuerpo;
  final int? alertaId;
  final int fechaMillis;
  final bool visto;

  const NotificacionGuardada({
    required this.tipo,
    this.titulo,
    this.cuerpo,
    this.alertaId,
    required this.fechaMillis,
    required this.visto,
  });

  DateTime get fecha => DateTime.fromMillisecondsSinceEpoch(fechaMillis);

  Map<String, dynamic> toJson() => {
        'tipo': tipo,
        'titulo': titulo,
        'cuerpo': cuerpo,
        'alertaId': alertaId,
        'fechaMillis': fechaMillis,
        'visto': visto,
      };

  factory NotificacionGuardada.fromJson(Map<String, dynamic> j) => NotificacionGuardada(
        tipo: j['tipo'] as String,
        titulo: j['titulo'] as String?,
        cuerpo: j['cuerpo'] as String?,
        alertaId: j['alertaId'] as int?,
        fechaMillis: j['fechaMillis'] as int,
        visto: j['visto'] as bool? ?? false,
      );

  NotificacionGuardada copyWith({bool? visto}) => NotificacionGuardada(
        tipo: tipo,
        titulo: titulo,
        cuerpo: cuerpo,
        alertaId: alertaId,
        fechaMillis: fechaMillis,
        visto: visto ?? this.visto,
      );
}

/// Guarda en el celular las últimas notificaciones que le llegaron a
/// este vecino, hayan sido tocadas o no. Una sola lista sirve para dos
/// cosas: el aviso de "alerta sin ver" en Inicio (la más nueva sin ver)
/// y la campanita (el historial completo).
class Notificaciones {
  static const _clave = 'historial_notificaciones';
  static const _maximo = 30;

  static Future<List<NotificacionGuardada>> listar() async {
    final prefs = await SharedPreferences.getInstance();
    final crudo = prefs.getString(_clave);
    if (crudo == null) return [];
    try {
      final lista = jsonDecode(crudo) as List;
      return lista.map((e) => NotificacionGuardada.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _guardarLista(List<NotificacionGuardada> lista) async {
    final prefs = await SharedPreferences.getInstance();
    final recortada = lista.take(_maximo).toList();
    await prefs.setString(_clave, jsonEncode(recortada.map((n) => n.toJson()).toList()));
  }

  /// Agrega una notificación nueva, arriba de todo (más reciente primero).
  static Future<void> agregar({
    required String tipo,
    String? titulo,
    String? cuerpo,
    int? alertaId,
  }) async {
    final lista = await listar();
    lista.insert(
      0,
      NotificacionGuardada(
        tipo: tipo,
        titulo: titulo,
        cuerpo: cuerpo,
        alertaId: alertaId,
        fechaMillis: DateTime.now().millisecondsSinceEpoch,
        visto: false,
      ),
    );
    await _guardarLista(lista);
  }

  /// La más nueva sin ver, o null si no hay ninguna — para el aviso
  /// arriba del botón de Pánico en Inicio.
  static Future<NotificacionGuardada?> pendiente() async {
    final lista = await listar();
    for (final n in lista) {
      if (!n.visto) return n;
    }
    return null;
  }

  /// Marca como vista una notificación puntual (no la borra, sigue en
  /// el historial de la campanita).
  static Future<void> marcarVista(NotificacionGuardada notificacion) async {
    final lista = await listar();
    final idx = lista.indexWhere((n) => n.fechaMillis == notificacion.fechaMillis);
    if (idx == -1) return;
    lista[idx] = lista[idx].copyWith(visto: true);
    await _guardarLista(lista);
  }

  /// Marca todas como vistas — al abrir el historial completo.
  static Future<void> marcarTodasVistas() async {
    final lista = await listar();
    if (lista.every((n) => n.visto)) return;
    await _guardarLista(lista.map((n) => n.copyWith(visto: true)).toList());
  }
}
