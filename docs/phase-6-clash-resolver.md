# Fase 6: Clash Resolver

## Alcance implementado

- Consulta autenticada de empalmes a partir de `schedule_items` y escenarios.
- Agrupación de opciones simultáneas sin duplicar conflictos.
- Preferencias manuales de géneros y artistas persistidas por usuario.
- OAuth 2.0 de Spotify para importar artistas y géneros más escuchados.
- Recomendación ponderada con gustos agregados de todos los integrantes.
- Explicación del artista, escenario y coincidencias que motivaron el resultado.
- Caché Drift, cola de preferencias manuales y recomendación local sin red.

## Flujo OAuth

1. Flutter solicita `POST /api/v1/spotify/authorize` con el JWT del usuario.
2. FastAPI genera una URL con estado firmado y expiración de diez minutos.
3. Spotify regresa al callback configurado en `SPOTIFY_REDIRECT_URI`.
4. FastAPI intercambia el código, consulta `/v1/me/top/artists` y normaliza los
   gustos en SQL Server.
5. El access token y el refresh token de Spotify no se almacenan.

Si faltan credenciales, Spotify rechaza el inicio con un error controlado y la
selección manual permanece completamente disponible.

## Endpoints

- `GET /api/v1/clash-resolver/conflicts`
- `POST /api/v1/clash-resolver/recommendation`
- `POST /api/v1/spotify/authorize`
- `GET /api/v1/spotify/callback`
- `POST /api/v1/spotify/connect`
- `GET /api/v1/preferences/music`
- `POST /api/v1/preferences/music/manual`

## Persistencia

La migración `005_phase6_music_preferences.sql` agrega `artists` y
`music_artist_preferences`. Las preferencias conservan `source` (`manual` o
`spotify`) y peso exacto `DECIMAL(5,2)`. Flutter usa la versión 4 del esquema
Drift para preferencias, empalmes y recomendaciones.

## Verificación

- Pruebas del algoritmo, desempates y contratos de horarios.
- Pruebas Flutter para cola manual offline y recomendación local.
- Validación de la migración en SQL Server local.
- `flutter analyze`, suites completas y compilaciones web/Android.
