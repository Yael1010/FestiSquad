# Interfaces de FestiSquad

Implementación Flutter de bienvenida (`/login`), inicio (`/dashboard`), unión
al squad (`/join`), mapa (`/map`), fondo común (`/finances`) y Clash Resolver
(`/clash`). La aplicación
utiliza Riverpod para estado e inyección de dependencias, Dio para la API y
almacenamiento seguro para JWT.

## Recorrido funcional

1. Crea una cuenta o inicia sesión desde la pantalla de bienvenida.
2. Flutter guarda access y refresh tokens con `flutter_secure_storage`.
3. Desde Inicio, crea un squad y recibe un código hexadecimal privado de seis
   caracteres.
4. Otro usuario autenticado puede introducir ese código para unirse.
5. La API obtiene la identidad desde el JWT; el cliente no envía `owner_id` ni
   `user_id` en las operaciones de squad.
6. Si expira el access token, Dio intenta una sola renovación con el refresh
   token y repite la petición original.
7. En Fondo común se registra el concepto, pagador, total y participantes. El
   reparto igual conserva todos los centavos y las deudas se simplifican.
8. Sin conexión, el ticket queda visible como pendiente y se reintenta con un
   identificador idempotente para evitar duplicados.
9. Clash Resolver carga empalmes de la agenda, combina las preferencias del
   squad y explica por qué recomienda un escenario.
10. Las preferencias manuales se guardan en Drift y se sincronizan al recuperar
    la conexión. Spotify es opcional y nunca bloquea el flujo manual.

`Explorar demostración` se conserva para revisar el maquetado sin backend. Las
acciones persistentes muestran un error controlado si no existe una sesión o no
hay conectividad.

## Alcance pendiente

Google OAuth, cámara QR y comunicación P2P todavía no están conectados. El QR es
ilustrativo. Spotify OAuth requiere credenciales de una aplicación de Spotify en
el archivo `.env`; si no existen, la interfaz conserva el fallback manual.

## Verificación

Desde `mobile`, ejecutar `flutter test --no-pub` y `dart analyze`. Las pruebas
cubren tres tamaños, texto al 160 %, validación de formularios, códigos inválidos
y unión mediante un repositorio sustituible. Las capturas de referencia están en
`mobile/test/goldens/`.
