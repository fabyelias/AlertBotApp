import 'package:flutter/material.dart';
import '../tema.dart';

/// Lo que llega al tocar una notificación de Pánico o Rondas — a
/// diferencia de Foto/clip, acá no hace falta pedirle nada al backend:
/// el título y el cuerpo ya vienen completos en el push (ver
/// _difundir_a_vecinos en el bot), así que esta pantalla solo los
/// muestra.
class PantallaVerAlerta extends StatelessWidget {
  final String tipo; // 'panico' | 'ronda'
  final String titulo;
  final String cuerpo;

  const PantallaVerAlerta({
    super.key,
    required this.tipo,
    required this.titulo,
    required this.cuerpo,
  });

  bool get _esPanico => tipo == 'panico';

  @override
  Widget build(BuildContext context) {
    final color = _esPanico ? AlertBotColores.rojoPanico : AlertBotColores.verdePrincipal;
    final colorClaro = _esPanico ? AlertBotColores.rojoPanicoClaro : AlertBotColores.verdeClaro;
    final icono = _esPanico ? Icons.sos_rounded : Icons.directions_walk_rounded;

    return Scaffold(
      appBar: AppBar(title: Text(_esPanico ? 'Alerta del barrio' : 'Aviso de ronda')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: colorClaro, shape: BoxShape.circle),
                child: Icon(icono, color: color, size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                titulo,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AlertBotColores.verdeOscuro),
              ),
              const SizedBox(height: 12),
              Text(
                cuerpo,
                style: const TextStyle(fontSize: 16, color: AlertBotColores.textoSuave, height: 1.4),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radioTarjeta), boxShadow: sombraTarjeta()),
                child: const Text(
                  'Este aviso llegó por notificación — no hace falta que hagas nada más acá.',
                  style: TextStyle(color: AlertBotColores.textoSuave, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
