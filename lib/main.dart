import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'tema.dart';
import 'pantallas/arranque.dart';
import 'pantallas/ver_alerta.dart';
import 'pantallas/ver_foto.dart';

/// Para navegar desde los handlers de notificaciones push, que corren
/// fuera del árbol de widgets (no tienen su propio BuildContext).
final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Tocaron una notificación y la app estaba en segundo plano.
  FirebaseMessaging.onMessageOpenedApp.listen(_abrirDesdeNotificacion);

  runApp(const AlertBotApp());

  // Tocaron una notificación y la app estaba cerrada del todo — esto
  // resuelve recién después de que arrancó la app, así que va después
  // de runApp (necesita que el Navigator ya esté montado).
  final mensajeInicial = await FirebaseMessaging.instance.getInitialMessage();
  if (mensajeInicial != null) _abrirDesdeNotificacion(mensajeInicial);

  // La app estaba abierta cuando llegó: Android no muestra sola una
  // notificación de sistema en este caso, así que avisamos nosotros.
  FirebaseMessaging.onMessage.listen((mensaje) {
    final tipo = mensaje.data['tipo'];
    if (tipo == null) return;
    final context = navigatorKey.currentContext;
    if (context == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_avisoCorto(tipo, mensaje.data['titulo'])),
      action: SnackBarAction(label: 'Ver', onPressed: () => _abrirDesdeNotificacion(mensaje)),
    ));
  });
}

String _avisoCorto(String tipo, String? titulo) {
  switch (tipo) {
    case 'foto':
      return '📸 Alguien compartió algo cerca tuyo';
    case 'ronda':
      return '🚶 ${titulo ?? 'Novedad de rondas'}';
    case 'panico':
      return '🚨 ${titulo ?? 'Alerta del barrio'}';
    default:
      return titulo ?? 'AlertBot';
  }
}

void _abrirDesdeNotificacion(RemoteMessage mensaje) {
  final tipo = mensaje.data['tipo'];
  if (tipo == 'foto') {
    final alertaId = int.tryParse(mensaje.data['alerta_id'] ?? '');
    if (alertaId == null) return;
    navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => PantallaVerFoto(alertaId: alertaId)));
    return;
  }
  if (tipo == 'panico' || tipo == 'ronda') {
    final titulo = mensaje.data['titulo'];
    final cuerpo = mensaje.data['cuerpo'];
    if (titulo == null || cuerpo == null) return;
    navigatorKey.currentState?.push(MaterialPageRoute(
      builder: (_) => PantallaVerAlerta(tipo: tipo!, titulo: titulo, cuerpo: cuerpo),
    ));
  }
}

class AlertBotApp extends StatelessWidget {
  const AlertBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'AlertBot',
      debugShowCheckedModeBanner: false,
      theme: temaAlertBot(),
      home: const PantallaArranque(),
    );
  }
}
