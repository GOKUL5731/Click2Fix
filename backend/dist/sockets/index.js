"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.configureSockets = configureSockets;
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const socket_io_1 = require("socket.io");
const config_1 = require("../config");
function configureSockets(server) {
    const io = new socket_io_1.Server(server, {
        cors: {
            origin: config_1.config.corsOrigins,
            credentials: true
        }
    });
    io.use((socket, next) => {
        const token = socket.handshake.auth?.token ??
            socket.handshake.headers.authorization?.replace(/^Bearer\s+/i, '');
        if (!token) {
            next(new Error('Missing socket token'));
            return;
        }
        try {
            socket.data.auth = jsonwebtoken_1.default.verify(token, config_1.config.jwtSecret);
            next();
        }
        catch {
            next(new Error('Invalid socket token'));
        }
    });
    io.on('connection', (socket) => {
        joinRoleRooms(socket);
        socket.on('booking.join', ({ bookingId }) => {
            socket.join(`booking:${bookingId}`);
        });
        socket.on('location.updated', (payload) => {
            io.to(`booking:${payload.bookingId}`).emit('location.updated', {
                ...payload,
                workerId: socket.data.auth.sub,
                updatedAt: new Date().toISOString()
            });
        });
        socket.on('chat.message', (payload) => {
            io.to(`booking:${payload.bookingId}`).emit('chat.message', {
                ...payload,
                senderId: socket.data.auth.sub,
                senderRole: socket.data.auth.role,
                sentAt: new Date().toISOString()
            });
        });
        socket.on('booking.status_changed', (payload) => {
            io.to(`booking:${payload.bookingId}`).emit('booking.status_changed', {
                ...payload,
                actorId: socket.data.auth.sub,
                changedAt: new Date().toISOString()
            });
        });
    });
    return io;
}
function joinRoleRooms(socket) {
    const auth = socket.data.auth;
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
