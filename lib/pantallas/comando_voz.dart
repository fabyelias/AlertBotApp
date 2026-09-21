import 'package:flutter/material.dart';
import '../tema.dart';

class PantallaComandoVoz extends StatelessWidget {
  const PantallaComandoVoz({super.key});

  static const _frases = [
    ('🆘', 'activa caída'),
    ('🚨', 'activa robo'),
    ('🚑', 'activa emergencia médica'),
    ('🔥', 'activa incendio'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comando de voz')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Con el teléfono bloqueado, decí:',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AlertBotColores.verdeOscuro),
            ),
            const SizedBox(height: 16),
            ..._frases.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDCE6DF)),
                    ),
                    child: Row(
                      children: [
                        Text(f.$1, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('"Oye AlertBot, ${f.$2}"',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 8),
            const Text(
              'Pensado para emergencias donde no podés tocar el teléfono: '
              'una caída, o si están entrando a robar.',
              style: TextStyle(color: AlertBotColores.textoSuave, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
