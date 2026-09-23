import 'package:flutter/material.dart';
import '../api.dart';
import '../sesion.dart';
import '../tema.dart';

/// Motivos prearmados de reporte, pensados para que alcance con un toque
/// en el caso más común (contenido obsceno en Rondas/Foto/clip).
const _motivosReporte = [
  '🔞 Contenido obsceno o inapropiado',
  '🚫 No tiene que ver con seguridad del barrio',
  '📛 Spam',
];

class PantallaVerFoto extends StatefulWidget {
  final int alertaId;
  const PantallaVerFoto({super.key, required this.alertaId});

  @override
  State<PantallaVerFoto> createState() => _PantallaVerFotoState();
}

class _PantallaVerFotoState extends State<PantallaVerFoto> {
  bool _cargando = true;
  bool _reportando = false;
  bool _yaReportado = false;
  String? _error;
  ContenidoCompartido? _contenido;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final id = await Sesion.leerIdVecino();
      if (id == null) throw const ErrorApi(0, 'No encontramos tu registro en este celular.');
      final contenido = await AlertBotApi.descargarFoto(idVecino: id, alertaId: widget.alertaId);
      if (!mounted) return;
      setState(() => _contenido = contenido);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'No pudimos cargar el contenido. Puede que ya no esté disponible.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _abrirReporte() async {
    final motivo = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _HojaReporte(),
    );
    if (motivo == null || motivo.isEmpty) return;
    await _enviarReporte(motivo);
  }

  Future<void> _enviarReporte(String motivo) async {
    setState(() => _reportando = true);
    try {
      final id = await Sesion.leerIdVecino();
      if (id == null) throw const ErrorApi(0, 'No encontramos tu registro en este celular.');
      await AlertBotApi.reportarFoto(idVecino: id, alertaId: widget.alertaId, motivo: motivo);
      if (!mounted) return;
      setState(() => _yaReportado = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reportado. Gracias por avisar, el administrador lo va a revisar 🙏')),
      );
    } on ErrorApi catch (e) {
      if (!mounted) return;
      if (e.codigo == 409) {
        setState(() => _yaReportado = true);
        _mostrarMensaje('Ya habías reportado este contenido.');
      } else {
        _mostrarMensaje('No pudimos enviar el reporte. Probá de nuevo.');
      }
    } catch (_) {
      if (!mounted) return;
      _mostrarMensaje('No pudimos enviar el reporte. Revisá tu conexión.');
    } finally {
      if (mounted) setState(() => _reportando = false);
    }
  }

  void _mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compartido por un vecino')),
      body: SafeArea(child: _cuerpo()),
      bottomNavigationBar: _contenido == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton.icon(
                  onPressed: (_reportando || _yaReportado) ? null : _abrirReporte,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AlertBotColores.rojoPanico,
                    side: const BorderSide(color: AlertBotColores.rojoPanico),
                  ),
                  icon: _reportando
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(_yaReportado ? Icons.flag_rounded : Icons.outlined_flag_rounded),
                  label: Text(_yaReportado ? 'Ya reportado' : 'Reportar contenido'),
                ),
              ),
            ),
    );
  }

  Widget _cuerpo() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AlertBotColores.textoSuave)),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: _cargar, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    final contenido = _contenido!;
    if (contenido.esVideo) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_rounded, size: 64, color: AlertBotColores.verdePrincipal),
              const SizedBox(height: 12),
              const Text(
                'Es un video. Todavía no podemos reproducirlo acá dentro,\npero ya lo podés reportar si hace falta.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AlertBotColores.textoSuave),
              ),
            ],
          ),
        ),
      );
    }

    return InteractiveViewer(
      child: Center(child: Image.memory(contenido.bytes, fit: BoxFit.contain)),
    );
  }
}

class _HojaReporte extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '¿Por qué lo reportás?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AlertBotColores.verdeOscuro),
            ),
            const SizedBox(height: 4),
            const Text(
              'Se lo mandamos al administrador para que lo revise.',
              style: TextStyle(color: AlertBotColores.textoSuave, fontSize: 13),
            ),
            const SizedBox(height: 16),
            for (final motivo in _motivosReporte) _opcion(context, motivo),
            _opcionEscribir(context),
          ],
        ),
      ),
    );
  }

  Widget _opcion(BuildContext context, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OutlinedButton(
        onPressed: () => Navigator.pop(context, texto),
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), alignment: Alignment.centerLeft),
        child: Text(texto),
      ),
    );
  }

  Widget _opcionEscribir(BuildContext context) {
    return OutlinedButton(
      onPressed: () async {
        final texto = await showDialog<String>(
          context: context,
          builder: (context) {
            final ctrl = TextEditingController();
            return AlertDialog(
              title: const Text('Contanos el motivo'),
              content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(hintText: 'Motivo del reporte...')),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('Listo')),
              ],
            );
          },
        );
        if (texto != null && texto.isNotEmpty && context.mounted) Navigator.pop(context, texto);
      },
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), alignment: Alignment.centerLeft),
      child: const Text('✍️ Otro motivo'),
    );
  }
}
