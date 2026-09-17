# Reglas de Calidad

## Seguridad

- JWT firmado con secreto seguro por ambiente.
- HTTPS obligatorio fuera de desarrollo local.
- Tokens móviles en almacenamiento seguro.
- Datos de ubicación cifrados en tránsito.

## Rendimiento

- Objetivo de respuesta FastAPI: menos de 1.5 segundos en casos normales.
- Índices para email, códigos de squad, ubicaciones recientes y gastos.
- Listados paginados cuando crezcan.

## Batería

- El GPS solo se sincroniza si hay desplazamiento mayor a 15 metros.
- En segundo plano se limita a máximo un envío cada 3 minutos.
- Evitar polling constante y tareas de fondo innecesarias.

## Tolerancia a fallos

- Flutter debe conservar estado útil desde caché.
- Pérdidas de red se muestran como estados offline, no como crashes.
- Reintentos controlados y errores globales tipados.

