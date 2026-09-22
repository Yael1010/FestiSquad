# Fase 3: Persistencia local y modelo relacional

## Alcance implementado

- Modelo SQL Server revisado en tercera forma normal.
- Migración conservadora para bases creadas en Fase 2.
- Índices alineados con las consultas críticas del MVP.
- Base local Drift/SQLite versionada.
- Caché local de squads separada por usuario autenticado.
- Entidades locales preparadas para festivales, ubicaciones y puntos de encuentro.
- Cola local de operaciones pendiente para la sincronización de fases posteriores.
- Repositorio de squads con lectura local y actualización remota en segundo plano.
- Creación y unión a squads almacenadas localmente después de la confirmación del servidor.

## Flujo offline-first

1. El repositorio identifica al usuario de la sesión segura.
2. Si existen squads locales, los entrega inmediatamente y solicita una actualización
   remota en segundo plano.
3. Si no existe caché, consulta FastAPI y persiste el resultado antes de entregarlo.
4. Si la actualización remota falla, conserva el último dato válido y la interfaz
   informa que está mostrando información guardada.
5. Las escrituras que requieren autoridad del servidor, como crear o unirse a un
   squad, no se simulan offline para evitar códigos o membresías inconsistentes.

## Decisiones

- La caché usa SQLite mediante Drift para obtener esquema tipado, migraciones y
  pruebas en memoria.
- Los tokens permanecen en almacenamiento seguro; nunca se copian a SQLite.
- Los datos se particionan por `session_user_id` para impedir que una cuenta vea el
  caché de otra cuenta en el mismo dispositivo.
- Ubicaciones usan números reales localmente porque no representan dinero. Los
  importes financieros seguirán usando centavos enteros en Flutter.
- La cola `pending_sync_operations` se crea en esta fase, pero su procesamiento se
  conectará en las fases de mapa y finanzas, cuando estén definidos los conflictos
  y reglas de reintento de cada dominio.

## Ejecución

Para actualizar una base SQL Server existente:

```text
database/003_phase3_normalization_and_indexes.sql
```

Para regenerar el código Drift después de cambiar tablas locales:

```powershell
dart run build_runner build --delete-conflicting-outputs
```

## Evidencia de validación

- `flutter analyze`: sin observaciones.
- `flutter test`: 12 pruebas aprobadas, incluidas lectura remota inicial,
  persistencia SQLite, fallback offline y aislamiento de caché por usuario.
- `flutter build web --no-pub`: compilación completada.
- `pytest`: 32 pruebas aprobadas, incluidas cinco validaciones del esquema de
  Fase 3.
- La migración 003 se aplicó en SQL Server y se ejecutó una segunda vez para
  validar su comportamiento idempotente.
- La conexión SQLAlchemy con las credenciales de la aplicación continuó
  operativa después de la migración.
