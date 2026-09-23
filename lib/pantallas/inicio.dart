import 'package:flutter/material.dart';
import '../api.dart';
import '../sesion.dart';
import '../tema.dart';
import 'emergencias.dart';
import 'mi_direccion.dart';
import 'mi_familia.dart';
import 'rondas.dart';

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
  PerfilVecino? _perfil;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    final id = await Sesion.leerIdVecino();
    if (id == null) return;
    try {
      final perfil = await AlertBotApi.consultarPerfil(id);
      if (mounted) setState(() => _perfil = perfil);
    } catch (_) {
      // sin conexión puntual: el resto de la pantalla igual funciona,
      // solo no se personaliza el saludo ni se sabe si es titular
    }
  }

  Future<void> _mostrarCategorias() async {
    if (_activando) return; // ya hay una alerta en curso, no abrir otra

    final clave = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AlertBotColores.borde, borderRadius: BorderRadius.circular(4)),
              ),
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
      backgroundColor: esError ? AlertBotColores.rojoPanico : null,
      duration: const Duration(seconds: 4),
    ));
  }

  void _mostrarProximamente(String funcion) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$funcion todavía no está lista. ¡Ya la estamos preparando! 🚧'),
    ));
  }

  void _abrirEmergencias() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaEmergencias()));
  }

  void _abrirRondas() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaRondas()));
  }

  void _abrirMiFamilia() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaMiFamilia()));
  }

  Future<void> _abrirMiDireccion() async {
    final actualizada = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PantallaMiDireccion(direccionActual: _perfil?.direccion ?? '')),
    );
    if (actualizada == true) _cargarPerfil();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlertBotColores.fondo,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Encabezado(onTocarNotificacion: () => _mostrarProximamente('Las notificaciones'), nombre: _perfil?.nombre),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  children: [
                    _BotonPanico(activando: _activando, onTap: _mostrarCategorias),
                    const SizedBox(height: 14),
                    Text(
                      _activando ? 'Enviando tu alerta…' : 'Mantené presionado para pedir ayuda de inmediato',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AlertBotColores.textoSuave, fontSize: 13),
                    ),
                    const SizedBox(height: 32),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Acciones rápidas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AlertBotColores.verdeOscuro,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.95,
                      children: [
                        _TarjetaAccion(
                          icono: Icons.directions_walk_rounded,
                          titulo: 'Rondas',
                          subtitulo: 'Iniciar / cerrar',
                          onTap: _abrirRondas,
                        ),
                        _TarjetaAccion(
                          icono: Icons.local_phone_rounded,
                          titulo: 'Emergencias',
                          subtitulo: 'Números útiles',
                          onTap: _abrirEmergencias,
                        ),
                        _TarjetaAccion(
                          icono: Icons.photo_camera_rounded,
                          titulo: 'Foto / clip',
                          subtitulo: 'Próximamente',
                          onTap: () => _mostrarProximamente('Foto / clip'),
                        ),
                        if (_perfil?.esTitular ?? true) ...[
                          _TarjetaAccion(
                            icono: Icons.home_rounded,
                            titulo: 'Mi dirección',
                            subtitulo: 'Actualizarla',
                            onTap: _abrirMiDireccion,
                          ),
                          _TarjetaAccion(
                            icono: Icons.family_restroom_rounded,
                            titulo: 'Mi familia',
                            subtitulo: 'Sumar integrantes',
                            onTap: _abrirMiFamilia,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  final VoidCallback onTocarNotificacion;
  final String? nombre;
  const _Encabezado({required this.onTocarNotificacion, this.nombre});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 28),
      decoration: const BoxDecoration(
        gradient: gradienteAlertBot,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield_rounded, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'AlertBot',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                (nombre != null && nombre!.isNotEmpty) ? 'Hola, $nombre 👋' : 'Tu barrio, cuidado entre todos',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          Material(
            color: Colors.white.withOpacity(0.18),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTocarNotificacion,
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
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
    return Center(
      child: GestureDetector(
        onTap: activando ? null : onTap,
        child: Container(
          width: 214,
          height: 214,
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AlertBotColores.rojoPanicoClaro,
          ),
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
                      height: 40,
                      width: 40,
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
        ),
      ),
    );
  }
}

class _TarjetaAccion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  const _TarjetaAccion({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radioTarjeta),
        boxShadow: sombraTarjeta(),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radioTarjeta),
        child: InkWell(
          borderRadius: BorderRadius.circular(radioTarjeta),
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
                const SizedBox(height: 2),
                Text(
                  subtitulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AlertBotColores.textoSuave, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
