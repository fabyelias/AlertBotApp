# AlertBotApp

App nativa Android de AlertBot (seguridad vecinal), pensada para
complementar al bot de Telegram — no reemplazarlo. El admin sigue
aprobando vecinos desde Telegram exactamente como hasta ahora.

## Estado actual

✅ Estructura del proyecto Flutter
✅ Pantallas: Bienvenida → Registro (nombre, apellido, dirección,
   ubicación) → Espera de aprobación → Inicio (botón de Pánico + menú)
✅ Tema visual verde/blanco de AlertBot
✅ **Conectada al backend real** (bot de Telegram, repo
   [fabyelias/AlertBot](https://github.com/fabyelias/AlertBot)):
   registro, consulta de estado y botón de pánico funcionan de punta a
   punta. El `id_vecino` (token) que devuelve el registro se guarda en
   el celular (`lib/sesion.dart`) — al reabrir la app, `arranque.dart`
   decide sola a qué pantalla ir según ese estado.

✅ **Carpeta `android/` generada y subida** (con `flutter create .` desde
una tablet, vía Termux + proot-distro con Debian). El proyecto ya
compila.

✅ **Permisos de Android agregados** en `AndroidManifest.xml`: internet
y ubicación (sin esto el registro y las alertas ni siquiera podían
llamar al backend — no eran parte de los 4 pendientes originales, pero
sin ellos la app no funciona en un celular real) más micrófono/servicio
en primer plano para el comando de voz.

⏳ **Pendiente:**
1. **Firebase**: conectar el proyecto real (el de Cuidar+, o uno
   nuevo) — agregar `google-services.json` en `android/app/` y activar
   `firebase_messaging`. Sin esto, los vecinos de la app no reciben
   las alertas de los demás (sí pueden activar las suyas).
2. **Comando de voz real — en pausa.** El código está armado
   (`lib/comando_voz_servicio.dart` + `lib/pantallas/comando_voz.dart`
   + el `<service>` y los `uses-permission` de Android), pero **se sacó
   el acceso desde la pantalla de Inicio** (ya no aparece esa tarjeta
   en el menú) porque el registro en console.picovoice.ai está roto:
   su formulario rechaza mails gratuitos (Gmail, etc.) con "valid
   company email", es un bug conocido de ellos, reportado por varios
   usuarios más, sin arreglo todavía. Los archivos siguen en el repo,
   listos para retomarlo cuando: (a) Picovoice arregle el registro o te
   den acceso por soporte, o (b) se decida cambiar a otro motor sin
   necesidad de cuenta (ej. Vosk, offline). Detalle de lo que hace
   falta en `assets/wakewords/LEEME.md`.
3. ✅ **Ícono y splash**: hecho — escudo con gradiente verde, casa y
   corazón (el diseño que pasaste), ya generado en todas las
   resoluciones dentro de `android/app/src/main/res/` (íconos legacy,
   ícono adaptativo de Android 8+, y la splash screen). Los bloques
   `flutter_launcher_icons`/`flutter_native_splash` en `pubspec.yaml`
   quedan igual por si en algún momento cambia el diseño y hay que
   regenerar todo desde `assets/icono/` con Flutter instalado.
4. ✅ **Límite de frecuencia en `/api/registro`**: hecho, pero vive en
   el otro repo ([fabyelias/AlertBot](https://github.com/fabyelias/AlertBot),
   rama `claude/limite-frecuencia-registro`, todavía no mergeada ni
   deployada) — máximo 5 registros por IP por hora
   (`limitador.py` + `api_app.py`). Importante: esto **no reemplaza**
   el punto "anti-duplicados" que se charló aparte (que la misma
   persona no pueda tener varias solicitudes activas a la vez) — ese
   sigue sin resolver y depende de tener algún dato estable del vecino
   (ver Firebase, pendiente #1).

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
  comando_voz_servicio.dart — motor del comando de voz (Picovoice Porcupine + servicio en primer plano)
                              — en pausa, no enlazado desde el menú (ver pendiente #2)
  pantallas/
    arranque.dart          — primera pantalla; decide a dónde ir según la sesión guardada
    registro.dart          — alta de vecino
    esperando_aprobacion.dart — consulta /api/estado hasta que el admin aprueba
    inicio.dart             — pantalla principal, botón de pánico (ya activa alertas de verdad)
    comando_voz.dart        — pantalla del comando de voz — en pausa, no enlazado desde el menú
assets/
  wakewords/               — archivos de Picovoice del comando de voz (ver LEEME.md ahí)
  icono/                    — ícono y logo del splash (escudo verde/blanco), usados por
                              flutter_launcher_icons y flutter_native_splash (ver pubspec.yaml)
```
