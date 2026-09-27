# Fase 10: Catálogo y mapas de festivales

## Alcance implementado

- Catálogo autenticado de festivales publicados, ordenado por fecha.
- Selección del festival antes de abrir el mapa.
- Caché offline-first del catálogo, geometría y escenarios.
- Datos editoriales de recinto, ciudad, país, zona horaria, sitio oficial y
  estado `draft`, `published` o `archived`.
- Administración protegida por el atributo `users.is_platform_admin`.
- Alta y edición de festivales y escenarios con polígonos GeoJSON.
- Archivado lógico de festivales para conservar referencias históricas.
- Validación de fechas, rangos geográficos y cierre de polígonos.
- Pantalla Flutter administrativa para registrar y publicar un festival.

No se incluyen coordenadas inventadas. Los mapas deben cargarse desde datos
oficiales o levantamientos autorizados del organizador del festival.

## Preparación de SQL Server

Ejecutar `database/008_phase10_festival_catalog.sql` y después habilitar una
cuenta existente como administradora:

```sql
UPDATE dbo.users
SET is_platform_admin = 1
WHERE email = 'correo-del-administrador@example.com';
```

## Formato GeoJSON

El backend acepta polígonos simples, cerrados y en orden
`[longitud, latitud]`:

```json
{
  "type": "Polygon",
  "coordinates": [[
    [-99.1800, 19.4000],
    [-99.1700, 19.4000],
    [-99.1700, 19.3900],
    [-99.1800, 19.4000]
  ]]
}
```

Los escenarios de la pantalla administrativa se ingresan como una lista:

```json
[
  {
    "name": "Escenario principal",
    "polygon": {
      "type": "Polygon",
      "coordinates": [[
        [-99.1760, 19.3970],
        [-99.1750, 19.3970],
        [-99.1750, 19.3960],
        [-99.1760, 19.3970]
      ]]
    }
  }
]
```

## Endpoints

- `GET /api/v1/festivals`
- `GET /api/v1/festivals/{festival_id}`
- `GET /api/v1/festivals/admin/access`
- `GET /api/v1/festivals/admin/catalog`
- `POST /api/v1/festivals`
- `PATCH /api/v1/festivals/{festival_id}`
- `DELETE /api/v1/festivals/{festival_id}`
- `POST /api/v1/festivals/{festival_id}/stages`
- `PATCH /api/v1/festivals/{festival_id}/stages/{stage_id}`
- `DELETE /api/v1/festivals/{festival_id}/stages/{stage_id}`

## Criterios de calidad

- Un usuario normal puede leer festivales publicados, pero no modificarlos.
- Borradores y archivados solo son visibles para administradores.
- El catálogo guardado permanece visible sin red.
- Un mapa abierto previamente conserva sus polígonos sin conexión.
- La pantalla de catálogo se valida en un viewport móvil compacto.
