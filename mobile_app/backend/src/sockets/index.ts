import type http from 'http';
import jwt from 'jsonwebtoken';
import { Server, type Socket } from 'socket.io';
import { config } from '../config';
import type { AuthTokenPayload } from '../models/types';

export function configureSockets(server: http.Server) {
  const io = new Server(server, {
    cors: {
      origin: config.corsOrigins,
      credentials: true
    }
  });

  io.use((socket, next) => {
    const token =
      socket.handshake.auth?.token ??
      socket.handshake.headers.authorization?.replace(/^Bearer\s+/i, '');

    if (!token) {
      next(new Error('Missing socket token'));
      return;
    }

    try {
      socket.data.auth = jwt.verify(token, config.jwtSecret) as AuthTokenPayload;
      next();
    } catch {
      next(new Error('Invalid socket token'));
    }
  });

  io.on('connection', (socket) => {
    joinRoleRooms(socket);

    socket.on('booking.join', ({ bookingId }: { bookingId: string }) => {
      socket.join(`booking:${bookingId}`);
    });

    socket.on('location.updated', (payload: { bookingId: string; latitude: number; longitude: number }) => {
      io.to(`booking:${payload.bookingId}`).emit('location.updated', {
        ...payload,
        workerId: socket.data.auth.sub,
        updatedAt: new Date().toISOString()
      });
    });

    socket.on('chat.message', (payload: { bookingId: string; message: string; mediaUrl?: string }) => {
      io.to(`booking:${payload.bookingId}`).emit('chat.message', {
        ...payload,
        senderId: socket.data.auth.sub,
        senderRole: socket.data.auth.role,
        sentAt: new Date().toISOString()
      });
    });

    socket.on('booking.status_changed', (payload: { bookingId: string; status: string }) => {
      io.to(`booking:${payload.bookingId}`).emit('booking.status_changed', {
        ...payload,
        actorId: socket.data.auth.sub,
        changedAt: new Date().toISOString()
      });
    });
  });

  return io;
}

function joinRoleRooms(socket: Socket) {
  const auth = socket.data.auth as AuthTokenPayload;

  if (auth.role === 'user') {
    socket.join(`user:${auth.sub}`);
  }

  if (auth.role === 'worker') {
    socket.join(`worker:${auth.sub}`);
  }

  if (auth.role === 'admin') {
    socket.join('admin:emergencies');
    socket.join('admin:dashboard');
  }
}

