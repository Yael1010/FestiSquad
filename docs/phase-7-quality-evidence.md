# Fase 7: Calidad y requisitos no funcionales

## Alcance implementado

### Seguridad

- FastAPI exige HTTPS en `staging` y `production`, agrega HSTS y cabeceras de
  endurecimiento, limita cada cuerpo HTTP a 1 MiB y oculta Swagger en producción.
- El proxy de referencia en `deploy/nginx/festisquad.conf` acepta únicamente
  TLS 1.3 con `TLS_AES_256_GCM_SHA384`. Así se obtiene AES-256 en tránsito sin
  distribuir una llave secreta dentro del APK.
- Flutter release exige `API_BASE_URL=https://...`; Android release deshabilita
  tráfico claro. El overlay de debug conserva HTTP para el backend local.
- Los tokens JWT siguen en `flutter_secure_storage`. Las credenciales privadas
  se configuran mediante variables de ambiente y nunca deben versionarse.

### Rendimiento y observabilidad

- Cada respuesta incluye `X-Request-ID`, `X-Process-Time-Ms` y `Server-Timing`.
- Las solicitudes que superan `PERFORMANCE_TARGET_MS` se registran como lentas.
- El benchmark usa P95 para evitar que un promedio oculte valores extremos:

```powershell
cd backend
.venv\Scripts\Activate.ps1
python scripts\benchmark_api.py --url http://127.0.0.1:8000/health --requests 30
python scripts\benchmark_api.py --url http://127.0.0.1:8000/health/db --requests 30
```

El segundo comando incluye la conexión real a SQL Server y es la evidencia más
representativa. Debe terminar con `CUMPLE` y código de salida cero.

### Tolerancia a fallos

- Flutter captura errores de framework, plataforma y zona y presenta una vista
  estable si una pantalla no puede renderizarse.
- Solo los GET fallidos por red, timeout o HTTP 502/503/504 se reintentan, hasta
  dos veces con backoff. Los POST conservan idempotencia explícita del dominio.
- Los repositorios mantienen la estrategia offline-first existente: caché local,
  cola de sincronización y mensajes comprensibles cuando la red desaparece.

### Batería

- El GPS usa precisión baja, filtro de 15 metros, lifecycle y un límite de tres
  minutos en segundo plano. No arranca si no hay squad activo ni mantiene wake lock.
- La validación física no puede sustituirse por una prueba unitaria. Con un Poco
  X5 Pro conectado por ADB, ejecutar desde la raíz:

```powershell
powershell -ExecutionPolicy Bypass -File tools\measure_android_battery.ps1
```

Registrar modelo, versión de Android, batería inicial/final, conectividad y
duración. Adjuntar `battery-phase7.txt`. La fase acepta un consumo máximo de 10
puntos porcentuales durante 60 minutos de uso representativo.

## Verificación automatizada

```powershell
cd backend
pytest -q

cd ..\mobile
flutter analyze
flutter test
```

Las pruebas de fase 7 validan cabeceras, trazabilidad, límite de cuerpo, HTTPS,
HSTS, latencia de aplicación, política de reintentos y bloqueo de HTTP release.
`database/006_phase7_quality_checks.sql` debe devolver cero filas en su primera
consulta y `decimal(18,2)` en la segunda.

Ejecución local del 26 de septiembre de 2026:

- Backend: 55 pruebas aprobadas.
- Flutter: 31 pruebas aprobadas.
- `flutter analyze`: sin incidencias.

## Evidencia pendiente antes de entrega académica

- Captura del benchmark contra `/health/db` en la computadora de despliegue.
- Reporte de batería de 60 minutos en el dispositivo objetivo.
- Certificado y dominio reales en el proxy de producción.

Estos puntos dependen del ambiente físico y no se declaran aprobados hasta que
se adjunten sus resultados.
