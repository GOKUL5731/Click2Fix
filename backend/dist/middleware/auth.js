"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.authenticate = void 0;
exports.requireRole = requireRole;
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const config_1 = require("../config");
const error_1 = require("./error");
const authenticate = (req, _res, next) => {
    const header = req.headers.authorization;
    const token = header?.startsWith('Bearer ') ? header.slice('Bearer '.length) : undefined;
    if (!token) {
        next((0, error_1.httpError)(401, 'Missing bearer token'));
        return;
    }
    try {
        req.auth = jsonwebtoken_1.default.verify(token, config_1.config.jwtSecret);
        next();
    }
    catch {
        next((0, error_1.httpError)(401, 'Invalid or expired token'));
    }
};
exports.authenticate = authenticate;
function requireRole(...roles) {
    return (req, _res, next) => {
        if (!req.auth) {
            next((0, error_1.httpError)(401, 'Authentication required'));
            return;
        }
        if (!roles.includes(req.auth.role)) {
            next((0, error_1.httpError)(403, 'Insufficient permissions'));
            return;
        }
        next();
    };
}
