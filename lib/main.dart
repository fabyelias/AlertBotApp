import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'tema.dart';
import 'pantallas/arranque.dart';

void main() {
  // Necesario para que el comando de voz pueda avisarle a la pantalla
  // cuando el servicio en primer plano arranca o para (ver
  // comando_voz_servicio.dart).
  FlutterForegroundTask.initCommunicationPort();
  runApp(const AlertBotApp());
}

class AlertBotApp extends StatelessWidget {
  const AlertBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AlertBot',
      debugShowCheckedModeBanner: false,
      theme: temaAlertBot(),
      home: const PantallaArranque(),
    );
  }
}
