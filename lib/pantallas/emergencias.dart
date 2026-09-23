import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../tema.dart';

/// Mismos números que NUMEROS_EMERGENCIA en config.py del bot — no hay
/// una ruta en el backend para traerlos, así que se mantienen acá a
/// mano. Si se editan de un lado, editar del otro.
const _numerosEmergencia = [
  ('🚓', 'Central de Emergencias Nacional (Policía)', '911'),
  ('🔥', 'Bomberos', '100'),
  ('🏚️', 'Defensa Civil', '103'),
  ('🌳', 'Emergencia ambiental', '105'),
  ('⚓', 'Emergencia náutica', '106'),
  ('🆘', 'Atención a víctimas de violencia de género', '144'),
  ('🚑', 'SAME (emergencias médicas)', '107'),
  ('💬', 'Línea de prevención del suicidio', '135'),
  ('🧒', 'Chicos y chicas extraviados', '142'),
];

class PantallaEmergencias extends StatelessWidget {
  const PantallaEmergencias({super.key});

  /// Abre el marcador del teléfono con el número cargado — no llama
  /// directo (ni Android ni el usuario lo permitirían para una app
  /// externa): hay que tocar el botón verde para confirmar. En un
  /// dispositivo sin línea (como una tablet sin chip) no hay nada que
  /// hacer del lado de la app; mostramos el número para marcarlo a mano
  /// tanto si url_launcher devuelve que no pudo como si tira una
  /// excepción (pasa en algunos equipos sin app de teléfono instalada).
  Future<void> _llamar(BuildContext context, String numero) async {
    final uri = Uri(scheme: 'tel', path: numero);
    var pudoAbrir = false;
    try {
      pudoAbrir = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      pudoAbrir = false;
    }
    if (!pudoAbrir && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Este dispositivo no puede llamar. Marcá $numero desde un teléfono con línea.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergencias')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Números de emergencia',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AlertBotColores.verdeOscuro),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tocá "Llamar" para abrir el marcador con el número cargado '
              '(confirmás vos el llamado). Necesita un teléfono con línea.',
              style: TextStyle(color: AlertBotColores.textoSuave),
            ),
            const SizedBox(height: 20),
            for (final (emoji, titulo, numero) in _numerosEmergencia)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(radioTarjeta),
                    boxShadow: sombraTarjeta(),
                  ),
                  child: Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 26)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titulo,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              numero,
                              style: const TextStyle(
                                color: AlertBotColores.textoSuave,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () => _llamar(context, numero),
                        style: FilledButton.styleFrom(
                          backgroundColor: AlertBotColores.verdePrincipal,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.call_rounded, size: 18),
                        label: const Text('Llamar'),
                      ),
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
