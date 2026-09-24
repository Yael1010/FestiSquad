# Fase 5: fondo común

## Implementado

- Persistencia real de tickets y participantes en SQL Server.
- Importes `DECIMAL(18,2)` en SQL Server, `Decimal` en Python y centavos enteros
  en el dominio Flutter. Los contratos JSON usan cadenas decimales.
- Validación de suma exacta, participantes únicos y pertenencia al squad.
- Creación idempotente mediante `client_request_id` para reintentos offline.
- Listado paginado de tickets y cálculo de balances desde `fund_balances`.
- Compensación determinista de acreedores/deudores para reducir transferencias.
- Formulario Flutter con pagador, total y selección de participantes.
- División igual con distribución estable de centavos sobrantes.
- Caché Drift de tickets, balances y transferencias, más cola de creación offline.
- Estados visibles de caché y sincronización pendiente sin bloquear la interfaz.

## Endpoints

- `POST /api/v1/expenses`
- `GET /api/v1/expenses/squad/{squad_id}?limit=50&offset=0`
- `GET /api/v1/expenses/squad/{squad_id}/balances`

Todas las rutas requieren JWT y pertenencia al squad.

## Base de datos

- Instalación nueva: ejecutar `001`, `002`, `003` y `004` en orden.
- Base existente: ejecutar `004_phase5_expense_idempotency.sql` con una cuenta
  que tenga permiso `ALTER` sobre `dbo.expenses`.
- El usuario de aplicación solo necesita permisos DML; no debe recibir permisos
  de modificación de esquema en producción.

## Evidencia

- Backend: validación monetaria, DDL `DECIMAL`, compensación, transacción y
  pertenencia de participantes.
- Flutter: parsing sin truncamiento, reparto exacto de centavos, cola offline y
  balance optimista.
- SQL Server local: columna e índice idempotente y vista de balances verificados.
