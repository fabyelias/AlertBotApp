import 'package:flutter/material.dart';
import '../api.dart';
import '../sesion.dart';
import '../tema.dart';
import 'comando_voz.dart';

/// Categorías de pánico: la clave es la que entiende el backend
/// (ver CATEGORIAS_PANICO en config.py del bot), el texto es lo que ve
/// el vecino.
const _categoriasPanico = {
  'robo': '🚨 Robo en curso',
  'sospechoso': '👀 Persona sospechosa',
  'medica': '🏥 Emergencia médica',
  'otro': '❗ Otro',
};

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  bool _activando = false;

  Future<void> _mostrarCategorias() async {
    if (_activando) return; // ya hay una alerta en curso, no abrir otra

    final clave = await showModalBottomSheet<String>(
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
              for (final entrada in _categoriasPanico.entries) _opcionCategoria(entrada.key, entrada.value),
            ],
          ),
        ),
      ),
    );

    if (clave != null && mounted) await _confirmarYActivar(clave, _categoriasPanico[clave]!);
  }

  Widget _opcionCategoria(String clave, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OutlinedButton(
        onPressed: () => Navigator.pop(context, clave),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.centerLeft,
        ),
        child: Text(texto),
      ),
    );
  }

  Future<void> _confirmarYActivar(String clave, String texto) async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Categoría elegida: $texto'),
        content: const Text(
          '¿Confirmás la alerta? En cuanto confirmes le avisamos a todos los vecinos de inmediato.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirma != true || !mounted) return;

    setState(() => _activando = true);
    try {
      final id = await Sesion.leerIdVecino();
      if (id == null) throw const ErrorApi(0, 'No encontramos tu registro en este celular.');
      await AlertBotApi.activarPanico(idVecino: id, categoria: clave);
      if (!mounted) return;
      _mostrarMensaje('Listo, tu alerta ya llegó a los vecinos. Quedate tranquilo 🙏', esError: false);
    } catch (_) {
      if (!mounted) return;
      _mostrarMensaje('No pudimos enviar la alerta. Revisá tu conexión e intentá de nuevo.', esError: true);
    } finally {
      if (mounted) setState(() => _activando = false);
    }
  }

  void _mostrarMensaje(String texto, {required bool esError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(texto),
      backgroundColor: esError ? AlertBotColores.rojoPanico : AlertBotColores.verdePrincipal,
      duration: const Duration(seconds: 4),
    ));
  }

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
              _BotonPanico(activando: _activando, onTap: _mostrarCategorias),
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
}

class _BotonPanico extends StatelessWidget {
  final bool activando;
  final VoidCallback onTap;
  const _BotonPanico({required this.activando, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: activando ? null : onTap,
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
        child: activando
            ? const Center(
                child: SizedBox(
                  height: 40, width: 40,
                  child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                ),
              )
            : const Column(
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
