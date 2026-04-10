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
exports.bookingRoutes = void 0;
const express_1 = require("express");
const zod_1 = require("zod");
const bookingController = __importStar(require("../controllers/booking.controller"));
const auth_1 = require("../middleware/auth");
const validate_1 = require("../middleware/validate");
const booking_service_1 = require("../services/booking.service");
exports.bookingRoutes = (0, express_1.Router)();
const liveLocationQuerySchema = zod_1.z.object({
    bookingId: zod_1.z.string().uuid()
});
exports.bookingRoutes.post('/create', auth_1.authenticate, (0, auth_1.requireRole)('user'), (0, validate_1.validateBody)(booking_service_1.createBookingSchema), bookingController.createBooking);
exports.bookingRoutes.get('/history', auth_1.authenticate, bookingController.history);
exports.bookingRoutes.get('/live-location', auth_1.authenticate, (0, validate_1.validateQuery)(liveLocationQuerySchema), bookingController.liveLocation);
exports.bookingRoutes.post('/complete', auth_1.authenticate, (0, validate_1.validateBody)(booking_service_1.completeBookingSchema), bookingController.complete);
