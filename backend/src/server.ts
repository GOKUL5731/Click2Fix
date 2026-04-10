import http from 'http';
import { createApp } from './app';
import { config } from './config';
import { configureSockets } from './sockets';

const app = createApp();
const server = http.createServer(app);

configureSockets(server);

// Set keep-alive timeouts to prevent connection issues on Render
server.keepAliveTimeout = 120000; // 120 seconds
server.headersTimeout = 125000; // 125 seconds (must be > keepAliveTimeout)

server.listen(config.port, '0.0.0.0', () => {
  console.log(`Click2Fix backend listening on 0.0.0.0:${config.port}`);
});

process.on('SIGTERM', () => {
  console.log('SIGTERM received, closing server gracefully');
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});

