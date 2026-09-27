# FestiSquad

FestiSquad es una aplicación móvil multiplataforma para resolver logística, ubicación resiliente, comunicación operativa y finanzas compartidas entre grupos de amigos durante festivales musicales masivos.

## Stack

- **Mobile:** Flutter + Riverpod, con enfoque offline-first.
- **Backend:** FastAPI modular bajo `/api/v1`.
- **Base de datos:** Microsoft SQL Server en 3FN.
- **Calidad:** pruebas automatizadas, documentación técnica y reglas explícitas de seguridad, rendimiento y batería.

## Estructura

```text
backend/   API FastAPI, dominios y pruebas
database/  scripts SQL Server
docs/      arquitectura, decisiones y evidencias
mobile/    aplicación Flutter
```

## Inicio rápido backend

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Documentación local: `http://127.0.0.1:8000/docs`

## Base de datos

En una instalación nueva, ejecutar en SQL Server y en este orden:

```text
database/001_initial_schema.sql
database/002_fund_balances.sql
database/003_phase3_normalization_and_indexes.sql
database/004_phase5_expense_idempotency.sql
database/005_phase6_music_preferences.sql
database/007_phase8_social_auth.sql
database/008_phase10_festival_catalog.sql
```

Si la base fue creada durante una fase anterior, ejecutar las migraciones
idempotentes que todavía no se hayan aplicado:

```text
database/003_phase3_normalization_and_indexes.sql
database/004_phase5_expense_idempotency.sql
database/005_phase6_music_preferences.sql
database/007_phase8_social_auth.sql
database/008_phase10_festival_catalog.sql
```

## Inicio rápido Flutter

```bash
cd mobile
flutter pub get
flutter run
```

Para un build release se debe proporcionar un endpoint HTTPS:

```bash
flutter build apk --dart-define=API_BASE_URL=https://api.example.com/api/v1
```

Flutter conserva localmente los squads con Drift/SQLite. Los tokens JWT se
mantienen separados en el almacenamiento seguro del dispositivo.

La tarjeta del squad activo abre su lista de integrantes. Los administradores
pueden gestionar roles y expulsiones; el propietario también puede transferir
la propiedad o eliminar el squad. Los perfiles se conservan en caché para su
consulta sin red. Consulta [Fase 9](docs/phase-9-squad-members.md) para las
reglas de autorización.

El fondo común conserva tickets y balances en caché, acepta divisiones iguales
entre participantes seleccionados y reintenta los tickets creados sin conexión.
Los importes viajan como cadenas decimales, se procesan con `Decimal` en FastAPI
y se guardan como `DECIMAL(18,2)` en SQL Server.

Clash Resolver conserva preferencias manuales y resultados recientes en Drift.
Para conectar Spotify, crea una aplicación en Spotify Developer Dashboard,
registra como callback `http://127.0.0.1:8000/api/v1/spotify/callback` y completa
`SPOTIFY_CLIENT_ID`, `SPOTIFY_CLIENT_SECRET` y `SPOTIFY_REDIRECT_URI` en
`backend/.env`. Los tokens de Spotify se usan para importar gustos y no se
persisten.

El acceso social utiliza callbacks independientes. Registra en Google Cloud
`http://127.0.0.1:8000/api/v1/auth/social/google/callback` y agrega en Spotify
`http://127.0.0.1:8000/api/v1/auth/social/spotify/callback`, conservando también
el callback musical anterior. Configura las variables `GOOGLE_*` y
`SPOTIFY_LOGIN_REDIRECT_URI` descritas en `backend/.env.example`. Consulta
[Fase 8](docs/phase-8-social-auth.md) para el procedimiento y el modelo de
vinculación.

El mapa funciona en Android con permiso de ubicación bajo demanda. El catálogo
permite seleccionar festivales publicados y conserva sus geometrías para uso
sin conexión. La carga administrativa y el formato GeoJSON se documentan en
[Fase 10](docs/phase-10-festival-catalog.md). Ver también
[Fase 4](docs/phase-4-resilient-map.md) para los límites del modo web y del
rastreo en segundo plano.

## Calidad y RNF

```bash
cd backend
pytest -q
python scripts/benchmark_api.py --url http://127.0.0.1:8000/health/db

cd ../mobile
flutter analyze
flutter test

cd ..
powershell -ExecutionPolicy Bypass -File tools/check_secrets.ps1
```

La configuración de proxy TLS está en `deploy/nginx/festisquad.conf`. El
procedimiento y las evidencias pendientes de ambiente físico están documentados
en [Fase 7](docs/phase-7-quality-evidence.md).

## Alcance MVP

- Registro, login tradicional y acceso social con Google o Spotify.
- Creación y unión a squads mediante código privado.
- Mapa offline-first con última ubicación conocida y throttling GPS.
- Fondo común con cálculo exacto de deudas cruzadas.
- Clash Resolver con Spotify OAuth 2.0, recomendación grupal y fallback manual.
