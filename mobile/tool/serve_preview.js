const fs = require('fs');
const http = require('http');
const path = require('path');

const host = '127.0.0.1';
const port = Number(process.env.FESTISQUAD_PREVIEW_PORT || 53127);
const root = path.resolve(__dirname, '..', 'build', 'web');

const contentTypes = {
  '.css': 'text/css; charset=utf-8',
  '.html': 'text/html; charset=utf-8',
  '.ico': 'image/x-icon',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.wasm': 'application/wasm',
};

function sendFile(filePath, response) {
  fs.readFile(filePath, (error, contents) => {
    if (error) {
      response.writeHead(500);
      response.end('No se pudo leer la compilacion web.');
      return;
    }

    response.writeHead(200, {
      'Content-Type': contentTypes[path.extname(filePath)] ||
          'application/octet-stream',
      'Cache-Control': 'no-store',
    });
    response.end(contents);
  });
}

const server = http.createServer((request, response) => {
  const pathname = decodeURIComponent(new URL(request.url, `http://${host}`).pathname);
  const requestedPath = pathname === '/' ? 'index.html' : pathname.slice(1);
  const filePath = path.resolve(root, requestedPath);

  if (!filePath.startsWith(root)) {
    response.writeHead(403);
    response.end('Ruta no permitida.');
    return;
  }

  fs.stat(filePath, (error, stats) => {
    if (!error && stats.isFile()) {
      sendFile(filePath, response);
      return;
    }

    sendFile(path.join(root, 'index.html'), response);
  });
});

server.listen(port, host, () => {
  console.log(`FestiSquad disponible en http://${host}:${port}`);
});
