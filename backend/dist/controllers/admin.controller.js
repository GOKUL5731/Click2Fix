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
exports.getAllBookings = exports.getSystemActivity = exports.reviewDocument = exports.approveWorker = exports.getPendingWorkers = exports.getDashboard = void 0;
const error_1 = require("../middleware/error");
const adminService = __importStar(require("../services/admin.service"));
exports.getDashboard = (0, error_1.asyncHandler)(async (_req, res) => {
    res.json(await adminService.getDashboard());
});
exports.getPendingWorkers = (0, error_1.asyncHandler)(async (_req, res) => {
    res.json(await adminService.getPendingWorkers());
});
exports.approveWorker = (0, error_1.asyncHandler)(async (req, res) => {
    res.json(await adminService.approveWorker(req.body, req.auth?.sub));
});
exports.reviewDocument = (0, error_1.asyncHandler)(async (req, res) => {
    res.json(await adminService.reviewDocument(req.body, req.auth?.sub));
});
exports.getSystemActivity = (0, error_1.asyncHandler)(async (_req, res) => {
    res.json(await adminService.getSystemActivity());
});
exports.getAllBookings = (0, error_1.asyncHandler)(async (_req, res) => {
    res.json(await adminService.getAllBookings());
});
