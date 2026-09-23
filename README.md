# AlertBotApp

App nativa Android de AlertBot (seguridad vecinal), pensada para
complementar al bot de Telegram — no reemplazarlo. El admin sigue
aprobando vecinos desde Telegram exactamente como hasta ahora.

## Estado actual

✅ Estructura del proyecto Flutter
✅ Pantallas: Bienvenida → Registro (nombre, apellido, dirección,
   ubicación) → Espera de aprobación → Inicio (botón de Pánico + menú)
✅ **Interfaz rediseñada** (`lib/tema.dart` + pantallas): encabezado con
   degradé de marca y saludo por nombre, tarjetas con sombra suave, botón
   de Pánico con halo, y feedback real al tocar cualquier botón — nada
   queda "muerto".
✅ **Menú real del bot, no solo Pánico.** Se grabó un video usando el bot
   de Telegram (teclado persistente con 11 botones) y se replicaron en la
   app las funciones que tiene sentido que use un vecino común:
   - 📞 **Emergencias**: llama de verdad a los números fijos del bot
     (`NUMEROS_EMERGENCIA` en `config.py`, replicados en
     `lib/pantallas/emergencias.dart`) usando `url_launcher`.
   - 🚶 **Rondas** (`lib/pantallas/rondas.dart`): iniciar/terminar ronda,
     ver quién está haciendo ronda ahora, y cerrar con una novedad
     (presets tipo "Perro suelto" o texto libre) — mismo flujo que
     Telegram, mismos mensajes a los vecinos.
   - 📍 **Mi dirección** (`lib/pantallas/mi_direccion.dart`) y
     👨‍👩‍👧 **Mi familia** (`lib/pantallas/mi_familia.dart`, invita por
     `share_plus` con el link de un solo uso que genera el bot): solo
     visibles si el vecino es titular de su grupo familiar
     (`es_titular` en `/api/estado`), igual que en Telegram.
   - 📸 **Foto/clip** (`lib/pantallas/foto.dart`): sacar foto, grabar un
     video corto o elegir de la galería, y mandarlo — llega a los
     vecinos exactamente igual que si se lo hubieran mandado al bot por
     Telegram (la app sube los bytes a `POST /api/foto`, que por dentro
     los sube a Telegram para conseguir un `file_id` y reusa la misma
     difusión de siempre). Los vecinos de la app reciben un push cuando
     alguien comparte algo cerca; verlo *dentro* de la app (en vez de
     solo el aviso) queda para más adelante — el backend ya tiene
     `GET /api/foto/{alerta_id}` listo para eso.

   Quedan **a propósito** fuera de la app: 📋 Historial, ⚙️ Vecinos, 🩺
   Estado del bot, 🔔 Probar sirena y 🗂️ Categorías de voz son
   herramientas *solo de administrador* en el bot — no tiene sentido
   exponérselas a un vecino común. 🎙️ **Comando de voz** sigue en pausa
   (ver pendiente #2).
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

✅ **Firebase conectado, app y bot.** Proyecto propio `alertbotapp`
(no comparte con Cuidar+): `google-services.json` en `android/app/`,
plugin de Gradle, `Firebase.initializeApp()` al arrancar, y
`registro.dart` pide permiso de notificaciones y manda el token de FCM
al registrarse. Del lado del bot (`fabyelias/AlertBot`, rama
`claude/push-notificaciones-app`, todavía sin mergear ni deployar):
`push.py` manda la notificación a cada vecino de la app cuando se
activa un pánico cerca — antes ese token se guardaba pero no se usaba
para nada. Falta que mergees esa rama y cargues la variable de entorno
`FIREBASE_SERVICE_ACCOUNT_JSON` en Railway (instrucciones en el README
de ese repo) — sin eso, el push queda desactivado en silencio.

⏳ **Pendiente:**
1. ✅ **Firebase**: hecho (ver arriba). Solo falta que mergees la rama
   del bot y cargues `FIREBASE_SERVICE_ACCOUNT_JSON` en Railway.
2. **Comando de voz real — en pausa, y ahora también sin sus paquetes.**
   El código Dart sigue en el repo (`lib/comando_voz_servicio.dart` +
   `lib/pantallas/comando_voz.dart`, sin usarse — ninguna pantalla los
   importa), pero se sacaron de `pubspec.yaml` sus tres dependencias
   nativas (`porcupine_flutter`, `permission_handler`,
   `flutter_foreground_task`) y del `AndroidManifest.xml` sus permisos
   y el `<service>`: `permission_handler_android` exige mínimo SDK de
   Android **37** (todavía en preview en este momento), y eso rompía
   la compilación de **toda** la app, no solo la del comando de voz.
   No tenía sentido dejar tres paquetes sin usar bloqueando el resto.

   Aparte sigue el motivo original: el registro en console.picovoice.ai
   está roto (rechaza mails gratuitos como Gmail con "valid company
   email", bug conocido de ellos, sin arreglo todavía). Para retomar
   esto hace falta: (a) que Picovoice arregle el registro o te den
   acceso por soporte, o se decida cambiar a otro motor sin cuenta
   (ej. Vosk, offline) — *y* (b) volver a agregar esos tres paquetes
   a `pubspec.yaml` y sus permisos al manifest (una vez que el SDK 37
   sea estable, o fijando una versión más vieja de `permission_handler`
   que no lo exija). Detalle en `assets/wakewords/LEEME.md`.
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
    emergencias.dart        — números de emergencia fijos, llama con url_launcher
    rondas.dart              — iniciar/terminar ronda, con novedades al cerrar
    mi_familia.dart          — integrantes e invitación (solo titular)
    mi_direccion.dart        — actualizar dirección (solo titular)
    foto.dart                — sacar/grabar/elegir y mandar una foto o video
    comando_voz.dart        — pantalla del comando de voz — en pausa, no enlazado desde el menú
assets/
  wakewords/               — archivos de Picovoice del comando de voz (ver LEEME.md ahí)
  icono/                    — ícono y logo del splash (escudo verde/blanco), usados por
                              flutter_launcher_icons y flutter_native_splash (ver pubspec.yaml)
```
