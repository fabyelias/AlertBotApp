import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'tema.dart';
import 'notificaciones.dart';
import 'notificaciones_locales.dart';
import 'sonido_alerta.dart';
import 'pantallas/arranque.dart';
import 'pantallas/ver_alerta.dart';
import 'pantallas/ver_foto.dart';

/// Para navegar desde los handlers de notificaciones push, que corren
/// fuera del árbol de widgets (no tienen su propio BuildContext).
final navigatorKey = GlobalKey<NavigatorState>();

/// Corre en un isolate aparte, incluso con la app cerrada del todo — por
/// eso necesita su propio Firebase.initializeApp() y no puede tocar nada
/// del árbol de widgets (ni navigatorKey). Solo guarda la alerta
/// localmente, para que la vea apenas abra la app por cualquier lado, no
/// solo si toca la notificación.
@pragma('vm:entry-point')
Future<void> _manejarMensajeEnSegundoPlano(RemoteMessage mensaje) async {
  await Firebase.initializeApp();
  await _guardarSiEsAlerta(mensaje);
}

Future<void> _guardarSiEsAlerta(RemoteMessage mensaje) async {
  final tipo = mensaje.data['tipo'];
  if (tipo == null) return;
  await Notificaciones.agregar(
    tipo: tipo,
    titulo: mensaje.data['titulo'],
    cuerpo: mensaje.data['cuerpo'],
    alertaId: int.tryParse(mensaje.data['alerta_id'] ?? ''),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Arma los canales de notificación de Android (uno por sirena
  // disponible) — hace falta que existan antes de que llegue cualquier
  // push, sea que lo muestre el sistema solo (app en segundo plano) o
  // que lo mostremos nosotros acá abajo (app en primer plano).
  await inicializarNotificacionesLocales();

  // Con la app en segundo plano o cerrada del todo: guarda la alerta
  // apenas llega, la haya tocado o no.
  FirebaseMessaging.onBackgroundMessage(_manejarMensajeEnSegundoPlano);

  // Tocaron una notificación y la app estaba en segundo plano.
  FirebaseMessaging.onMessageOpenedApp.listen(_abrirDesdeNotificacion);

  runApp(const AlertBotApp());

  // Tocaron una notificación y la app estaba cerrada del todo — esto
  // resuelve recién después de que arrancó la app, así que va después
  // de runApp (necesita que el Navigator ya esté montado).
  final mensajeInicial = await FirebaseMessaging.instance.getInitialMessage();
  if (mensajeInicial != null) _abrirDesdeNotificacion(mensajeInicial);

  // La app estaba abierta cuando llegó: Android no muestra sola una
  // notificación de sistema en este caso (y por lo tanto tampoco suena
  // nada), así que la mostramos nosotros con el sonido elegido, además
  // de un aviso rápido dentro de la app (y la guardamos, por si el
  // vecino ignora ambos).
  FirebaseMessaging.onMessage.listen((mensaje) async {
    await _guardarSiEsAlerta(mensaje);
    final tipo = mensaje.data['tipo'];
    if (tipo == null) return;
    final (titulo, cuerpo) = _tituloYCuerpoLocal(tipo, mensaje);
    final canalSonido = await PreferenciaSonido.leer();
    await mostrarNotificacionLocal(titulo: titulo, cuerpo: cuerpo, canal: canalSonido);
    final context = navigatorKey.currentContext;
    if (context == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_avisoCorto(tipo, mensaje.data['titulo'])),
      action: SnackBarAction(label: 'Ver', onPressed: () => _abrirDesdeNotificacion(mensaje)),
    ));
  });
}

/// Título y cuerpo para la notificación local que mostramos nosotros
/// (a diferencia de _avisoCorto, que es un solo texto para el SnackBar).
(String, String) _tituloYCuerpoLocal(String tipo, RemoteMessage mensaje) {
  switch (tipo) {
    case 'foto':
      return ('📸 Alguien compartió algo cerca tuyo', 'Tocá para verlo.');
    case 'ronda':
      return ('🚶 ${mensaje.data['titulo'] ?? 'Novedad de rondas'}', mensaje.data['cuerpo'] ?? 'Tocá para ver el detalle.');
    case 'panico':
      return ('🚨 ${mensaje.data['titulo'] ?? 'Alerta del barrio'}', mensaje.data['cuerpo'] ?? 'Tocá para ver el detalle.');
    default:
      return (mensaje.data['titulo'] ?? 'AlertBot', mensaje.data['cuerpo'] ?? '');
  }
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

/// Al tocar la notificación (o el botón "Ver" del aviso en primer plano),
/// abre la pantalla del aviso Y marca todo como visto — sigue en el
/// historial de la campanita, pero ya no hace falta que le siga
/// apareciendo el aviso arriba del botón de Pánico en Inicio.
void _abrirDesdeNotificacion(RemoteMessage mensaje) {
  final tipo = mensaje.data['tipo'];
  if (tipo == 'foto') {
    final alertaId = int.tryParse(mensaje.data['alerta_id'] ?? '');
    if (alertaId == null) return;
    Notificaciones.marcarTodasVistas();
    navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => PantallaVerFoto(alertaId: alertaId)));
    return;
  }
  if (tipo == 'panico' || tipo == 'ronda') {
    final titulo = mensaje.data['titulo'];
    final cuerpo = mensaje.data['cuerpo'];
    if (titulo == null || cuerpo == null) return;
    Notificaciones.marcarTodasVistas();
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
