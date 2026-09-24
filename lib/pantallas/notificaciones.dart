import 'package:flutter/material.dart';
import '../notificaciones.dart';
import '../tema.dart';
import 'ver_alerta.dart';
import 'ver_foto.dart';

/// Historial de las últimas notificaciones que le llegaron a este
/// vecino (pánico, rondas y foto/clip) — se abre desde la campanita en
/// Inicio. Solo lee lo que ya guardó Notificaciones al recibir cada
/// push, no le pide nada al backend.
class PantallaNotificaciones extends StatefulWidget {
  const PantallaNotificaciones({super.key});

  @override
  State<PantallaNotificaciones> createState() => _PantallaNotificacionesState();
}

class _PantallaNotificacionesState extends State<PantallaNotificaciones> {
  List<NotificacionGuardada>? _notificaciones;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final lista = await Notificaciones.listar();
    // Ya las está mostrando todas: de acá en más, ninguna queda "sin ver".
    await Notificaciones.marcarTodasVistas();
    if (mounted) setState(() => _notificaciones = lista);
  }

  void _abrir(NotificacionGuardada n) {
    if (n.tipo == 'foto') {
      final alertaId = n.alertaId;
      if (alertaId == null) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaVerFoto(alertaId: alertaId)));
      return;
    }
    final titulo = n.titulo;
    final cuerpo = n.cuerpo;
    if (titulo == null || cuerpo == null) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PantallaVerAlerta(tipo: n.tipo, titulo: titulo, cuerpo: cuerpo),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final lista = _notificaciones;
    return Scaffold(
      backgroundColor: AlertBotColores.fondo,
      appBar: AppBar(title: const Text('Notificaciones')),
      body: lista == null
          ? const Center(child: CircularProgressIndicator())
          : lista.isEmpty
              ? const _SinNotificaciones()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _TarjetaNotificacion(notificacion: lista[i], onTap: () => _abrir(lista[i])),
                ),
    );
  }
}

class _SinNotificaciones extends StatelessWidget {
  const _SinNotificaciones();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_none_rounded, size: 56, color: AlertBotColores.textoSuave),
            const SizedBox(height: 16),
            const Text(
              'Todavía no te llegó ninguna notificación',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AlertBotColores.verdeOscuro),
            ),
            const SizedBox(height: 8),
            const Text(
              'Acá vas a ver las alertas de pánico, rondas y fotos/clips que te lleguen de tus vecinos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AlertBotColores.textoSuave, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaNotificacion extends StatelessWidget {
  final NotificacionGuardada notificacion;
  final VoidCallback onTap;
  const _TarjetaNotificacion({required this.notificacion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final esPanico = notificacion.tipo == 'panico';
    final esFoto = notificacion.tipo == 'foto';
    final color = esPanico ? AlertBotColores.rojoPanico : AlertBotColores.verdePrincipal;
    final colorClaro = esPanico ? AlertBotColores.rojoPanicoClaro : AlertBotColores.verdeClaro;
    final icono = esFoto
        ? Icons.photo_camera_rounded
        : (esPanico ? Icons.sos_rounded : Icons.directions_walk_rounded);
    final titulo = esFoto ? 'Alguien compartió algo cerca tuyo' : (notificacion.titulo ?? 'Alerta del barrio');
    final cuerpo = esFoto ? null : notificacion.cuerpo;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radioTarjeta),
        boxShadow: sombraTarjeta(),
        border: notificacion.visto ? null : Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radioTarjeta),
        child: InkWell(
          borderRadius: BorderRadius.circular(radioTarjeta),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: colorClaro, shape: BoxShape.circle),
                  child: Icon(icono, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      if (cuerpo != null && cuerpo.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          cuerpo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AlertBotColores.textoSuave, fontSize: 12.5),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        _tiempoRelativo(notificacion.fecha),
                        style: const TextStyle(color: AlertBotColores.textoSuave, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (!notificacion.visto)
                  Container(
                    margin: const EdgeInsets.only(left: 8, top: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _tiempoRelativo(DateTime fecha) {
  final diferencia = DateTime.now().difference(fecha);
  if (diferencia.inMinutes < 1) return 'Recién';
  if (diferencia.inMinutes < 60) return 'Hace ${diferencia.inMinutes} min';
  if (diferencia.inHours < 24) return 'Hace ${diferencia.inHours} h';
  if (diferencia.inDays < 7) return 'Hace ${diferencia.inDays} d';
  return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
}
