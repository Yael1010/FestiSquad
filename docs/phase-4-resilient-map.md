# Fase 4: mapa resiliente

## Implementado

- Polígonos del festival y escenarios renderizados localmente; el plano se puede
  ampliar y mover sin tiles ni conexión.
- Endpoint autenticado `GET /api/v1/festivals/{festival_id}` para geometría
  almacenada en SQL Server. La app usa `FESTIVAL_ID` al compilar; sin él,
  muestra un recinto claramente identificado como demostración.
- Ubicaciones persistentes en SQL Server, con consulta de la última por miembro.
  El servidor obtiene la identidad del JWT y exige pertenecer al squad.
- Puntos de encuentro persistentes y protegidos por membresía.
- Caché Drift de geometría, escenarios, ubicaciones y puntos de encuentro.
  La migración SQLite de versión 1 a 2 conserva la caché previa de squads.
- GPS solicitado solo al pulsar el control de ubicación. El stream usa precisión
  baja y filtro de distancia de 15 metros, y se cancela al salir de la pantalla
  o al suspender la app.
- Política de envío: primer punto, desplazamiento de al menos 15 metros en
  primer plano; en segundo plano, nunca más de una vez cada 3 minutos.
- Última ubicación propia guardada antes del intento de red. Si el envío falla
  por conexión o error de servidor, se conserva una sola operación pendiente
  por usuario y squad; se reintenta al actualizar el mapa.

## Limitaciones explícitas

- No hay servicio nativo de rastreo en segundo plano. La app suspende el GPS al
  perder visibilidad. La regla de 3 minutos está implementada y probada como
  política, pero todavía no existe una tarea background que la utilice.
- La estimación de consumo menor a 10% por hora requiere medición manual en un
  dispositivo físico de gama media; no se declara validada.
- Flutter Web requiere `web/sqlite3.wasm` de sqlite3 2.9.4 y
  `web/drift_worker.js` de Drift 2.31.0 para persistencia local. La descarga de
  esos binarios no fue autorizada en esta iteración, así que el mapa con sesión
  y caché web queda pendiente. Android es el objetivo funcional de esta fase.
- El plano de demostración no corresponde a la geometría oficial de un festival.
  Para un recinto real, cargar `festivals` y `stages` en SQL Server y ejecutar
  Flutter con `--dart-define=FESTIVAL_ID=<uuid>`.
- Las ubicaciones usan el canal HTTP local del emulador solo en desarrollo.
  En despliegue debe configurarse HTTPS/TLS y validarse el certificado.

## Pruebas

- Backend: validación de coordenadas/fechas, rechazo de identidad suplantada y
  consulta de última ubicación por integrante.
- Flutter: distancia de 15 metros, intervalo de 3 minutos, interpretación
  GeoJSON, caché aislada por sesión, cola offline acotada y layout de teléfono.

## Referencias técnicas

- [Geolocator](https://pub.dev/packages/geolocator): permisos y stream GPS.
- [Drift Web](https://drift.simonbinder.eu/platforms/web/): binarios y worker
  necesarios para la caché en navegador.
