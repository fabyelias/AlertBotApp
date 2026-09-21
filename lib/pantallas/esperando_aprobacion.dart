import 'package:flutter/material.dart';
import '../tema.dart';
import 'inicio.dart';

class PantallaEsperandoAprobacion extends StatelessWidget {
  const PantallaEsperandoAprobacion({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_top_rounded, size: 72, color: AlertBotColores.verdePrincipal),
              const SizedBox(height: 24),
              const Text(
                '¡Listo! Tu solicitud está en revisión',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AlertBotColores.verdeOscuro),
              ),
              const SizedBox(height: 12),
              const Text(
                'El administrador del barrio ya la recibió. En cuanto te apruebe, '
                'te vamos a avisar acá mismo con una notificación.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: AlertBotColores.textoSuave, height: 1.4),
              ),
              const SizedBox(height: 40),
              // Botón de prueba temporal: en la versión final esta pantalla
              // avanza sola cuando llega la notificación push de aprobación.
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const PantallaInicio()),
                  );
                },
                child: const Text('(demo) Simular aprobación →'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
