# Fase 14: Fotos de Perfil

Cada usuario puede seleccionar una foto desde la galería mediante el icono de
edición sobre su avatar en el dashboard. Flutter reduce la imagen antes de
enviarla; FastAPI valida firma binaria JPEG, PNG o WebP y rechaza cargas de más
de 5 MB.

La migración `database/011_phase14_profile_avatars.sql` añade
`users.avatar_url`. La API guarda rutas relativas bajo `backend/storage/avatars`
y las publica temporalmente en `/media/avatars`. Esa carpeta está en
`.gitignore`: nunca debe subirse al repositorio.

La foto personalizada tiene prioridad sobre la foto de Google o Spotify. El
endpoint de integrantes de un squad devuelve esa foto, por lo que cualquier
cuenta que comparta el squad la ve al abrir o actualizar la lista de miembros.
En producción, el adaptador local de archivos debe reemplazarse por un almacén
de objetos privado, como Azure Blob Storage, conservando el mismo contrato de
`avatar_url`.
