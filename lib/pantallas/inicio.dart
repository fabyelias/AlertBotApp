import 'package:flutter/material.dart';
import '../tema.dart';
import 'comando_voz.dart';

class PantallaInicio extends StatelessWidget {
  const PantallaInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AlertBot'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              _BotonPanico(onTap: () => _mostrarCategorias(context)),
              const SizedBox(height: 28),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.15,
                  children: [
                    _TarjetaAccion(icono: Icons.photo_camera_rounded, titulo: 'Foto / clip', onTap: () {}),
                    _TarjetaAccion(icono: Icons.directions_walk_rounded, titulo: 'Rondas', onTap: () {}),
                    _TarjetaAccion(
                      icono: Icons.record_voice_over_rounded,
                      titulo: 'Comando de voz',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PantallaComandoVoz()),
                      ),
                    ),
                    _TarjetaAccion(icono: Icons.local_phone_rounded, titulo: 'Emergencias', onTap: () {}),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarCategorias(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('¿Qué está pasando?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AlertBotColores.verdeOscuro)),
              const SizedBox(height: 16),
              _opcionCategoria(context, '🚨 Robo en curso'),
              _opcionCategoria(context, '👀 Algo sospechoso'),
              _opcionCategoria(context, '🚑 Emergencia médica'),
              _opcionCategoria(context, '❗ Otro'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _opcionCategoria(BuildContext context, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OutlinedButton(
        onPressed: () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.centerLeft,
        ),
        child: Text(texto),
      ),
    );
  }
}

class _BotonPanico extends StatelessWidget {
  final VoidCallback onTap;
  const _BotonPanico({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 190,
        height: 190,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AlertBotColores.rojoPanico,
          boxShadow: [
            BoxShadow(color: AlertBotColores.rojoPanico.withOpacity(0.35), blurRadius: 30, spreadRadius: 4),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sos_rounded, color: Colors.white, size: 56),
            SizedBox(height: 8),
            Text('PÁNICO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}

class _TarjetaAccion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final VoidCallback onTap;

  const _TarjetaAccion({required this.icono, required this.titulo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(color: AlertBotColores.verdeClaro, shape: BoxShape.circle),
                child: Icon(icono, color: AlertBotColores.verdePrincipal, size: 28),
              ),
              const SizedBox(height: 10),
              Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
