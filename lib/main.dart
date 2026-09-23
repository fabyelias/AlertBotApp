import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'tema.dart';
import 'pantallas/arranque.dart';
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
    if (mensaje.data['tipo'] != 'foto') return;
    final context = navigatorKey.currentContext;
    if (context == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('📸 Alguien compartió algo cerca tuyo'),
      action: SnackBarAction(label: 'Ver', onPressed: () => _abrirDesdeNotificacion(mensaje)),
    ));
  });
}

void _abrirDesdeNotificacion(RemoteMessage mensaje) {
  if (mensaje.data['tipo'] != 'foto') return;
  final alertaId = int.tryParse(mensaje.data['alerta_id'] ?? '');
  if (alertaId == null) return;
  navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => PantallaVerFoto(alertaId: alertaId)));
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
