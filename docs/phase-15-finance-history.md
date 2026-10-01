# Fase 15: Historial Financiero

Los tickets y pagos sincronizados no se eliminan físicamente. Se anulan con
estado `cancelled`, usuario responsable y fecha de anulación. Solo el pagador o
un administrador del squad puede realizar la operación. La vista
`fund_balances` excluye registros anulados para recalcular deudas exactas.

Flutter separa movimientos activos e historial, muestra cinco registros por
bloque y permite ampliar la lista. Los borradores todavía no sincronizados sí
pueden eliminarse localmente junto con su operación pendiente.

Antes de iniciar la API debe ejecutarse
`database/012_phase15_finance_history.sql` sobre la base FestiSquad.
