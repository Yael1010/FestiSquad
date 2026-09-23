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
  baja y filtro de distancia de 15 metros. En Android, con el permiso "todo el
  tiempo", continúa al suspender la app mediante un servicio visible y sin
  `wake lock`; se cancela al salir del mapa o al pulsar nuevamente el control.
- Política de envío: primer punto, desplazamiento de al menos 15 metros en
  primer plano; en segundo plano, nunca más de una vez cada 3 minutos.
- Última ubicación propia guardada antes del intento de red. Si el envío falla
  por conexión o error de servidor, se conserva una sola operación pendiente
  por usuario y squad; se reintenta al actualizar el mapa.
- Persistencia web habilitada con los artefactos oficiales compatibles de Drift
  2.31.0 y sqlite3 2.9.4. Flutter sirve el módulo con `application/wasm`.

## Limitaciones explícitas

- El rastreo en segundo plano del MVP está implementado para Android, plataforma
  objetivo del Poco X5 Pro. Web y escritorio suspenden el stream al perder
  visibilidad; no se promete ejecución en segundo plano en navegadores.
- La estimación de consumo menor a 10% por hora requiere medición manual en un
  dispositivo físico de gama media; no se declara validada.
- iOS no está generado en el repositorio actual. Su configuración de permisos y
  `UIBackgroundModes` deberá agregarse cuando esa plataforma entre al alcance.
- El plano de demostración no corresponde a la geometría oficial de un festival.
  Para un recinto real, cargar `festivals` y `stages` en SQL Server y ejecutar
  Flutter con `--dart-define=FESTIVAL_ID=<uuid>`.
- Las ubicaciones usan el canal HTTP local del emulador solo en desarrollo.
  En despliegue debe configurarse HTTPS/TLS y validarse el certificado.

## Pruebas

- Backend: validación de coordenadas/fechas, rechazo de identidad suplantada y
  consulta de última ubicación por integrante.
- Flutter: distancia de 15 metros, intervalo de 3 minutos, interpretación
  GeoJSON, caché aislada por sesión, cola offline acotada, artefactos web y
  layout de teléfono.

## Evidencia de batería pendiente para fase 7

1. Instalar el APK en un Poco X5 Pro o dispositivo de gama media equivalente.
2. Cargar la batería al 100%, desactivar optimizaciones extraordinarias y cerrar
   otras aplicaciones de alto consumo.
3. Activar la ubicación desde el mapa y caminar un recorrido reproducible por
   60 minutos, con al menos 30 minutos de la app en segundo plano.
4. Registrar porcentaje inicial/final, cantidad de envíos del endpoint y captura
   de `adb shell dumpsys batterystats`.
5. El criterio se aprueba con consumo atribuible menor o igual a 10% por hora y
   sin intervalos de envío en segundo plano menores a 3 minutos.

## Referencias técnicas

- [Geolocator](https://pub.dev/packages/geolocator): permisos y stream GPS.
- [Drift Web](https://drift.simonbinder.eu/platforms/web/): binarios y worker
  necesarios para la caché en navegador.
