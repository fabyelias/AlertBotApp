import 'package:flutter/material.dart';
import '../api.dart';
import '../sesion.dart';
import '../tema.dart';

/// Novedades prearmadas para el cierre de ronda — mismas opciones que
/// NOVEDAD_PRESETS en keyboards.py del bot, para que alcance con un toque
/// en el caso más común.
const _novedadesPreset = {
  'sospechoso': '👀 Vi a alguien sospechoso',
  'vehiculo': '🚗 Vehículo desconocido estacionado',
  'perro': '🐕 Perro suelto',
};

class PantallaRondas extends StatefulWidget {
  const PantallaRondas({super.key});

  @override
  State<PantallaRondas> createState() => _PantallaRondasState();
}

class _PantallaRondasState extends State<PantallaRondas> {
  bool _cargando = true;
  bool _procesando = false;
  String? _error;
  EstadoRondas? _estado;
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
      final estado = await AlertBotApi.consultarRondas(id);
      if (!mounted) return;
      setState(() => _estado = estado);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'No pudimos cargar las rondas. Revisá tu conexión e intentá de nuevo.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _iniciarRonda() async {
    if (_idVecino == null || _procesando) return;
    setState(() => _procesando = true);
    try {
      await AlertBotApi.iniciarRonda(_idVecino!);
      _mostrarMensaje('Listo, quedaste marcado como en ronda 🚶 Gracias por cuidar el barrio.');
      await _cargar();
    } on ErrorApi catch (e) {
      _mostrarMensaje(e.codigo == 409 ? 'Ya tenés una ronda activa.' : 'No pudimos iniciar tu ronda. Probá de nuevo.');
    } catch (_) {
      _mostrarMensaje('No pudimos iniciar tu ronda. Revisá tu conexión.');
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _abrirCierreDeRonda() async {
    final novedad = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _HojaCierreRonda(),
    );
    if (novedad == null) return; // canceló la hoja sin elegir nada
    await _finalizarRonda(novedad.isEmpty ? null : novedad);
  }

  Future<void> _finalizarRonda(String? novedad) async {
    if (_idVecino == null || _procesando) return;
    setState(() => _procesando = true);
    try {
      await AlertBotApi.finalizarRonda(_idVecino!, novedad: novedad);
      _mostrarMensaje(novedad == null || novedad.isEmpty
          ? 'Perfecto, marqué el fin de tu ronda sin novedades. ¡Gracias por el aguante! 🙏'
          : 'Listo, quedó anotado: "$novedad". Cerré tu ronda. ¡Gracias por el aguante! 🙏');
      await _cargar();
    } on ErrorApi catch (e) {
      _mostrarMensaje(e.codigo == 409 ? 'No tenías ninguna ronda activa.' : 'No pudimos cerrar tu ronda. Probá de nuevo.');
    } catch (_) {
      _mostrarMensaje('No pudimos cerrar tu ronda. Revisá tu conexión.');
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rondas'),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _cargando ? null : _cargar)],
      ),
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

    final estado = _estado!;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radioTarjeta), boxShadow: sombraTarjeta()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: AlertBotColores.verdeClaro, shape: BoxShape.circle),
                    child: const Icon(Icons.directions_walk_rounded, color: AlertBotColores.verdePrincipal),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      estado.activa ? 'Estás haciendo una ronda ahora' : 'No estás haciendo ronda',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: estado.activa
                    ? FilledButton.icon(
                        onPressed: _procesando ? null : _abrirCierreDeRonda,
                        style: FilledButton.styleFrom(backgroundColor: AlertBotColores.rojoPanico),
                        icon: const Icon(Icons.flag_rounded),
                        label: const Text('Terminar mi ronda'),
                      )
                    : ElevatedButton.icon(
                        onPressed: _procesando ? null : _iniciarRonda,
                        icon: const Icon(Icons.directions_walk_rounded),
                        label: const Text('Iniciar ronda'),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Vecinos haciendo ronda ahora',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AlertBotColores.verdeOscuro),
        ),
        const SizedBox(height: 12),
        if (estado.activas.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radioTarjeta), boxShadow: sombraTarjeta()),
            child: const Text('Ahora mismo no hay ningún vecino haciendo ronda.', style: TextStyle(color: AlertBotColores.textoSuave)),
          )
        else
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radioTarjeta), boxShadow: sombraTarjeta()),
            child: Column(
              children: [
                for (final v in estado.activas)
                  ListTile(
                    leading: const Icon(Icons.directions_walk_rounded, color: AlertBotColores.verdePrincipal),
                    title: Text('${v.nombre} ${v.apellido}'),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _HojaCierreRonda extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // isScrollControlled (en showModalBottomSheet) más este SingleChildScrollView:
    // sin esto, la hoja se recorta a una altura fija y, con varias opciones,
    // el contenido no entra y desborda por abajo (se veía "BOTTOM OVERFLOWED").
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '¿Alguna novedad antes de cerrar la ronda?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AlertBotColores.verdeOscuro),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tocá la opción que más se parezca a lo que pasó, o "Sin novedades" si todo estuvo tranquilo.',
                style: TextStyle(color: AlertBotColores.textoSuave, fontSize: 13),
              ),
              const SizedBox(height: 16),
              _opcion(context, '✅ Sin novedades', ''),
              for (final entrada in _novedadesPreset.entries) _opcion(context, entrada.value, entrada.value),
              _opcionEscribir(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _opcion(BuildContext context, String texto, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OutlinedButton(
        onPressed: () => Navigator.pop(context, valor),
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
              title: const Text('Contanos qué novedad hay'),
              content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(hintText: 'Tu novedad...')),
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
      child: const Text('✍️ Escribir otra cosa'),
    );
  }
}
