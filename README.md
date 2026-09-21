# AlertBotApp

App nativa Android de AlertBot (seguridad vecinal), pensada para
complementar al bot de Telegram — no reemplazarlo. El admin sigue
aprobando vecinos desde Telegram exactamente como hasta ahora.

## Estado actual (primera versión)

✅ Estructura del proyecto Flutter
✅ Pantallas: Bienvenida → Registro (nombre, apellido, dirección,
   ubicación) → Espera de aprobación → Inicio (botón de Pánico + menú)
   → Comando de voz (informativa)
✅ Tema visual verde/blanco de AlertBot

⏳ **Pendiente, antes de que funcione de verdad:**
1. **Backend**: el servidor de Railway todavía no tiene las rutas
   `/api/registro`, `/api/estado/{id}` ni `/api/panico` que usa
   `lib/api.dart` — hoy el bot solo entiende Telegram. Este es el
   próximo paso grande.
2. **Firebase**: falta conectar el proyecto real de Firebase (el que
   ya tenés de Cuidar+, o uno nuevo) — agregar `google-services.json`
   en `android/app/` y activar `firebase_messaging` para las
   notificaciones push (aprobación, alertas de vecinos).
3. **Comando de voz real**: la pantalla de comando de voz hoy es
   solo informativa. Para que escuche de verdad con la pantalla
   bloqueada hace falta integrar un motor de palabra de activación
   (ej. Picovoice Porcupine) — se suma en una segunda etapa.
4. **Ícono y splash**: falta el ícono real de la app (hoy usa un
   ícono genérico de Flutter) y configurar `android/app/src/main/res`.

## Cómo compilarla (vía Codemagic, igual que tus otras apps)

1. Conectá este repo (`fabyelias/AlertBotApp`) a Codemagic
2. Codemagic detecta automáticamente que es un proyecto Flutter
3. Configurá la firma de Android (keystore) en Codemagic, como ya
   hiciste para Cuidar+
4. Corré el build — te va a generar el `.aab` para subir a la fase
   de test de Play Store

## Estructura

```
lib/
  main.dart              — punto de entrada
  tema.dart               — colores y estilo visual
  api.dart                 — cliente HTTP contra el backend (pendiente conectar)
  bienvenida.dart          — pantalla de inicio/splash
  pantallas/
    registro.dart          — alta de vecino
    esperando_aprobacion.dart
    inicio.dart             — pantalla principal, botón de pánico
    comando_voz.dart        — info del comando de voz
```
