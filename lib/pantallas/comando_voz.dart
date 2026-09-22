import 'package:flutter/material.dart';
import '../comando_voz_servicio.dart';
import '../tema.dart';

class PantallaComandoVoz extends StatefulWidget {
  const PantallaComandoVoz({super.key});

  @override
  State<PantallaComandoVoz> createState() => _PantallaComandoVozState();
}

class _PantallaComandoVozState extends State<PantallaComandoVoz> {
  static const _frases = [
    ('🆘', 'activa caída'),
    ('🚨', 'activa robo'),
    ('🚑', 'activa emergencia médica'),
    ('🔥', 'activa incendio'),
  ];

  final _servicio = ComandoVozServicio.instancia;
  bool _cambiando = false;

  Future<void> _alCambiarInterruptor(bool activar) async {
    setState(() => _cambiando = true);
    if (activar) {
      await _servicio.activar();
    } else {
      await _servicio.desactivar();
    }
    if (mounted) setState(() => _cambiando = false);
  }

  String _textoEstado(EstadoComandoVoz? estado) {
    switch (estado) {
      case EstadoComandoVoz.escuchando:
        return 'Escuchando con el teléfono bloqueado ✅';
      case EstadoComandoVoz.sinPermisoMicrofono:
        return 'Falta el permiso de micrófono. Activalo desde Ajustes del sistema.';
      case EstadoComandoVoz.sinConfigurar:
        return 'Todavía no está configurado en este build (falta el AccessKey de Picovoice).';
      case EstadoComandoVoz.error:
        return 'No se pudo iniciar la escucha. Probá de nuevo.';
      case EstadoComandoVoz.alertaEnviada:
        return 'Alerta enviada por voz. Seguimos escuchando.';
      case EstadoComandoVoz.errorAlEnviar:
        return 'Se detectó el comando pero no se pudo avisar a los vecinos. Revisá tu conexión.';
      case EstadoComandoVoz.inactivo:
      case null:
        return 'Escucha desactivada.';
    }
  }

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
            const SizedBox(height: 28),
            StreamBuilder<EstadoComandoVoz>(
              stream: _servicio.estado,
              builder: (context, snap) {
                final activo = _servicio.activo;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AlertBotColores.verdeClaro,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('Escucha con pantalla bloqueada',
                                style: const TextStyle(fontWeight: FontWeight.w600, color: AlertBotColores.verdeOscuro)),
                          ),
                          _cambiando
                              ? const SizedBox(
                                  width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                              : Switch(
                                  value: activo,
                                  onChanged: _servicio.configurado ? _alCambiarInterruptor : null,
                                ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(_textoEstado(snap.data), style: const TextStyle(color: AlertBotColores.textoSuave)),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
