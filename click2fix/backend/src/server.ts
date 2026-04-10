import http from 'http';
import { createApp } from './app';
import { config } from './config';
import { configureSockets } from './sockets';

const app = createApp();
const server = http.createServer(app);

configureSockets(server);

server.listen(config.port, () => {
  console.log(`Click2Fix backend listening on port ${config.port}`);
});

process.on('SIGTERM', () => {
  server.close(() => process.exit(0));
});

