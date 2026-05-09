# Chat Cifrado — App Móvil

Cliente Flutter para el sistema de mensajería cifrada con servidor local. Los mensajes se cifran usando un algoritmo de sustitución monoalfabética antes de viajar por la red, y se muestran descifrados en los teléfonos de los participantes mientras el texto cifrado se visualiza en una pantalla LCD conectada a un Arduino.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web-success)]()
[![Build APK](https://github.com/twicegod/chat-cifrado-app/actions/workflows/build-apk.yml/badge.svg)](https://github.com/twicegod/chat-cifrado-app/actions/workflows/build-apk.yml)
[![License](https://img.shields.io/badge/License-MIT-yellow)]()

---

## Descargar APK

La última versión está disponible en la sección **[Releases](https://github.com/twicegod/chat-cifrado-app/releases/latest)**.

Cada vez que se sube una nueva versión etiquetada (tag `vX.X.X`), GitHub Actions compila automáticamente el APK y lo publica.

---

## Arquitectura del sistema

```
+----------------+       +-------------------+       +-----------------+
|   Telefono A   |       |   Telefono B      |       |   Panel Admin   |
|  (chat-app)    |       |  (chat-app)       |       |  (navegador)    |
+--------+-------+       +---------+---------+       +--------+--------+
         |                         |                          |
         |  WebSocket cifrado      |  WebSocket cifrado       |  WebSocket
         |                         |                          |
         +---------+---------------+--------------+-----------+
                   |                              |
                   v                              v
         +---------+----------------------------------------+
         |          Servidor FastAPI (laptop)               |
         |          Hotspot WiFi 192.168.137.1              |
         +-----------------------+--------------------------+
                                 |
                                 | Serial USB (9600 baud)
                                 v
                          +------+-------+
                          |  Arduino +   |
                          |  LCD 16x2    |
                          +--------------+
```

Este repo contiene **únicamente la app cliente Flutter**. El servidor se encuentra en un repo separado:

> **Servidor:** [twicegod/servidor_local](https://github.com/twicegod/servidor_local)

---

## Características

- Interfaz estilo WhatsApp (verde corporativo, burbujas de chat).
- Lista de contactos en tiempo real vía WebSocket — sin polling.
- Indicador de mensajes no leídos por contacto.
- Detección automática de IP del servidor en versión web.
- Compatible con Flutter Web (PWA) y Android (APK nativo).
- Login simple: solo nombre de usuario e IP del servidor.

---

## Cómo correr la app

### Requisitos previos

- Flutter SDK 3.x — [instalar Flutter](https://docs.flutter.dev/get-started/install)
- Servidor corriendo (ver [servidor_local](https://github.com/twicegod/servidor_local))
- Hotspot WiFi activo en la PC del servidor (Windows: `Configuración > Red > Mobile hotspot`)

### Versión Android (APK nativo)

```bash
flutter pub get
flutter build apk --release
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk`.

### Versión Web

```bash
flutter pub get
flutter build web --release
```

Luego copiar el contenido de `build/web/` a la carpeta `static/` del servidor.

---

## Estructura del código

```
lib/
├── main.dart                       Punto de entrada de la app
├── models/
│   └── message.dart                Modelo de mensaje
├── services/
│   └── chat_service.dart           Singleton WebSocket (streams)
├── screens/
│   ├── login_screen.dart           Pantalla de conexion
│   ├── contacts_screen.dart        Lista de contactos
│   └── chat_screen.dart            Conversacion estilo WhatsApp
└── utils/
    ├── platform_utils.dart         Import condicional
    ├── platform_utils_web.dart     Detecta IP desde URL (web)
    └── platform_utils_stub.dart    IP por defecto (Android)
```

### Patrón de comunicación

`ChatService` es un singleton que mantiene un WebSocket abierto al servidor y expone tres streams:

- `usersStream` — lista de usuarios conectados (push del servidor).
- `messages` — mensajes entrantes.
- `unreadStream` — contador de no leídos por contacto.

Las pantallas se suscriben con `StreamBuilder` y se actualizan reactivamente.

---

## Cómo funciona el cifrado

El servidor mantiene un diccionario de sustitución (`cipher.json`) editable desde el panel admin:

```json
{
  "a": "@1",  "b": "#2",  "c": "$3",  ...
  " ": "_",   ".": ">>"
}
```

Cuando un usuario envía `"hola"`, el servidor:

1. Cifra el texto: `"hola"` → `"<8>1<3@1"`.
2. Lo manda por Serial al Arduino → aparece en el LCD.
3. Reenvía el **texto original** al destinatario.
4. Reporta al panel admin ambas versiones (original + cifrada).

> El cifrado es educativo, no criptográficamente seguro. La meta es ilustrar conceptos de criptografía clásica de forma visible.

---

## Tecnologías

| Componente | Tecnología |
|------------|-----------|
| UI | Flutter 3.x + Material Design |
| Estado | Streams + StreamBuilder |
| Red | `web_socket_channel` |
| Plataformas | Android · Web (Flutter Web) |
| Build CI | GitHub Actions |

---

## Roadmap

- [x] Cliente web (Flutter Web)
- [x] APK Android nativo
- [x] Build automático con GitHub Actions
- [ ] Notificaciones locales en Android
- [ ] Historial persistente en SQLite
- [ ] Cifrado AES real (además del de sustitución)
- [ ] iOS build

---

## Licencia

MIT — proyecto educativo, libre de uso y modificación.

---

**Autor:** [@twicegod](https://github.com/twicegod)
**Repos relacionados:** [servidor_local](https://github.com/twicegod/servidor_local)
