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
exports.getQuotations = exports.getProfile = exports.uploadDocument = exports.setAvailability = exports.updateLocation = exports.sendQuote = exports.findNearbyWorkers = void 0;
const error_1 = require("../middleware/error");
const workerService = __importStar(require("../services/worker.service"));
const upload_service_1 = require("../services/upload.service");
exports.findNearbyWorkers = (0, error_1.asyncHandler)(async (req, res) => {
    res.json(await workerService.findNearbyWorkers(req.query));
});
exports.sendQuote = (0, error_1.asyncHandler)(async (req, res) => {
    if (!req.auth?.sub)
        throw (0, error_1.httpError)(401, 'Authentication required');
    res.status(201).json(await workerService.sendQuote(req.auth.sub, req.body));
});
exports.updateLocation = (0, error_1.asyncHandler)(async (req, res) => {
    if (!req.auth?.sub)
        throw (0, error_1.httpError)(401, 'Authentication required');
    res.json(await workerService.updateWorkerLocation(req.auth.sub, req.body));
});
exports.setAvailability = (0, error_1.asyncHandler)(async (req, res) => {
    if (!req.auth?.sub)
        throw (0, error_1.httpError)(401, 'Authentication required');
    res.json(await workerService.setWorkerAvailability(req.auth.sub, req.body));
});
exports.uploadDocument = (0, error_1.asyncHandler)(async (req, res) => {
    if (!req.auth?.sub)
        throw (0, error_1.httpError)(401, 'Authentication required');
    const file = req.file;
    if (!file)
        throw (0, error_1.httpError)(400, 'Document file is required');
    const uploaded = (0, upload_service_1.saveUploadedFile)(file);
    const result = await workerService.uploadWorkerDocument(req.auth.sub, {
        documentType: req.body.documentType ?? 'certificate',
        fileUrl: uploaded.url,
    });
    res.status(201).json(result);
});
exports.getProfile = (0, error_1.asyncHandler)(async (req, res) => {
    if (!req.auth?.sub)
        throw (0, error_1.httpError)(401, 'Authentication required');
    const profile = await workerService.getWorkerProfile(req.auth.sub);
    if (!profile)
        throw (0, error_1.httpError)(404, 'Worker not found');
    res.json(profile);
});
exports.getQuotations = (0, error_1.asyncHandler)(async (req, res) => {
    res.json(await workerService.getQuotationsForIssue(String(req.params.issueId)));
});
