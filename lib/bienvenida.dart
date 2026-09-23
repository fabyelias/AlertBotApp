import 'package:flutter/material.dart';
import 'tema.dart';
import 'pantallas/registro.dart';

class PantallaBienvenida extends StatelessWidget {
  const PantallaBienvenida({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  gradient: gradienteAlertBot,
                  shape: BoxShape.circle,
                  boxShadow: sombraTarjeta(color: AlertBotColores.verdePrincipal),
                ),
                child: const Icon(Icons.shield_rounded, color: Colors.white, size: 64),
              ),
              const SizedBox(height: 28),
              const Text(
                'AlertBot',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AlertBotColores.verdeOscuro),
              ),
              const SizedBox(height: 12),
              const Text(
                'Seguridad de barrio, entre vecinos.\nUna alerta y todos se enteran.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AlertBotColores.textoSuave, height: 1.4),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PantallaRegistro()),
                    );
                  },
                  child: const Text('Comenzar registro'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
