# AlertBotApp

App nativa Android de AlertBot (seguridad vecinal), pensada para
complementar al bot de Telegram — no reemplazarlo. El admin sigue
aprobando vecinos desde Telegram exactamente como hasta ahora.

## Estado actual

✅ Estructura del proyecto Flutter
✅ Pantallas: Bienvenida → Registro (nombre, apellido, dirección,
   ubicación) → Espera de aprobación → Inicio (botón de Pánico + menú)
   → Comando de voz (informativa)
✅ Tema visual verde/blanco de AlertBot
✅ **Conectada al backend real** (bot de Telegram, repo
   [fabyelias/AlertBot](https://github.com/fabyelias/AlertBot)):
   registro, consulta de estado y botón de pánico funcionan de punta a
   punta. El `id_vecino` (token) que devuelve el registro se guarda en
   el celular (`lib/sesion.dart`) — al reabrir la app, `arranque.dart`
   decide sola a qué pantalla ir según ese estado.

⏳ **Pendiente:**
1. **Firebase**: conectar el proyecto real (el de Cuidar+, o uno
   nuevo) — agregar `google-services.json` en `android/app/` y activar
   `firebase_messaging`. Sin esto, los vecinos de la app no reciben
   las alertas de los demás (sí pueden activar las suyas).
2. **Comando de voz real**: la pantalla de comando de voz hoy es solo
   informativa. Para que escuche con la pantalla bloqueada hace falta
   integrar un motor de palabra de activación (ej. Picovoice
   Porcupine) — se suma en una segunda etapa.
3. **Ícono y splash**: falta el ícono real de la app (hoy usa uno
   genérico de Flutter) y configurar `android/app/src/main/res`.
4. **Límite de frecuencia en `/api/registro`**: es una ruta pública
   que le escribe al admin por Telegram en cada llamada; conviene
   sumar un límite antes de publicar la app.

## Cómo compilarla

**En tu compu (por defecto):**

```bash
git clone https://github.com/fabyelias/AlertBotApp.git
cd AlertBotApp
flutter pub get
```

Abrí la carpeta en VS Code (con la extensión de Flutter), conectá el
celular por USB o abrí un emulador, y tocá "Run" (o `flutter run`).

**Desde un dispositivo sin compu (tablet, celular) — vía Codemagic:**

1. Conectá este repo (`fabyelias/AlertBotApp`) a Codemagic
2. Codemagic detecta automáticamente que es un proyecto Flutter
3. Configurá la firma de Android (keystore) en Codemagic, como ya
   hiciste para Cuidar+
4. Corré el build — te va a generar el `.aab`/`.apk` para instalar
   directo, sin pasar por tu compu.

## Estructura

```
lib/
  main.dart              — punto de entrada
  tema.dart               — colores y estilo visual
  api.dart                 — cliente HTTP contra el backend
  sesion.dart              — guarda el id_vecino (token) en el celular
  bienvenida.dart          — pantalla de inicio/splash
  pantallas/
    arranque.dart          — primera pantalla; decide a dónde ir según la sesión guardada
    registro.dart          — alta de vecino
    esperando_aprobacion.dart — consulta /api/estado hasta que el admin aprueba
    inicio.dart             — pantalla principal, botón de pánico (ya activa alertas de verdad)
    comando_voz.dart        — info del comando de voz
```
