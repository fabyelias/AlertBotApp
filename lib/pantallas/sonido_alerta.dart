import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../api.dart';
import '../notificaciones_locales.dart';
import '../sesion.dart';
import '../sonido_alerta.dart';
import '../tema.dart';

/// Elegir con qué sonido avisa AlertBot — a diferencia de una
/// notificación cualquiera, acá hay sirenas tipo patrullero, para que
/// una alerta real se distinga de un mensaje común incluso sin mirar
/// el celular.
class PantallaSonidoAlerta extends StatefulWidget {
  const PantallaSonidoAlerta({super.key});

  @override
  State<PantallaSonidoAlerta> createState() => _PantallaSonidoAlertaState();
}

class _PantallaSonidoAlertaState extends State<PantallaSonidoAlerta> {
  String? _elegido;
  bool _cargando = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final elegido = await PreferenciaSonido.leer();
    if (mounted) setState(() { _elegido = elegido; _cargando = false; });
  }

  Future<void> _previsualizar(SonidoAlerta sonido) async {
    await mostrarNotificacionLocal(
      titulo: '🔔 ${sonido.nombre}',
      cuerpo: 'Así vas a escuchar las alertas del barrio.',
      canal: sonido.canal,
    );
  }

  Future<void> _elegir(SonidoAlerta sonido) async {
    if (_guardando) return;
    setState(() => _guardando = true);
    try {
      await PreferenciaSonido.guardar(sonido.canal);
      if (mounted) setState(() => _elegido = sonido.canal);
      await _previsualizar(sonido);
      await _sincronizarConBackend(sonido.canal);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  /// Mejor esfuerzo: si falla (sin conexión), no pasa nada — arranque.dart
  /// manda siempre la preferencia guardada en la próxima apertura.
  Future<void> _sincronizarConBackend(String? canalSonido) async {
    try {
      final id = await Sesion.leerIdVecino();
      if (id == null) return;
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await AlertBotApi.actualizarTokenPush(idVecino: id, tokenPush: token, canalSonido: canalSonido);
    } catch (_) {
      // sin conexión puntual: no pasa nada, se reintenta en la próxima apertura
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlertBotColores.fondo,
      appBar: AppBar(title: const Text('Sonido de alertas')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Elegí con qué sonido te avisa AlertBot cuando llega una alerta del barrio — '
                  'con sirena, para que se note que es algo urgente y no una notificación más.',
                  style: TextStyle(color: AlertBotColores.textoSuave, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 20),
                for (final sonido in sonidosDisponibles) ...[
                  _TarjetaSonido(
                    sonido: sonido,
                    elegido: sonido.canal == _elegido,
                    onElegir: () => _elegir(sonido),
                    onEscuchar: () => _previsualizar(sonido),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}

class _TarjetaSonido extends StatelessWidget {
  final SonidoAlerta sonido;
  final bool elegido;
  final VoidCallback onElegir;
  final VoidCallback onEscuchar;

  const _TarjetaSonido({
    required this.sonido,
    required this.elegido,
    required this.onElegir,
    required this.onEscuchar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radioTarjeta),
        boxShadow: sombraTarjeta(),
        border: elegido ? Border.all(color: AlertBotColores.verdePrincipal, width: 1.5) : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radioTarjeta),
        child: InkWell(
          borderRadius: BorderRadius.circular(radioTarjeta),
          onTap: onElegir,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  elegido ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: elegido ? AlertBotColores.verdePrincipal : AlertBotColores.borde,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sonido.nombre, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(sonido.descripcion, style: const TextStyle(color: AlertBotColores.textoSuave, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onEscuchar,
                  icon: const Icon(Icons.volume_up_rounded, color: AlertBotColores.verdePrincipal),
                  tooltip: 'Escuchar',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
