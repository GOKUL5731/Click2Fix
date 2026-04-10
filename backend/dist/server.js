"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const http_1 = __importDefault(require("http"));
const app_1 = require("./app");
const config_1 = require("./config");
const sockets_1 = require("./sockets");
const app = (0, app_1.createApp)();
const server = http_1.default.createServer(app);
(0, sockets_1.configureSockets)(server);
server.listen(config_1.config.port, () => {
    console.log(`Click2Fix backend listening on port ${config_1.config.port}`);
});
process.on('SIGTERM', () => {
    server.close(() => process.exit(0));
});
