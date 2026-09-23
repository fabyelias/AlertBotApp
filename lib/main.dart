import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'tema.dart';
import 'pantallas/arranque.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
