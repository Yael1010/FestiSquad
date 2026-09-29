# Fase 11: Fondo Común y liquidación de pagos

## Alcance implementado

- Registro de liquidaciones parciales o completas entre miembros del squad.
- Solo el usuario deudor autenticado puede confirmar su propio pago.
- El backend impide pagar más que el menor valor entre la deuda del pagador y
  el saldo a favor del receptor.
- Operaciones idempotentes mediante `client_request_id`.
- Historial de pagos inmutable y paginado.
- Recálculo de balances y transferencias sugeridas incluyendo liquidaciones.
- Caché Drift, actualización optimista y cola offline para pagos pendientes.
- Nombres reales de integrantes en tickets, deudas e historial.

## Contrato HTTP

- `POST /api/v1/expenses/settlements`
- `GET /api/v1/expenses/squad/{squad_id}/settlements?limit=50&offset=0`

Los importes viajan como cadenas decimales, por ejemplo `"125.50"`.
SQL Server usa `DECIMAL(18,2)`, Python usa `Decimal` y Flutter usa centavos
enteros.

## Migración

En una base existente, ejecutar una sola vez:

```text
database/009_phase11_settlements.sql
```

El script crea `dbo.settlements`, sus restricciones e índices y actualiza
`dbo.fund_balances`. Es idempotente y no borra tickets ni pagos existentes.

## Flujo móvil

1. El usuario abre Fondo Común y consulta las deudas simplificadas.
2. Si una transferencia sugerida sale de su usuario, aparece `Registrar pago`.
3. Confirma el importe, completo o parcial, y puede añadir una nota.
4. Con red, el backend valida el saldo y actualiza el resumen.
5. Sin red, el pago queda marcado como pendiente y se reintenta al recargar.
6. Si el saldo cambió y el servidor rechaza un reintento, se elimina la
   operación optimista inválida y se recalcula el caché.

## Evidencia automatizada

- Backend: precisión decimal, autorización, límite de deuda y DDL SQL Server.
- Flutter: pago offline, persistencia, ajuste de saldos y deuda restante.
