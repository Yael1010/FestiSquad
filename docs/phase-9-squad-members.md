# Fase 9: Miembros, perfiles y roles

## Objetivo

Completar la administración de squads con una vista offline-first de sus
integrantes y reglas de autorización verificables en el backend.

## Funcionalidad implementada

- Consulta de integrantes con nombre, avatar social, rol, fecha de ingreso y
  hora de la última ubicación registrada.
- Caché local de integrantes separado por sesión y squad.
- Promoción y degradación entre los roles `admin` y `member`.
- Expulsión de integrantes por administradores.
- Salida voluntaria para integrantes que no sean propietarios.
- Transferencia de propiedad antes de que el propietario abandone el squad.
- Eliminación definitiva del squad reservada a su propietario.
- Acceso desde la tarjeta de squad activo en el dashboard.

Las coordenadas no se incluyen en el perfil del integrante. La pantalla solo
muestra cuándo se recibió su última ubicación, reduciendo la exposición de
datos sensibles fuera del módulo de mapa.

## Reglas de autorización

| Acción | Miembro | Administrador | Propietario |
| --- | --- | --- | --- |
| Ver integrantes | Sí | Sí | Sí |
| Abandonar squad | Sí | Sí, si no es propietario | No |
| Cambiar roles | No | Sí | Sí |
| Expulsar integrante | No | Sí | Sí |
| Transferir propiedad | No | No | Sí |
| Eliminar squad | No | No | Sí |

El rol del propietario está bloqueado. Para salir debe transferir primero la
propiedad o eliminar el squad.

## Endpoints

- `GET /api/v1/squads/{squad_id}/members`
- `PATCH /api/v1/squads/{squad_id}/members/{user_id}`
- `DELETE /api/v1/squads/{squad_id}/members/{user_id}`
- `POST /api/v1/squads/{squad_id}/owner/{user_id}`
- `DELETE /api/v1/squads/{squad_id}`

## Evidencia automatizada

- Servicios backend: permisos, protección del propietario, transferencia y
  salida voluntaria.
- Flutter: persistencia local de perfiles y lectura sin conexión.
- Análisis estático y suites completas de backend y Flutter.
