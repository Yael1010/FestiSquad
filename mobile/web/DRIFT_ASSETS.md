# Artefactos web de Drift

Estos archivos permiten que la caché SQLite funcione en Flutter Web. Deben
mantenerse alineados con las versiones resueltas en `pubspec.lock`.

| Archivo | Versión | SHA-256 |
| --- | --- | --- |
| `drift_worker.js` | Drift 2.31.0 | `f0a9b87085f732fd7b6ee7eb34d3858c556f05d221eb1febfc443649cd365752` |
| `sqlite3.wasm` | sqlite3 2.9.4 | `922a76b182b6af69b030c8e2fdd3283ecc8e827248b20e4b1f3f3db170b52117` |

Fuentes oficiales:

- <https://github.com/simolus3/drift/releases/tag/drift-2.31.0>
- <https://github.com/simolus3/sqlite3.dart/releases/tag/sqlite3-2.9.4>

Ambos proyectos publican estos artefactos con licencia MIT. Al actualizar Drift
o sqlite3, se deben reemplazar los binarios, actualizar los hashes y ejecutar
`flutter test` y `flutter build web`.
