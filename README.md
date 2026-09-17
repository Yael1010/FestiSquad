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

## Inicio rápido Flutter

```bash
cd mobile
flutter pub get
flutter run
```

## Alcance MVP

- Registro, login y sesión JWT.
- Creación y unión a squads mediante código privado.
- Mapa offline-first con última ubicación conocida y throttling GPS.
- Fondo común con cálculo exacto de deudas cruzadas.
- Clash Resolver con preferencias musicales manuales y preparación para Spotify OAuth 2.0.

