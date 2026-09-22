import 'package:flutter/material.dart';
import '../api.dart';
import '../sesion.dart';
import '../tema.dart';
import '../bienvenida.dart';
import 'esperando_aprobacion.dart';
import 'inicio.dart';

/// Primera pantalla que se ve al abrir la app. Decide a dónde ir según si
/// ya hay una solicitud guardada en este celular y, si la hay, en qué
/// estado quedó — así un vecino que ya se registró no tiene que repetir
/// el formulario cada vez que abre la app.
class PantallaArranque extends StatefulWidget {
  const PantallaArranque({super.key});

  @override
  State<PantallaArranque> createState() => _PantallaArranqueState();
}

class _PantallaArranqueState extends State<PantallaArranque> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _decidirDestino();
  }

  Future<void> _decidirDestino() async {
    setState(() => _error = null);

    final id = await Sesion.leerIdVecino();
    if (id == null) {
      _ir(const PantallaBienvenida());
      return;
    }

    try {
      final estado = await AlertBotApi.consultarEstado(id);
      if (estado == 'aprobado') {
        _ir(const PantallaInicio());
      } else if (estado == 'pendiente') {
        _ir(const PantallaEsperandoAprobacion());
      } else {
        // rechazado, baja, o el token ya no existe en el servidor: no hay
        // nada que hacer con esta solicitud, hay que empezar de nuevo.
        await Sesion.borrar();
        _ir(const PantallaBienvenida());
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'No pudimos conectar con el servidor.');
    }
  }

  void _ir(Widget pantalla) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => pantalla));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: _error == null
              ? const CircularProgressIndicator(color: AlertBotColores.verdePrincipal)
              : Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 48, color: AlertBotColores.textoSuave),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      ElevatedButton(onPressed: _decidirDestino, child: const Text('Reintentar')),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
