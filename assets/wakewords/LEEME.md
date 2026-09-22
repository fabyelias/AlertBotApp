# Archivos del comando de voz (Picovoice Porcupine)

Esta carpeta tiene que tener, para que "Comando de voz" funcione de
verdad (`lib/comando_voz_servicio.dart`), estos 5 archivos. Ninguno se
puede generar con código: salen de tu cuenta de Picovoice.

## 1. Conseguir el AccessKey (una vez)

1. Entrá a https://console.picovoice.ai y creá una cuenta gratis.
2. Copiá el **AccessKey** que te muestra en el panel principal.
3. Compilá la app pasándoselo así (no se commitea a git, va por
   parámetro de compilación):

   ```bash
   flutter run --dart-define=PICOVOICE_ACCESS_KEY=tu_access_key_aca
   ```

   En Codemagic: agregalo como variable de entorno
   (`PICOVOICE_ACCESS_KEY`) y sumá `--dart-define=PICOVOICE_ACCESS_KEY=$PICOVOICE_ACCESS_KEY`
   al comando `flutter build` del workflow.

## 2. Entrenar las 4 frases (una vez, en console.picovoice.ai → Porcupine)

Para cada frase, "Create Wake Word" → plataforma **Android** → texto
exacto → descargar el `.ppn` → renombrarlo así y ponerlo acá:

| Frase a detectar                    | Nombre del archivo                          | Categoría que activa |
|--------------------------------------|----------------------------------------------|------------------------|
| "Oye AlertBot, activa caída"         | `activa_caida_es_android.ppn`                | `caida` *(ver nota)*   |
| "Oye AlertBot, activa robo"          | `activa_robo_es_android.ppn`                 | `robo`                 |
| "Oye AlertBot, activa emergencia médica" | `activa_emergencia_medica_es_android.ppn` | `medica`                |
| "Oye AlertBot, activa incendio"      | `activa_incendio_es_android.ppn`             | `incendio` *(ver nota)*|

Nota: el backend (`CATEGORIAS_PANICO` en `config.py` del repo del bot)
hoy solo reconoce `robo`, `sospechoso`, `medica` y `otro`. La alerta por
voz funciona igual para las 4 frases (el vecino y los vecinos cercanos
la reciben), pero "caída" e "incendio" le van a aparecer al admin como
"❗ Otro" en vez de algo específico, hasta que se agreguen esas dos
categorías en el bot. Es un cambio chico (dos líneas en ese diccionario)
pero vive en otro repo (`fabyelias/AlertBot`) y requiere redeploy en
Railway, así que no se tocó acá sin pedirlo primero.

## 3. Modelo de español (una vez, se descarga del repo de Picovoice)

Porcupine viene con modelo en inglés por defecto; como las frases son en
español hace falta el modelo de idioma. Bajalo de:

https://github.com/Picovoice/porcupine/blob/master/lib/common/porcupine_params_es.pv

y guardalo acá como `porcupine_params_es.pv`.

## 4. Permisos nativos de Android (pendiente hasta que exista `android/`)

Cuando subas la carpeta `android/` al repo, hay que agregar en
`android/app/src/main/AndroidManifest.xml`, dentro de `<manifest>`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

y dentro de `<application>`:

```xml
<service
    android:name="com.pravera.flutter_foreground_task.service.ForegroundService"
    android:foregroundServiceType="microphone"
    android:exported="false" />
```

## Resultado esperado en esta carpeta

```
assets/wakewords/
  activa_caida_es_android.ppn
  activa_robo_es_android.ppn
  activa_emergencia_medica_es_android.ppn
  activa_incendio_es_android.ppn
  porcupine_params_es.pv
  LEEME.md   (este archivo)
```

Mientras falten estos archivos, el interruptor de "Comando de voz" en la
app queda deshabilitado con el mensaje "Todavía no está configurado".
