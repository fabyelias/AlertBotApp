import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../api.dart';
import '../sesion.dart';
import '../tema.dart';

const _extensionesVideo = {'mp4', 'mov', '3gp', '3gpp'};

class PantallaFoto extends StatefulWidget {
  const PantallaFoto({super.key});

  @override
  State<PantallaFoto> createState() => _PantallaFotoState();
}

class _PantallaFotoState extends State<PantallaFoto> {
  final _picker = ImagePicker();
  XFile? _archivo;
  bool _enviando = false;

  bool get _esVideo {
    final ext = _archivo?.name.toLowerCase().split('.').last;
    return _extensionesVideo.contains(ext);
  }

  void _mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _elegir(Future<XFile?> Function() accion) async {
    try {
      final archivo = await accion();
      if (archivo == null || !mounted) return;
      setState(() => _archivo = archivo);
    } catch (_) {
      _mostrarMensaje('No pudimos acceder a la cámara o la galería.');
    }
  }

  String _tipoMime(String nombre, bool esVideo) {
    final ext = nombre.toLowerCase().split('.').last;
    if (esVideo) {
      if (ext == 'mov') return 'video/quicktime';
      if (ext == '3gp' || ext == '3gpp') return 'video/3gpp';
      return 'video/mp4';
    }
    if (ext == 'png') return 'image/png';
    if (ext == 'webp') return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _enviar() async {
    if (_archivo == null || _enviando) return;
    setState(() => _enviando = true);
    try {
      final id = await Sesion.leerIdVecino();
      if (id == null) throw const ErrorApi(0, 'No encontramos tu registro en este celular.');
      final bytes = await _archivo!.readAsBytes();
      await AlertBotApi.enviarFoto(
        idVecino: id,
        bytes: bytes,
        nombreArchivo: _archivo!.name,
        tipoMime: _tipoMime(_archivo!.name, _esVideo),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Recibido! Ya se lo compartí a los vecinos, gracias por avisar 🙌')),
      );
    } on ErrorApi catch (e) {
      _mostrarMensaje(e.codigo == 413
          ? 'El archivo es demasiado grande (máximo 20MB).'
          : 'No pudimos enviarlo. Probá de nuevo.');
    } catch (_) {
      _mostrarMensaje('No pudimos enviarlo. Revisá tu conexión.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Foto / clip')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _archivo == null ? _selector() : _previsualizacion(),
        ),
      ),
    );
  }

  Widget _selector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Mandá una foto o un video corto',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AlertBotColores.verdeOscuro),
        ),
        const SizedBox(height: 4),
        const Text(
          'Apenas lo mandes, se lo compartimos a los vecinos cerca tuyo — mismo destino que si se lo mandaras al bot por Telegram.',
          style: TextStyle(color: AlertBotColores.textoSuave),
        ),
        const SizedBox(height: 28),
        ElevatedButton.icon(
          onPressed: () => _elegir(() => _picker.pickImage(source: ImageSource.camera, imageQuality: 85)),
          icon: const Icon(Icons.photo_camera_rounded),
          label: const Text('Sacar foto'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _elegir(() => _picker.pickVideo(source: ImageSource.camera, maxDuration: const Duration(seconds: 30))),
          icon: const Icon(Icons.videocam_rounded),
          label: const Text('Grabar video corto'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _elegir(() => _picker.pickMedia(imageQuality: 85)),
          icon: const Icon(Icons.photo_library_rounded),
          label: const Text('Elegir de la galería'),
        ),
      ],
    );
  }

  Widget _previsualizacion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radioTarjeta), boxShadow: sombraTarjeta()),
            clipBehavior: Clip.antiAlias,
            child: _esVideo
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.videocam_rounded, size: 56, color: AlertBotColores.verdePrincipal),
                        const SizedBox(height: 8),
                        Text(_archivo!.name, textAlign: TextAlign.center, style: const TextStyle(color: AlertBotColores.textoSuave)),
                      ],
                    ),
                  )
                : Image.file(File(_archivo!.path), fit: BoxFit.contain, width: double.infinity),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _enviando ? null : () => setState(() => _archivo = null),
                child: const Text('Elegir otro'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _enviando ? null : _enviar,
                child: _enviando
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Enviar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
