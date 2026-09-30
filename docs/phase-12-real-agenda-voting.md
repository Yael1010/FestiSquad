# Fase 12: Agenda real, votación y decisión grupal

## Alcance implementado

- La creación administrativa de festivales acepta una agenda asociada a los
  escenarios creados en la misma operación.
- La API permite consultar, crear, sustituir y eliminar horarios individuales.
- Clash Resolver puede abrirse para un festival específico desde el catálogo.
- Los empalmes reciben una identidad SHA-256 estable basada en sus horarios.
- Cada integrante puede mantener un solo voto por empalme.
- Los votos del squad se incorporan con peso explícito a la recomendación.
- Un administrador del squad puede confirmar o cambiar la decisión final.
- Flutter muestra votos, selección personal y decisión confirmada.
- Un voto realizado sin conexión se aplica localmente y queda en la cola de
  sincronización; el último voto reemplaza los anteriores del mismo empalme.

## Migración SQL Server

Ejecutar una vez, después de las migraciones anteriores:

```sql
database/010_phase12_clash_voting.sql
```

La migración crea `clash_votes` y `clash_decisions`, agrega claves foráneas y
valida que cada horario termine después de comenzar.

## Formato de agenda

El campo `schedule` usa el nombre de un escenario incluido en `stages`:

```json
[
  {
    "stage_name": "Escenario Norte",
    "artist_name": "Las Luces",
    "starts_at": "2026-10-17T20:00:00-06:00",
    "ends_at": "2026-10-17T21:00:00-06:00",
    "genres": ["indie", "rock"]
  }
]
```

## Endpoints

- `GET /api/v1/festivals/{festival_id}/schedule`
- `POST /api/v1/festivals/{festival_id}/schedule`
- `PUT /api/v1/festivals/{festival_id}/schedule/{item_id}`
- `DELETE /api/v1/festivals/{festival_id}/schedule/{item_id}`
- `GET /api/v1/clash-resolver/conflicts?squad_id=...&festival_id=...`
- `PUT /api/v1/clash-resolver/votes`
- `PUT /api/v1/clash-resolver/decision`

## Reglas

- El horario debe pertenecer a un escenario del festival y quedar dentro de su
  periodo oficial.
- Votar requiere pertenecer al squad.
- Votar por otra opción reemplaza el voto anterior del usuario en ese empalme.
- Confirmar la decisión requiere rol `admin` del squad.
- La recomendación considera preferencias manuales, Spotify y votos, pero la
  decisión final permanece explícita y auditable.
