import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../tema.dart';
import '../api.dart';
import '../sesion.dart';
import 'esperando_aprobacion.dart';

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();

  Position? _ubicacion;
  bool _cargandoUbicacion = false;
  bool _enviando = false;

  Future<void> _obtenerUbicacion() async {
    setState(() => _cargandoUbicacion = true);
    try {
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.deniedForever || permiso == LocationPermission.denied) {
        _mostrarError('Necesitamos tu ubicación para avisarle a los vecinos más cercanos cuando actives una alerta.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() => _ubicacion = pos);
    } catch (_) {
      _mostrarError('No pudimos obtener tu ubicación. Probá de nuevo.');
    } finally {
      setState(() => _cargandoUbicacion = false);
    }
  }

  void _mostrarError(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  /// Pide permiso de notificaciones y devuelve el token de FCM del
  /// celular. Si el vecino lo rechaza o falla, se registra igual sin
  /// token — el panico y el registro no dependen de esto, solo se
  /// pierde el aviso por notificación push (le siguen llegando las
  /// alertas si abre la app).
  Future<String?> _tokenPush() async {
    try {
      final permiso = await FirebaseMessaging.instance.requestPermission();
      if (permiso.authorizationStatus == AuthorizationStatus.denied) return null;
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> _enviarRegistro() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ubicacion == null) {
      _mostrarError('Compartí tu ubicación antes de continuar.');
      return;
    }
    setState(() => _enviando = true);
    try {
      final tokenPush = await _tokenPush();
      final idVecino = await AlertBotApi.registrarVecino(
        nombre: _nombreCtrl.text.trim(),
        apellido: _apellidoCtrl.text.trim(),
        direccion: _direccionCtrl.text.trim(),
        lat: _ubicacion!.latitude,
        lon: _ubicacion!.longitude,
        tokenPush: tokenPush,
      );
      await Sesion.guardarIdVecino(idVecino);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PantallaEsperandoAprobacion()),
      );
    } catch (_) {
      _mostrarError('No pudimos enviar tu solicitud. Revisá tu conexión e intentá de nuevo.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de vecino')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Contanos quién sos',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AlertBotColores.verdeOscuro),
                ),
                const SizedBox(height: 4),
                const Text(
                  'El administrador del barrio va a revisar tu solicitud antes de aprobarte.',
                  style: TextStyle(color: AlertBotColores.textoSuave),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _apellidoCtrl,
                  decoration: const InputDecoration(labelText: 'Apellido'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _direccionCtrl,
                  decoration: const InputDecoration(labelText: 'Dirección (calle y número)'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: _cargandoUbicacion ? null : _obtenerUbicacion,
                  icon: Icon(_ubicacion == null ? Icons.my_location : Icons.check_circle, color: AlertBotColores.verdePrincipal),
                  label: Text(_cargandoUbicacion
                      ? 'Buscando ubicación...'
                      : _ubicacion == null
                          ? 'Compartir mi ubicación'
                          : 'Ubicación lista ✓'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AlertBotColores.verdePrincipal),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _enviando ? null : _enviarRegistro,
                  child: _enviando
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Enviar solicitud'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
