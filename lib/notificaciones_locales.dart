import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'sonido_alerta.dart';

/// Instancia única del plugin de notificaciones locales — se usa tanto
/// para mostrar el aviso con sonido cuando llega una alerta con la app
/// abierta (FCM no la muestra solo en ese caso) como para la vista
/// previa al elegir sonido en Ajustes.
final notificacionesLocales = FlutterLocalNotificationsPlugin();

/// Canal "por defecto": mismo sonido de siempre, sin sirena — se crea
/// solo (Android lo arma la primera vez que se usa) con los datos que
/// le pasamos en mostrarNotificacionLocal.
const _canalPorDefecto = 'alertbot_alertas_app';

const _nombreCanal = 'Alertas de AlertBot';
const _descripcionCanal = 'Avisos de pánico, rondas y foto/clip del barrio';

/// Arma de entrada los canales de Android para cada sirena — así están
/// listos desde el primer momento, tanto para cuando el vecino elige
/// una en Ajustes como para cuando le llega un push ya armado con ese
/// canal (con la app cerrada, es Android quien muestra la notificación
/// solo, y necesita que el canal ya exista).
Future<void> inicializarNotificacionesLocales() async {
  await notificacionesLocales.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  final androidPlugin = notificacionesLocales
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  if (androidPlugin == null) return;

  for (final sonido in sonidosDisponibles) {
    final canal = sonido.canal;
    if (canal == null) continue;
    await androidPlugin.createNotificationChannel(AndroidNotificationChannel(
      canal,
      '$_nombreCanal — ${sonido.nombre}',
      description: _descripcionCanal,
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound(canal),
    ));
  }
}

/// Muestra una notificación local con el sonido de un canal puntual —
/// para la alerta en primer plano y para la vista previa de sonidos.
/// `canal` null usa el sonido por defecto.
Future<void> mostrarNotificacionLocal({
  required String titulo,
  required String cuerpo,
  String? canal,
}) async {
  final detalleAndroid = AndroidNotificationDetails(
    canal ?? _canalPorDefecto,
    _nombreCanal,
    channelDescription: _descripcionCanal,
    importance: Importance.max,
    priority: Priority.high,
  );
  await notificacionesLocales.show(
    id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
    title: titulo,
    body: cuerpo,
    notificationDetails: NotificationDetails(android: detalleAndroid),
  );
}
