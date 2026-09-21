import 'package:flutter/material.dart';
import 'tema.dart';
import 'bienvenida.dart';

void main() {
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
      home: const PantallaBienvenida(),
    );
  }
}
