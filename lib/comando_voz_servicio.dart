import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:porcupine_flutter/porcupine_error.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';

import 'api.dart';
import 'sesion.dart';

/// Qué está pasando con la escucha del comando de voz, para que la
/// pantalla (`comando_voz.dart`) muestre el estado sin conocer Porcupine.
enum EstadoComandoVoz {
  inactivo,
  escuchando,
  sinPermisoMicrofono,
  sinConfigurar,
  error,
  alertaEnviada,
  errorAlEnviar,
}

/// Detecta, con el teléfono bloqueado, las 4 frases de pánico de
/// `comando_voz.dart` y activa la alerta correspondiente sin que el
/// vecino toque la pantalla. Usa el motor de palabra de activación de
/// Picovoice Porcupine (offline, bajo consumo) y un servicio en primer
/// plano de Android (`flutter_foreground_task`) solo para evitar que el
/// sistema mate la app al bloquear la pantalla — Porcupine sigue
/// corriendo en el isolate principal, el servicio en primer plano no lo
/// reemplaza, solo lo mantiene con vida.
///
/// Para que esto funcione hacen falta, además de este código (ver
/// assets/wakewords/LEEME.md):
/// 1. Una cuenta gratis en https://console.picovoice.ai y su AccessKey,
///    pasada al compilar con `--dart-define=PICOVOICE_ACCESS_KEY=...`.
/// 2. Los 4 archivos `.ppn` (uno por frase) entrenados ahí para Android,
///    más el modelo de español `porcupine_params_es.pv`, copiados a
///    `assets/wakewords/`.
/// 3. Los permisos y el `<service>` de Android que se agregan en
///    `android/app/src/main/AndroidManifest.xml` (pendiente hasta que
///    esa carpeta se suba al repo — ver LEEME.md).
class ComandoVozServicio {
  ComandoVozServicio._();
  static final instancia = ComandoVozServicio._();

  static const _accessKey = String.fromEnvironment('PICOVOICE_ACCESS_KEY');
  static const _modeloEspanol = 'assets/wakewords/porcupine_params_es.pv';

  /// Archivo .ppn → categoría que entiende el backend (ver
  /// CATEGORIAS_PANICO en config.py del bot). "caida" e "incendio"
  /// todavía no tienen categoría propia ahí: el backend las muestra
  /// como "❗ Otro" hasta que se agreguen (son dos líneas en ese
  /// diccionario, no rompe nada agregarlas).
  static const _categoriaPorArchivo = {
    'assets/wakewords/activa_caida_es_android.ppn': 'caida',
    'assets/wakewords/activa_robo_es_android.ppn': 'robo',
    'assets/wakewords/activa_emergencia_medica_es_android.ppn': 'medica',
    'assets/wakewords/activa_incendio_es_android.ppn': 'incendio',
  };

  /// Si el AccessKey no se pasó al compilar, el toggle de la pantalla
  /// queda deshabilitado con una explicación en vez de intentar arrancar
  /// y fallar.
  bool get configurado => _accessKey.isNotEmpty;

  PorcupineManager? _manager;
  final _estadoCtrl = StreamController<EstadoComandoVoz>.broadcast();
  Stream<EstadoComandoVoz> get estado => _estadoCtrl.stream;

  bool get activo => _manager != null;

  Future<bool> activar() async {
    if (!configurado) {
      _emitir(EstadoComandoVoz.sinConfigurar);
      return false;
    }
    if (activo) return true;

    final permiso = await Permission.microphone.request();
    if (!permiso.isGranted) {
      _emitir(EstadoComandoVoz.sinPermisoMicrofono);
      return false;
    }
    // Android 13+: sin este permiso el servicio en primer plano no puede
    // mostrar la notificación persistente que exige el sistema.
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    try {
      _manager = await PorcupineManager.fromKeywordPaths(
        _accessKey,
        _categoriaPorArchivo.keys.toList(),
        _alDetectar,
        modelPath: _modeloEspanol,
        errorCallback: (error) => _emitir(EstadoComandoVoz.error),
      );
      await _manager!.start();
    } on PorcupineException {
      _manager = null;
      _emitir(EstadoComandoVoz.error);
      return false;
    }

    await _iniciarServicioPrimerPlano();
    _emitir(EstadoComandoVoz.escuchando);
    return true;
  }

  Future<void> desactivar() async {
    await _manager?.stop();
    await _manager?.delete();
    _manager = null;
    await FlutterForegroundTask.stopService();
    _emitir(EstadoComandoVoz.inactivo);
  }

  Future<void> _alDetectar(int indice) async {
    final categoria = _categoriaPorArchivo.values.elementAt(indice);
    final idVecino = await Sesion.leerIdVecino();
    if (idVecino == null) return;
    try {
      await AlertBotApi.activarPanico(idVecino: idVecino, categoria: categoria);
      _emitir(EstadoComandoVoz.alertaEnviada);
    } catch (_) {
      _emitir(EstadoComandoVoz.errorAlEnviar);
    }
    // Sigue escuchando: no se detiene el manager, la emergencia puede
    // seguir y el vecino puede necesitar repetir el comando.
    if (activo) _emitir(EstadoComandoVoz.escuchando);
  }

  Future<void> _iniciarServicioPrimerPlano() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'alertbot_comando_voz',
        channelName: 'Comando de voz de AlertBot',
        channelDescription: 'Mantiene activa la escucha del comando de voz con el teléfono bloqueado.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(showNotification: false),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(15000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
    await FlutterForegroundTask.startService(
      serviceId: 501,
      notificationTitle: 'AlertBot escuchando',
      notificationText: 'Comando de voz activo. Tocá para volver a la app.',
      callback: _iniciarTareaSegundoPlano,
    );
  }

  void _emitir(EstadoComandoVoz e) => _estadoCtrl.add(e);
}

/// El servicio en primer plano solo existe para que Android no mate el
/// proceso al bloquear la pantalla; no hace nada por sí mismo (Porcupine
/// sigue escuchando en el isolate principal de la app).
@pragma('vm:entry-point')
void _iniciarTareaSegundoPlano() {
  FlutterForegroundTask.setTaskHandler(_TareaComandoVoz());
}

class _TareaComandoVoz extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onReceiveData(Object data) {}

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {}

  @override
  void onNotificationDismissed() {}
}
