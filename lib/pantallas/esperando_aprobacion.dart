import 'dart:async';
import 'package:flutter/material.dart';
import '../api.dart';
import '../sesion.dart';
import '../tema.dart';
import '../bienvenida.dart';
import 'inicio.dart';

/// Se muestra mientras el admin todavía no aprobó ni rechazó al vecino.
/// Consulta /api/estado cada pocos segundos y avanza sola apenas cambia
/// (sin que el vecino tenga que hacer nada ni reabrir la app).
class PantallaEsperandoAprobacion extends StatefulWidget {
  const PantallaEsperandoAprobacion({super.key});

  @override
  State<PantallaEsperandoAprobacion> createState() => _PantallaEsperandoAprobacionState();
}

class _PantallaEsperandoAprobacionState extends State<PantallaEsperandoAprobacion> {
  static const _intervaloConsulta = Duration(seconds: 5);

  Timer? _timer;
  bool _consultando = false;
  String? _rechazo; // null = sigue pendiente; con texto = ya no hay nada que esperar

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_intervaloConsulta, (_) => _consultar());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _consultar() async {
    if (_consultando) return; // no solapar consultas si una tarda más que el intervalo
    _consultando = true;
    try {
      final id = await Sesion.leerIdVecino();
      if (id == null) return; // no debería pasar; si pasa, simplemente no hay nada que consultar

      final estado = await AlertBotApi.consultarEstado(id);
      if (!mounted) return;
      if (estado == 'aprobado') {
        _timer?.cancel();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PantallaInicio()),
        );
      } else if (estado == 'rechazado') {
        _timer?.cancel();
        setState(() => _rechazo =
            'Tu solicitud no fue aprobada. Si creés que fue un error, contactate con la organización del barrio.');
      } else if (estado == 'baja' || estado == 'desconocido') {
        _timer?.cancel();
        setState(() => _rechazo = 'Tu solicitud ya no está disponible. Tenés que registrarte de nuevo.');
      }
      // si sigue 'pendiente', no hay nada que hacer todavía
    } catch (_) {
      // fallo de red puntual: no interrumpe el polling, se reintenta solo
    } finally {
      _consultando = false;
    }
  }

  Future<void> _empezarDeNuevo() async {
    await Sesion.borrar();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PantallaBienvenida()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _rechazo == null ? _vistaEspera() : _vistaRechazo(_rechazo!),
          ),
        ),
      ),
    );
  }

  List<Widget> _vistaEspera() => [
        Container(
          width: 104,
          height: 104,
          decoration: const BoxDecoration(color: AlertBotColores.verdeClaro, shape: BoxShape.circle),
          child: const Icon(Icons.hourglass_top_rounded, size: 48, color: AlertBotColores.verdePrincipal),
        ),
        const SizedBox(height: 24),
        const Text(
          '¡Listo! Tu solicitud está en revisión',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AlertBotColores.verdeOscuro),
        ),
        const SizedBox(height: 12),
        const Text(
          'El administrador del barrio ya la recibió. En cuanto te apruebe, '
          'esta pantalla avanza sola.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: AlertBotColores.textoSuave, height: 1.4),
        ),
      ];

  List<Widget> _vistaRechazo(String mensaje) => [
        const Icon(Icons.info_outline_rounded, size: 72, color: AlertBotColores.textoSuave),
        const SizedBox(height: 24),
        Text(
          mensaje,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: AlertBotColores.textoSuave, height: 1.4),
        ),
        const SizedBox(height: 28),
        ElevatedButton(onPressed: _empezarDeNuevo, child: const Text('Volver al inicio')),
      ];
}
