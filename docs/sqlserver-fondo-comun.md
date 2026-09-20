# FestiSquad: conexión SQL Server y Fondo Común

Paquete incremental basado en `Yael1010/FestiSquad`, rama main, commit
`ec54e992f1c4300b5e10b512d6912c2f60849537`, consultado el 17/09/2026.
Contiene configuración, modelos, servicio persistente, SQL y pruebas. Copiar sus
carpetas `backend` y `database` sobre las del repositorio conservando lo existente.
No se ha publicado ningún cambio en GitHub.

## Decisiones del modelo

| Entidad | Función |
|---|---|
| users | Usuario, correo único y hash de contraseña; nunca contraseña en texto |
| squads | Grupo privado y propietario |
| squad_members | Relación N:M usuarios/grupos, clave compuesta |
| expenses | Ticket/gasto: pagador, grupo, concepto, importe y fecha UTC |
| expense_participants | Cuota individual, clave compuesta ticket/usuario |
| fund_balances | Vista calculada: lo pagado menos lo consumido por usuario/grupo |

El esquema preserva las cinco tablas existentes y su normalización en 3FN.
Un usuario puede pagar un ticket sin consumir parte de él. Un participante solo
puede aparecer una vez por ticket. Las cuotas deben ser positivas, de acuerdo
con la restricción ya existente. El ticket es el registro lógico del gasto;
captura de imágenes/OCR y almacenamiento de archivos quedan fuera de este paso.

Supuesto explícito para este MVP: todos los importes son MXN. No mezclar monedas;
para habilitar varias, añadir moneda por grupo/gasto y agrupar también por moneda.
No es todavía una caja con depósitos ni un registro de pagos de liquidación:
las transferencias calculadas son sugerencias, no pagos ejecutados o confirmados.

## 1. Preparar SQL Server

Necesitas SQL Server con TCP/IP habilitado y puerto accesible (el ejemplo usa
1433), una base `FestiSquad`, un usuario de aplicación con permisos mínimos sobre
las tablas/vista y Microsoft ODBC Driver 18 instalado. `pip install pyodbc` no
instala ese controlador del sistema. Usa una cuenta de migraciones separada para DDL.

En SQL Server Management Studio crea una base vacía si aún no existe:

```sql
CREATE DATABASE FestiSquad;
```

Selecciona esa base. Para el repositorio completo, ejecuta su
`database/001_initial_schema.sql` **solo si aún no se aplicó**. Después ejecuta
el nuevo `database/002_fund_balances.sql`. No vuelvas a crear tablas existentes.

Se incluye `database/fund_schema_reference.sql` como DDL autónomo del módulo,
generado a partir de los modelos. Es una alternativa para una base de pruebas
vacía dedicada al módulo, NO otra migración que ejecutar después de `001`.

## 2. Dependencias y variables (PowerShell)

Desde la raíz de tu repositorio:

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements-database.txt
```

Integra las variables de `.env.database.example` en `backend/.env` sin borrar las
de JWT/Spotify. Rellena DB_USER y DB_PASSWORD localmente. La conexión nueva utiliza
las variables DB_*, no el antiguo DATABASE_URL de ejemplo. Evita subir `.env` a Git.
Para un certificado autofirmado, DB_TRUST_SERVER_CERTIFICATE=true se permite solo
en development/test. En staging/production se valida el certificado y siempre se
solicita cifrado. Para instancias nombradas configura un puerto TCP fijo y úsalo
en DB_PORT; el ejemplo no depende del descubrimiento de SQL Browser.

## 3. Verificar conexión FastAPI

```powershell
python -m uvicorn app.db_probe:app --reload
```

Consulta `http://127.0.0.1:8000/health/db`. Debe responder:

```json
{"status":"ok","database":"sqlserver"}
```

Un fallo SQL responde 503 con un código estable sin filtrar conexión/credenciales.
La app de diagnóstico usa la misma dependencia get_db que usarán los endpoints.
Para incorporarla a la API principal, importa `router` desde `app.db_probe` y llama
`app.include_router(router)` dentro de `create_app`; integra `dispose_engine()` en
el cierre de su lifespan. Conserva el router `/api/v1` existente.

Las operaciones pyodbc son síncronas: usa endpoints `def` para que FastAPI las
ejecute fuera del event loop. El pool valida conexiones al reutilizarlas. No se
crean tablas al iniciar la API. Los timeouts de 5/10 segundos son límites de fallo,
no evidencia de cumplir el objetivo de respuesta <1.5 s: medir con SQL Server real.

## 4. Registrar un ticket y calcular deudas

El servicio nuevo está en `app/domains/finances/db_service.py`. Recibe una Session
y `actor_id` obtenido del JWT verificado. Comprueba que actor, pagador y participantes
pertenezcan al grupo; inserta ticket/cuotas en una transacción. Ante fallo revierte
todo. Usa SERIALIZABLE para mantener coherencia entre validación y operación; medir
contención bajo carga antes de cambiar aislamiento. No reintentar escrituras a
ciegas: aún falta una clave de idempotencia para sincronización móvil offline.

Ejemplo de uso interno (sustituye IDs por usuarios y grupos existentes en SQL):

```python
from uuid import UUID
from sqlalchemy.orm import Session
from app.core.database import get_engine
from app.domains.finances.db_schemas import ExpenseInput
from app.domains.finances.db_service import DatabaseFinanceService

payload = ExpenseInput.model_validate({
    "squad_id": "00000000-0000-0000-0000-000000000010",
    "paid_by_user_id": "00000000-0000-0000-0000-000000000001",
    "description": "Transporte al festival",
    "amount": "100.00",
    "participants": [
        {"user_id": "00000000-0000-0000-0000-000000000001", "share_amount": "33.34"},
        {"user_id": "00000000-0000-0000-0000-000000000002", "share_amount": "33.33"},
        {"user_id": "00000000-0000-0000-0000-000000000003", "share_amount": "33.33"}
    ]
})
actor_id = UUID("00000000-0000-0000-0000-000000000001")  # En HTTP: JWT verificado.
service = DatabaseFinanceService()
with Session(get_engine(), expire_on_commit=False) as db:
    expense_id = service.create_expense(db, payload, actor_id)
    result = service.balances_for_squad(db, payload.squad_id, actor_id)
    print(result.model_dump_json())
```

Saldo = total pagado − suma de cuotas. Positivo: debe recibir; negativo: debe pagar.
En el ejemplo, A recibe 66.66; B y C pagan 33.33 cada uno. `split_equal` reparte
centavos sobrantes de manera determinista por UUID. `suggest_transfers` compensa
saldos cruzados y los deja en cero, sin afirmar un mínimo global de transferencias.

DECIMAL(18,2) se usa en SQL y `Decimal` en Python. El JSON usa cadenas (`"100.00"`),
nunca números flotantes. La validación rechaza floats, más de dos decimales,
NaN/infinito, importes fuera del rango, duplicados y sumas incorrectas. Las sumas
SQL se amplían a DECIMAL(38,2) para acumular tickets sin reducir la precisión.

## Integración pendiente y límites de este paso

El servicio original `FinanceService` sigue guardando gastos en memoria. Este
paquete no cambia sus rutas ni migra automáticamente usuarios/squads de memoria.
Para activar los endpoints financieros persistentes hay que conectar autenticación
y squads a las mismas tablas, inyectar get_db y usar DatabaseFinanceService.
No aceptar un actor_id enviado por el cliente ni exponer rutas financieras sin JWT.
Traducir PermissionError a 403, errores de validación a 422 y fallos de base a una
respuesta tipada; devolver BalanceOutput para conservar los importes como cadenas.

La base impone PK/FK, unicidad y positividad; la pertenencia al squad y la igualdad
entre el total y la suma de cuotas se garantizan en este servicio transaccional.
Las escrituras SQL directas pueden saltarse esas dos reglas. No presentar el
esquema como si un CHECK validara sumas entre filas. Si habrá otros escritores,
centralizar las escrituras en un procedimiento y restringir permisos directos.

## Verificación

Desde backend: `python -m pytest tests/test_database_finances.py -q`.
Pruebas de aritmética, validación, serialización, TLS y compilación del DDL MSSQL.
No sustituyen una prueba de integración contra SQL Server: quedan por comprobar
ODBC/certificados, permisos, rollback real, consultas concurrentes y latencia.

Fuentes técnicas:
- https://docs.sqlalchemy.org/en/20/dialects/mssql.html
- https://fastapi.tiangolo.com/tutorial/dependencies/dependencies-with-yield/
- https://github.com/Yael1010/FestiSquad/blob/main/database/001_initial_schema.sql
