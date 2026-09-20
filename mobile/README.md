# FestiSquad Mobile

Aplicación Flutter offline-first para coordinación de squads en festivales.

## Ejecutar la demostración

```powershell
flutter pub get
flutter run -d chrome
```

Si el servidor de desarrollo de Flutter no inicia, se puede servir la
compilación verificada con:

```powershell
flutter build web
node tool/serve_preview.js
```

En web y Windows, la aplicación se muestra dentro de un marco de teléfono de
390 x 844 px. En Android e iOS utiliza directamente las dimensiones y áreas
seguras del dispositivo.

Para abrirla en un emulador Android conectado:

```powershell
flutter devices
flutter run -d <device-id>
```

La demostración comienza en la pantalla de acceso. El enlace
`Explorar demostración` permite entrar al dashboard sin configurar todavía el
backend de autenticación.
