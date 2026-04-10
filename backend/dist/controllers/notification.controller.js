"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendToActor = exports.sendTestToSelf = exports.unregisterToken = exports.registerToken = void 0;
const error_1 = require("../middleware/error");
const notificationService = __importStar(require("../services/notification.service"));
exports.registerToken = (0, error_1.asyncHandler)(async (req, res) => {
    if (!req.auth?.sub) {
        throw (0, error_1.httpError)(401, 'Authentication required');
    }
    res.status(201).json(await notificationService.registerDeviceToken(req.auth.sub, req.auth.role, req.body));
});
exports.unregisterToken = (0, error_1.asyncHandler)(async (req, res) => {
    if (!req.auth?.sub) {
        throw (0, error_1.httpError)(401, 'Authentication required');
    }
    res.json(await notificationService.unregisterDeviceToken(req.auth.sub, req.auth.role, req.body));
});
exports.sendTestToSelf = (0, error_1.asyncHandler)(async (req, res) => {
    if (!req.auth?.sub) {
        throw (0, error_1.httpError)(401, 'Authentication required');
    }
    const payload = notificationService.pushPayloadSchema.parse(req.body);
    res.json(await notificationService.sendPushToActor(req.auth.role, req.auth.sub, payload));
});
exports.sendToActor = (0, error_1.asyncHandler)(async (req, res) => {
    const payload = notificationService.sendPushToActorSchema.parse(req.body);
    res.json(await notificationService.sendPushToActor(payload.actorRole, payload.actorId, {
        title: payload.title,
        message: payload.message,
        data: payload.data
    }));
});
