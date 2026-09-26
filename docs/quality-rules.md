# Reglas de Calidad

## Seguridad

- JWT firmado con secreto seguro por ambiente.
- HTTPS obligatorio fuera de desarrollo local.
- Tokens móviles en almacenamiento seguro.
- Datos de ubicación cifrados en tránsito con TLS 1.3 y
  `TLS_AES_256_GCM_SHA384`; no se incorpora una llave simétrica dentro de la app.
- Builds release de Flutter rechazan una `API_BASE_URL` que no use HTTPS.
- Android bloquea tráfico en texto claro salvo en el manifiesto de debug.
- OpenAPI queda deshabilitado en producción y cada respuesta incluye un
  identificador trazable sin exponer detalles internos.

## Rendimiento

- Objetivo de respuesta FastAPI: menos de 1.5 segundos en casos normales.
- El objetivo se evalúa sobre P95 con `backend/scripts/benchmark_api.py`.
- Índices para email, códigos de squad, ubicaciones recientes y gastos.
- Listados paginados cuando crezcan.

## Batería

- El GPS solo se sincroniza si hay desplazamiento mayor a 15 metros.
- En segundo plano se limita a máximo un envío cada 3 minutos.
- Evitar polling constante y tareas de fondo innecesarias.
- No iniciar el sensor si todavía no existe un squad activo.
- Validar el consumo durante 60 minutos en un Xiaomi Poco X5 Pro o dispositivo
  equivalente; la aceptación requiere un consumo menor o igual al 10% por hora.

## Tolerancia a fallos

- Flutter debe conservar estado útil desde caché.
- Pérdidas de red se muestran como estados offline, no como crashes.
- Las lecturas GET tienen como máximo dos reintentos con backoff; las escrituras
  no se repiten automáticamente para evitar duplicados.
- Errores no controlados muestran una vista estable y se registran para
  diagnóstico, sin cerrar abruptamente la aplicación.
