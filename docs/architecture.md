# Arquitectura de FestiSquad

## Vista general

FestiSquad se organiza como monorepo para simplificar la evaluación académica y mantener juntas las evidencias de calidad:

- `mobile`: app Flutter offline-first.
- `backend`: API FastAPI modular.
- `database`: scripts SQL Server.
- `docs`: decisiones técnicas y evidencias.

## Frontend

La app usa una arquitectura por feature con capas `data`, `domain` y `presentation`. Riverpod será el punto de composición para estado, repositorios y servicios.

La estrategia offline-first es:

1. leer primero datos locales;
2. mostrar estado funcional aunque no haya red;
3. sincronizar con backend cuando vuelva la conectividad;
4. reportar estados de error sin crashear.

## Backend

FastAPI expone endpoints bajo `/api/v1`. Cada módulo tiene schemas, servicios y routers separados. La implementación inicial usa servicios en memoria para acelerar el bootstrap; la siguiente iteración conectará repositorios SQL Server sin cambiar los contratos públicos.

## Datos

SQL Server mantiene el modelo normalizado en 3FN. Finanzas usa `DECIMAL(18,2)` y ubicación usa `DECIMAL` para coordenadas. No se permite `FLOAT` ni `REAL` para importes monetarios.

