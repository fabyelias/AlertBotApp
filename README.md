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
✅ **Paleta calcada del chat de Telegram del bot.** Se midieron los
   colores reales (muestreo de píxeles) sobre capturas del video de
   referencia: verde salvia del fondo del chat (`verdeGradiente`), verde
   menta de las burbujas/botones resaltados (`verdeMenta`), y el verde
   oscuro de acentos y texto (`verdePrincipal`/`verdeOscuro`) — todo
   centralizado en `AlertBotColores`, así que cambia en toda la app de
   una vez. Las pantallas siguen siendo nativas (botones, listas,
   formularios), no una imitación de chat — eso se charló antes de
   tocar nada. Tipografía: se mantiene Roboto (la fuente nativa de
   Android, ya muy parecida a la del video, que es un iPhone) en vez de
   importar una fuente nueva.
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
     difusión de siempre).
   - **Ver lo que comparten otros vecinos** (`lib/pantallas/ver_foto.dart`):
     cuando a un vecino de la app le llega un push de que alguien
     compartió algo cerca, tocarlo (o tocar "Ver" si la app estaba
     abierta — Android no muestra sola una notificación de sistema en
     ese caso) abre la foto/video (`lib/main.dart` engancha
     `onMessageOpenedApp`/`getInitialMessage`/`onMessage` de
     `firebase_messaging` para esto). **Video todavía no se reproduce
     dentro de la app** (evitamos sumar `video_player`/`chewie` por
     ahora, para no arriesgar el build como pasó con el comando de voz)
     — se avisa igual que se compartió uno, y se puede reportar.
   - **Ver el aviso de una alerta de Pánico o Rondas**
     (`lib/pantallas/ver_alerta.dart`): a diferencia de Foto/clip, acá el
     título y el cuerpo ya vienen completos en el push (`tipo_push` en
     `_difundir_a_vecinos`, del lado del bot), así que no hace falta
     pedirle nada al backend — tocar la notificación (o "Ver" si la app
     estaba abierta) muestra directo el aviso. Antes de esto, tocar una
     notificación de Pánico/Rondas abría la app sin mostrar nada de lo
     que pasó.
   - **Ver la alerta aunque no toques la notificación, y campanita con
     historial** (`lib/notificaciones.dart` + el aviso arriba del botón
     de Pánico y la campanita en `inicio.dart` + `lib/pantallas/
     notificaciones.dart`): `main.dart` registra
     `FirebaseMessaging.onBackgroundMessage`, que corre en un isolate
     aparte incluso con la app cerrada, y va guardando ahí mismo cada
     alerta que llega (se haya tocado la notificación o no), en una
     lista de hasta 30 en `SharedPreferences` — no se pisan entre sí.
     Al abrir la app por cualquier lado — ícono, volver de otra app, no
     solo tocando la notificación — Inicio lee la más nueva sin ver y la
     muestra en una tarjeta con "Ver"/"Descartar", hasta que el vecino
     la vea. Sin esto, un vecino que no llegaba a tocar la notificación a
     tiempo (se le pasó, el celular estaba bloqueado) no se enteraba de
     nada al entrar después. La campanita del encabezado (antes decía
     "todavía no está lista") ahora abre `PantallaNotificaciones`, con
     el historial completo — pánico, rondas y foto/clip, más recientes
     primero, con un punto de color en las que todavía no se vieron; al
     abrirla se marcan todas como vistas.
   - **Reportar contenido** (botón "Reportar" en `ver_foto.dart`):
     manda el motivo (obsceno, spam, no corresponde, u otro a mano) a
     `POST /api/foto/{alerta_id}/reportar`, que se lo reenvía al
     administrador por Telegram junto con la foto/video para que decida
     si corresponde dar de baja a quien la subió.
   - **Sonido de alertas con sirenas** (`lib/pantallas/sonido_alerta.dart`,
     `lib/sonido_alerta.dart`, `lib/notificaciones_locales.dart`): una
     tarjeta más en "Acciones rápidas" para elegir con qué sonido avisa
     AlertBot — sirena clásica, corta (yelp) o dos tonos, sintetizadas
     con Python puro (sin descargar ningún audio de terceros) y
     empaquetadas como recursos de Android en `android/app/src/main/res/
     raw/`. Usa `flutter_local_notifications` para armar un canal de
     notificación por sirena (`AndroidNotificationChannel` con
     `RawResourceAndroidNotificationSound`) y para mostrar la vista
     previa al tocar 🔊. La elección se guarda local y se manda al
     backend en `canal_sonido` (mismo `POST /api/token-push` que ya
     mandaba el token, en cada apertura y también al instante al
     cambiarla) — el bot arma el push con ese canal
     (`AndroidConfig.notification.channel_id` en `push.py`), así que
     Android usa la sirena elegida incluso con la app cerrada o en
     segundo plano, sin que el servidor tenga que mandar ningún archivo
     de audio. Con la app abierta, como Android no muestra sola una
     notificación de sistema, se muestra una notificación local propia
     con el mismo canal — así la sirena suena en cualquier caso.

   Quedan **a propósito** fuera de la app: 📋 Historial, ⚙️ Vecinos, 🩺
   Estado del bot, 🔔 Probar sirena y 🗂️ Categorías de voz son
   herramientas *solo de administrador* en el bot — no tiene sentido
   exponérselas a un vecino común. 🎙️ **Comando de voz** sigue en pausa
   (ver pendiente #2).
   - **Elegir desde dónde avisa el botón de Pánico** (`_confirmarYActivar`
     en `inicio.dart`): antes, toda alerta se mandaba siempre con la
     dirección del domicilio guardado — un problema si el vecino ve por
     cámara que le están entrando a robar la casa estando él en otro
     lado: había que avisar a los vecinos de SU CASA, no a los de donde
     está parado. Ahora, al confirmar la categoría, elige "Mi domicilio"
     (de siempre, no depende del GPS) o "Donde estoy" (pide la ubicación
     actual con `Geolocator.getCurrentPosition()` recién en ese momento,
     no antes) — esa elección define tanto a qué vecinos les llega (el
     filtro por radio del lado del bot) como qué dirección ven en el
     aviso (la del domicilio, o un link de Google Maps a la ubicación
     actual, ya que esa no tiene una dirección de texto guardada).
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
al registrarse; `arranque.dart` lo vuelve a mandar en cada apertura
(`POST /api/token-push`), por si ese primer intento falló (Google Play
Services no listo, sin internet, permiso aceptado tarde) o Firebase lo
rotó después — sin esto, un vecino podía quedar sin notificaciones para
siempre sin ninguna forma de corregirlo (nos pasó probando en la
tablet). Del lado del bot (`fabyelias/AlertBot`, ya en `main`):
`push.py` manda la notificación a cada vecino de la app cuando se
activa un pánico, ronda o foto/clip cerca. Necesita la variable de
entorno `FIREBASE_SERVICE_ACCOUNT_JSON` cargada en Railway (instrucciones en el README
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
  notificaciones.dart      — historial de alertas en el celular (hasta 30, la más nueva sin ver primero)
  sonido_alerta.dart       — sonidos de sirena disponibles + preferencia guardada
  notificaciones_locales.dart — canales de Android por sirena + mostrar notificación local
  bienvenida.dart          — pantalla de inicio/splash
  comando_voz_servicio.dart — motor del comando de voz (Picovoice Porcupine + servicio en primer plano)
                              — en pausa, no enlazado desde el menú (ver pendiente #2)
  pantallas/
    arranque.dart          — primera pantalla; decide a dónde ir según la sesión guardada, y de paso refresca el token de notificaciones (POST /api/token-push)
    registro.dart          — alta de vecino
    esperando_aprobacion.dart — consulta /api/estado hasta que el admin aprueba
    inicio.dart             — pantalla principal, botón de pánico (ya activa alertas de verdad)
    emergencias.dart        — números de emergencia fijos, llama con url_launcher
    rondas.dart              — iniciar/terminar ronda, con novedades al cerrar
    mi_familia.dart          — integrantes e invitación (solo titular)
    mi_direccion.dart        — actualizar dirección (solo titular)
    foto.dart                — sacar/grabar/elegir y mandar una foto o video
    ver_foto.dart             — ver lo que compartió otro vecino (llega por push) y reportarlo
    ver_alerta.dart           — ver el aviso de una alerta de Pánico o Rondas (llega por push)
    notificaciones.dart       — historial completo, abre desde la campanita en Inicio
    sonido_alerta.dart        — elegir sirena, con vista previa tocable
    comando_voz.dart        — pantalla del comando de voz — en pausa, no enlazado desde el menú
assets/
  wakewords/               — archivos de Picovoice del comando de voz (ver LEEME.md ahí)
  icono/                    — ícono y logo del splash (escudo verde/blanco), usados por
                              flutter_launcher_icons y flutter_native_splash (ver pubspec.yaml)
android/app/src/main/res/raw/
  alertbot_sirena_clasica.wav, alertbot_sirena_corta.wav, alertbot_sirena_dostonos.wav
                            — sirenas sintetizadas (ver notificaciones_locales.dart)
```
