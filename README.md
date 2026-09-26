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
```

Si la base fue creada durante una fase anterior, ejecutar las migraciones
idempotentes que todavía no se hayan aplicado:

```text
database/003_phase3_normalization_and_indexes.sql
database/004_phase5_expense_idempotency.sql
database/005_phase6_music_preferences.sql
```

## Inicio rápido Flutter

```bash
cd mobile
flutter pub get
flutter run
```

Flutter conserva localmente los squads con Drift/SQLite. Los tokens JWT se
mantienen separados en el almacenamiento seguro del dispositivo.

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

El mapa funciona en Android con permiso de ubicación bajo demanda. Para usar un
festival real, registra su geometría en SQL Server y agrega
`--dart-define=FESTIVAL_ID=<uuid>` al comando `flutter run`. Sin ese valor se
muestra un plano de demostración. Ver [Fase 4](docs/phase-4-resilient-map.md)
para los límites del modo web y del rastreo en segundo plano.

## Alcance MVP

- Registro, login y sesión JWT.
- Creación y unión a squads mediante código privado.
- Mapa offline-first con última ubicación conocida y throttling GPS.
- Fondo común con cálculo exacto de deudas cruzadas.
- Clash Resolver con Spotify OAuth 2.0, recomendación grupal y fallback manual.
