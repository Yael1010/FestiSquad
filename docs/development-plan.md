# Plan de Desarrollo Markdown - FestiSquad

## Resumen

FestiSquad se desarrollará como una app móvil **Flutter offline-first** con backend **FastAPI modular** y base de datos **SQL Server en 3FN**. El MVP priorizará logística, ubicación resiliente, comunicación básica de squad, finanzas compartidas y resolución de conflictos musicales con Spotify y fallback manual.

## Arquitectura Base

- **Frontend Flutter:** arquitectura por features, Riverpod, capas `data/domain/presentation`, persistencia local offline-first y sincronización controlada con API.
- **Backend FastAPI:** monolito modular por dominios, API bajo `/api/v1`, JWT, Pydantic y servicios separados de routers.
- **SQL Server:** modelo relacional en 3FN, dinero con `DECIMAL(18,2)` y prohibición de coma flotante para importes.

## Fases

1. Fundamentos del monorepo, Flutter, FastAPI, SQL Server y documentación.
2. Autenticación y gestión de squads privados.
3. Modelo relacional y persistencia local offline-first.
4. Mapa resiliente con caché y política GPS de 15 m / 3 min.
5. Fondo común con deudas cruzadas y precisión decimal.
6. Clash Resolver con Spotify OAuth 2.0 y fallback manual.
7. Seguridad, rendimiento, tolerancia a fallos, batería y evidencias de calidad.

## APIs Iniciales

- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/refresh`
- `POST /api/v1/squads`
- `POST /api/v1/squads/join`
- `GET /api/v1/squads/{squad_id}`
- `POST /api/v1/locations`
- `GET /api/v1/locations/squad/{squad_id}/latest`
- `POST /api/v1/expenses`
- `GET /api/v1/expenses/squad/{squad_id}/balances`
- `GET /api/v1/clash-resolver/conflicts`
- `POST /api/v1/clash-resolver/recommendation`
- `POST /api/v1/spotify/connect`
- `POST /api/v1/preferences/music/manual`

## Entregables

- Código fuente organizado.
- Diagrama de arquitectura.
- Diagrama entidad-relación.
- Documento de decisiones técnicas.
- Evidencia de pruebas.
- Evidencia de RNF.
- README de instalación, ejecución y explicación del MVP.

