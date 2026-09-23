import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../api.dart';
import '../sesion.dart';
import '../tema.dart';

class PantallaMiDireccion extends StatefulWidget {
  final String direccionActual;
  const PantallaMiDireccion({super.key, required this.direccionActual});

  @override
  State<PantallaMiDireccion> createState() => _PantallaMiDireccionState();
}

class _PantallaMiDireccionState extends State<PantallaMiDireccion> {
  late final TextEditingController _direccionCtrl = TextEditingController(text: widget.direccionActual);
  Position? _ubicacion;
  bool _cargandoUbicacion = false;
  bool _guardando = false;

  Future<void> _obtenerUbicacion() async {
    setState(() => _cargandoUbicacion = true);
    try {
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.deniedForever || permiso == LocationPermission.denied) {
        _mostrarMensaje('Necesitamos tu ubicación para actualizar tu dirección en el mapa del barrio.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() => _ubicacion = pos);
    } catch (_) {
      _mostrarMensaje('No pudimos obtener tu ubicación. Probá de nuevo.');
    } finally {
      if (mounted) setState(() => _cargandoUbicacion = false);
    }
  }

  void _mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _guardar() async {
    final direccion = _direccionCtrl.text.trim();
    if (direccion.isEmpty) {
      _mostrarMensaje('Escribí tu dirección.');
      return;
    }
    if (_ubicacion == null) {
      _mostrarMensaje('Compartí tu nueva ubicación (el pin en el mapa) antes de guardar.');
      return;
    }
    setState(() => _guardando = true);
    try {
      final id = await Sesion.leerIdVecino();
      if (id == null) throw const ErrorApi(0, 'No encontramos tu registro en este celular.');
      final integrantesAfectados = await AlertBotApi.actualizarDireccion(
        idVecino: id,
        direccion: direccion,
        lat: _ubicacion!.latitude,
        lon: _ubicacion!.longitude,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Listo, ya actualicé tu dirección 🙌'
            '${integrantesAfectados > 0 ? " (y la de tu familia)" : ""}'),
      ));
    } on ErrorApi catch (e) {
      _mostrarMensaje(e.codigo == 403
          ? 'Tu dirección la actualiza el titular de tu familia.'
          : 'No pudimos actualizar tu dirección. Probá de nuevo.');
    } catch (_) {
      _mostrarMensaje('No pudimos actualizar tu dirección. Revisá tu conexión.');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi dirección')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '¿Te mudaste?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AlertBotColores.verdeOscuro),
              ),
              const SizedBox(height: 4),
              const Text(
                'Si tenés familia sumada, se les actualiza a todos automáticamente.',
                style: TextStyle(color: AlertBotColores.textoSuave),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _direccionCtrl,
                decoration: const InputDecoration(labelText: 'Nueva dirección (calle, altura y entre calles)'),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _cargandoUbicacion ? null : _obtenerUbicacion,
                icon: Icon(_ubicacion == null ? Icons.my_location : Icons.check_circle, color: AlertBotColores.verdePrincipal),
                label: Text(_cargandoUbicacion
                    ? 'Buscando ubicación...'
                    : _ubicacion == null
                        ? 'Compartir mi nueva ubicación'
                        : 'Ubicación lista ✓'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AlertBotColores.verdePrincipal),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Guardar dirección'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
