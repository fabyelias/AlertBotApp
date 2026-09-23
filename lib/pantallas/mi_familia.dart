import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../api.dart';
import '../sesion.dart';
import '../tema.dart';

class PantallaMiFamilia extends StatefulWidget {
  const PantallaMiFamilia({super.key});

  @override
  State<PantallaMiFamilia> createState() => _PantallaMiFamiliaState();
}

class _PantallaMiFamiliaState extends State<PantallaMiFamilia> {
  bool _cargando = true;
  bool _invitando = false;
  String? _error;
  InfoFamilia? _info;
  String? _idVecino;

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
      _idVecino = id;
      final info = await AlertBotApi.consultarFamilia(id);
      if (!mounted) return;
      setState(() => _info = info);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'No pudimos cargar tu familia. Revisá tu conexión e intentá de nuevo.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _invitar() async {
    if (_idVecino == null || _invitando) return;
    setState(() => _invitando = true);
    try {
      final link = await AlertBotApi.generarInvitacionFamilia(_idVecino!);
      await SharePlus.instance.share(ShareParams(
        text: 'Te invito a sumarte a mi familia en AlertBot — es de un solo uso: $link',
        subject: 'Invitación a AlertBot',
      ));
    } on ErrorApi catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.codigo == 409 ? 'Ya llegaste al máximo de integrantes.' : 'No pudimos generar la invitación.'),
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No pudimos generar la invitación. Revisá tu conexión.')));
    } finally {
      if (mounted) setState(() => _invitando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi familia')),
      body: SafeArea(child: _cuerpo()),
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

    final info = _info!;
    if (!info.esTitular) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Tu familia la gestiona el titular de tu grupo — un integrante comparte la dirección, no la puede tocar.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AlertBotColores.textoSuave),
          ),
        ),
      );
    }

    final cupoLleno = info.cupoUsado >= info.cupoMaximo;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Tu familia (${info.cupoUsado}/${info.cupoMaximo})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AlertBotColores.verdeOscuro),
        ),
        const SizedBox(height: 16),
        if (info.integrantes.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radioTarjeta), boxShadow: sombraTarjeta()),
            child: const Text('Todavía no sumaste a nadie.', style: TextStyle(color: AlertBotColores.textoSuave)),
          )
        else
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radioTarjeta), boxShadow: sombraTarjeta()),
            child: Column(
              children: [
                for (final i in info.integrantes)
                  ListTile(
                    leading: const Icon(Icons.person_rounded, color: AlertBotColores.verdePrincipal),
                    title: Text('${i.nombre} ${i.apellido}'),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        if (cupoLleno)
          const Text('Ya llegaste al máximo de integrantes.', textAlign: TextAlign.center, style: TextStyle(color: AlertBotColores.textoSuave))
        else
          ElevatedButton.icon(
            onPressed: _invitando ? null : _invitar,
            icon: _invitando
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.person_add_rounded),
            label: Text(_invitando ? 'Generando link...' : 'Invitar integrante'),
          ),
      ],
    );
  }
}
