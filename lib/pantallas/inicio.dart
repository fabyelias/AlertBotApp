import 'package:flutter/material.dart';
import '../api.dart';
import '../sesion.dart';
import '../tema.dart';
import '../notificaciones.dart';
import 'emergencias.dart';
import 'foto.dart';
import 'mi_direccion.dart';
import 'mi_familia.dart';
import 'notificaciones.dart';
import 'rondas.dart';
import 'ver_alerta.dart';
import 'ver_foto.dart';

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

class _PantallaInicioState extends State<PantallaInicio> with WidgetsBindingObserver {
  bool _activando = false;
  PerfilVecino? _perfil;
  NotificacionGuardada? _alertaPendiente;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargarPerfil();
    _cargarAlertaPendiente();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Volvió del segundo plano (task switcher, desbloqueó el celular):
    // por si llegó una alerta mientras tanto, sin que abriera la app de
    // nuevo desde cero (eso ya lo cubre initState).
    if (state == AppLifecycleState.resumed) _cargarAlertaPendiente();
  }

  Future<void> _cargarAlertaPendiente() async {
    final alerta = await Notificaciones.pendiente();
    if (mounted) setState(() => _alertaPendiente = alerta);
  }

  Future<void> _descartarAlertaPendiente() async {
    final alerta = _alertaPendiente;
    if (alerta == null) return;
    await Notificaciones.marcarVista(alerta);
    if (mounted) setState(() => _alertaPendiente = null);
  }

  Future<void> _abrirAlertaPendiente() async {
    final alerta = _alertaPendiente;
    if (alerta == null) return;
    await Notificaciones.marcarVista(alerta);
    if (!mounted) return;
    setState(() => _alertaPendiente = null);
    if (alerta.tipo == 'foto') {
      final alertaId = alerta.alertaId;
      if (alertaId == null) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaVerFoto(alertaId: alertaId)));
      return;
    }
    final titulo = alerta.titulo;
    final cuerpo = alerta.cuerpo;
    if (titulo == null || cuerpo == null) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PantallaVerAlerta(tipo: alerta.tipo, titulo: titulo, cuerpo: cuerpo),
    ));
  }

  Future<void> _abrirNotificaciones() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaNotificaciones()));
    // Al volver, ya se marcaron todas como vistas — refresca el aviso.
    _cargarAlertaPendiente();
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

  void _abrirEmergencias() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaEmergencias()));
  }

  void _abrirFoto() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaFoto()));
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
            _Encabezado(onTocarNotificacion: _abrirNotificaciones, nombre: _perfil?.nombre),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  children: [
                    if (_alertaPendiente != null) ...[
                      _AvisoAlertaPendiente(
                        alerta: _alertaPendiente!,
                        onVer: _abrirAlertaPendiente,
                        onDescartar: _descartarAlertaPendiente,
                      ),
                      const SizedBox(height: 20),
                    ],
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
                          subtitulo: 'Compartir con vecinos',
                          onTap: _abrirFoto,
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
        color: AlertBotColores.verdeMenta,
        borderRadius: BorderRadius.circular(radioTarjeta),
        boxShadow: sombraTarjeta(color: AlertBotColores.verdeOscuro),
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
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
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

/// Aviso de "tenés una alerta sin ver" arriba del botón de Pánico — para
/// cuando el vecino abre la app sin haber tocado la notificación (la
/// descartó, no la vio, el celular estaba bloqueado). Se llena con lo
/// que ya guardó Notificaciones al llegar el push, sin pedirle nada al
/// backend.
class _AvisoAlertaPendiente extends StatelessWidget {
  final NotificacionGuardada alerta;
  final VoidCallback onVer;
  final VoidCallback onDescartar;

  const _AvisoAlertaPendiente({required this.alerta, required this.onVer, required this.onDescartar});

  @override
  Widget build(BuildContext context) {
    final tipo = alerta.tipo;
    final esPanico = tipo == 'panico';
    final esFoto = tipo == 'foto';
    final color = esPanico ? AlertBotColores.rojoPanico : AlertBotColores.verdePrincipal;
    final icono = esFoto
        ? Icons.photo_camera_rounded
        : (esPanico ? Icons.sos_rounded : Icons.directions_walk_rounded);
    final titulo = esFoto ? 'Alguien compartió algo cerca tuyo' : (alerta.titulo ?? 'Tenés una alerta sin ver');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radioTarjeta),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        boxShadow: sombraTarjeta(color: color),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(onPressed: onVer, child: const Text('Ver')),
                    TextButton(
                      onPressed: onDescartar,
                      style: TextButton.styleFrom(foregroundColor: AlertBotColores.textoSuave),
                      child: const Text('Descartar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
