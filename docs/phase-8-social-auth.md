# Fase 8: Autenticación social

## Alcance implementado

- Registro e inicio de sesión con Google OAuth 2.0/OpenID Connect.
- Registro e inicio de sesión con el perfil de Spotify.
- Vinculación explícita de ambos proveedores desde una sesión FestiSquad activa.
- Persistencia normalizada de identidades externas sin almacenar access tokens
  ni refresh tokens de Google o Spotify.
- Flujo temporal de diez minutos y ticket aleatorio almacenado únicamente como
  SHA-256. El ticket se consume una sola vez para emitir los JWT de FestiSquad.
- Estado OAuth firmado para impedir modificaciones y callback sin JWT en URL.

Spotify mantiene dos finalidades separadas:

1. `/auth/social/spotify/*` identifica al usuario con los scopes
   `user-read-email user-read-private`.
2. `/spotify/*` importa gustos para Clash Resolver. Esta conexión requiere una
   sesión FestiSquad previa y no inicia sesión.

## Migración

En una base existente ejecutar:

```text
database/007_phase8_social_auth.sql
```

La migración crea `external_accounts` y `social_auth_flows`, con unicidad por
identidad externa y por proveedor de cada usuario. Una instalación nueva ya
incluye estas tablas en `001_initial_schema.sql`.

## Google Cloud

1. Crear credenciales OAuth 2.0 para una aplicación web.
2. Configurar la pantalla de consentimiento con `openid`, `email` y `profile`.
3. Registrar exactamente este redirect de desarrollo:

```text
http://127.0.0.1:8000/api/v1/auth/social/google/callback
```

4. Completar en `backend/.env`:

```dotenv
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
GOOGLE_REDIRECT_URI=http://127.0.0.1:8000/api/v1/auth/social/google/callback
```

## Spotify Developer Dashboard

Agregar este segundo redirect sin eliminar el callback de Clash Resolver:

```text
http://127.0.0.1:8000/api/v1/auth/social/spotify/callback
```

```dotenv
SPOTIFY_LOGIN_REDIRECT_URI=http://127.0.0.1:8000/api/v1/auth/social/spotify/callback
```

Se reutilizan `SPOTIFY_CLIENT_ID` y `SPOTIFY_CLIENT_SECRET`. En producción todos
los redirects deben utilizar HTTPS y coincidir exactamente con los registrados.

## Comportamiento de vinculación

- Google puede asociar automáticamente una identidad nueva a un usuario local
  con el mismo correo únicamente cuando Google confirma `email_verified`.
- Spotify no expone una afirmación equivalente. Si el correo ya existe, el
  usuario debe iniciar sesión primero y elegir **Vincular Spotify** en su perfil.
- Una identidad externa no puede pertenecer a dos usuarios y un usuario no puede
  vincular dos cuentas diferentes del mismo proveedor.

## Verificación

- Backend: 62 pruebas aprobadas.
- Flutter: 34 pruebas aprobadas.
- `flutter analyze`: sin incidencias.
- Pendiente de aceptación: recorrido real de ambos proveedores después de cargar
  las credenciales privadas y ejecutar la migración en SQL Server.

Referencias oficiales:

- Google OAuth para aplicaciones web:
  https://developers.google.com/identity/protocols/oauth2/web-server
- Google OpenID Connect:
  https://developers.google.com/identity/openid-connect/openid-connect
- Spotify Authorization Code:
  https://developer.spotify.com/documentation/web-api/tutorials/code-flow
