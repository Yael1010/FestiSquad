# Fase 13: Rediseño, accesibilidad y entrega

## Alcance implementado

- Sistema visual consolidado en `app_theme.dart` y `festi_widgets.dart`.
- Controles interactivos con objetivos táctiles mínimos de 48 x 48 px.
- Componentes reutilizables para acciones, tarjetas y estados vacíos.
- Semántica explícita en las acciones principales para lectores de pantalla.
- Compatibilidad de estados vacíos con escalado de texto al 200 %.
- Eliminación del squad ficticio como estado inicial de una sesión.
- Identidad del encabezado obtenida del integrante actual del squad.
- Estados honestos cuando no hay catálogo, perfil o datos sincronizados.
- Preflight CORS habilitado para `PUT`, requerido por votos y decisiones.
- Prueba de integración del flujo de registro.
- Script único de verificación de secretos, backend y Flutter.

## Criterios de aceptación

1. La aplicación no muestra nombres, integrantes ni saldos ficticios después de
   autenticar a un usuario.
2. Los controles principales son operables mediante lector de pantalla y tienen
   un área táctil de al menos 48 x 48 px.
3. Los estados esenciales siguen siendo legibles con texto al 200 %.
4. Flutter web puede realizar preflight para todos los verbos usados por la API.
5. La suite backend, el análisis Flutter y las pruebas Flutter terminan sin
   errores antes de generar un build candidato.

## Verificación local

Desde la raíz del repositorio:

```powershell
powershell -ExecutionPolicy Bypass -File tools/verify_release.ps1
```

La prueba de integración puede ejecutarse por separado en un dispositivo:

```bash
cd mobile
flutter test integration_test/critical_flow_test.dart -d windows
```

## Evidencias manuales pendientes

- Medición de batería durante una sesión física de una hora.
- Prueba del APK release en un Xiaomi Poco X5 Pro o dispositivo equivalente.
- Benchmark contra el backend desplegado mediante HTTPS.
- Capturas finales de login, dashboard, mapa, fondo común y Clash Resolver.
