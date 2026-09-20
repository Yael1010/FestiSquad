# Fase 2: Autenticación y Squads

## Implementado

- Registro y login persistentes en SQL Server mediante SQLAlchemy.
- Contraseñas almacenadas como hash bcrypt; `bcrypt==4.0.1` se fija por
  compatibilidad con Passlib 1.7.4.
- JWT separados por tipo `access` y `refresh`, con expiración configurable.
- Endpoint autenticado `GET /api/v1/auth/me`.
- Creación de squads con código privado hexadecimal de seis caracteres.
- El creador se registra como `admin`; las uniones posteriores como `member`.
- Unión idempotente: repetir el mismo código no duplica la membresía.
- Identidad tomada exclusivamente del JWT para impedir suplantar propietario o
  miembro desde el cuerpo JSON.
- Validación de membresía aplicada a lectura de squads, ubicaciones y balances.
- CORS limitado a localhost en desarrollo y configurable por lista en otros
  ambientes.
- Flutter guarda la sesión en almacenamiento seguro, restaura la sesión, renueva
  tokens una vez ante un 401 y permite cerrar sesión.

## Configuración

Crear `backend/.env` a partir de `.env.example`. Ejecutar primero
`database/001_initial_schema.sql` en SQL Server y después iniciar FastAPI.

En emulador Android, Flutter usa `http://10.0.2.2:8000/api/v1`. En web y Windows
usa `http://127.0.0.1:8000/api/v1`. Puede sobrescribirse con:

```powershell
flutter run --dart-define=API_BASE_URL=https://api.example.com/api/v1
```

## Evidencia

- Backend: 27 pruebas aprobadas.
- Flutter: 8 pruebas de interfaz y comportamiento aprobadas.
- `dart analyze`: sin observaciones.

La comprobación contra una instancia SQL Server real requiere credenciales
locales y la ejecución previa de los scripts versionados.
