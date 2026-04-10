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
exports.getUserIssues = exports.getIssue = exports.createIssue = void 0;
const error_1 = require("../middleware/error");
const issueService = __importStar(require("../services/issue.service"));
const upload_service_1 = require("../services/upload.service");
const ai_service_1 = require("../services/ai.service");
exports.createIssue = (0, error_1.asyncHandler)(async (req, res) => {
    if (!req.auth?.sub) {
        throw (0, error_1.httpError)(401, 'Authentication required');
    }
    // Handle file uploads from multipart form
    const files = req.files;
    const body = { ...req.body };
    if (files?.length) {
        for (const file of files) {
            const uploaded = (0, upload_service_1.saveUploadedFile)(file);
            if (uploaded.category === 'images' && !body.imageUrl) {
                body.imageUrl = uploaded.url;
            }
            else if (uploaded.category === 'videos' && !body.videoUrl) {
                body.videoUrl = uploaded.url;
            }
            else if (uploaded.category === 'audio' && !body.voiceUrl) {
                body.voiceUrl = uploaded.url;
                // Transcribe voice to text and merge with description
                try {
                    const transcription = await (0, ai_service_1.transcribeVoice)(file.buffer, file.mimetype, file.originalname);
                    if (transcription.text) {
                        const existing = body.description ?? '';
                        body.description = existing
                            ? `${existing}\n\n[Voice Input]: ${transcription.text}`
                            : transcription.text;
                    }
                }
                catch {
                    // Voice transcription is non-blocking
                }
            }
        }
    }
    // Parse numeric fields from form data
    if (typeof body.latitude === 'string')
        body.latitude = parseFloat(body.latitude);
    if (typeof body.longitude === 'string')
        body.longitude = parseFloat(body.longitude);
    if (typeof body.isEmergency === 'string')
        body.isEmergency = body.isEmergency === 'true';
    res.status(201).json(await issueService.createIssue(req.auth.sub, body));
});
exports.getIssue = (0, error_1.asyncHandler)(async (req, res) => {
    const issue = await issueService.getIssue(String(req.params.id));
    if (!issue) {
        throw (0, error_1.httpError)(404, 'Issue not found');
    }
    res.json(issue);
});
exports.getUserIssues = (0, error_1.asyncHandler)(async (req, res) => {
    if (!req.auth?.sub) {
        throw (0, error_1.httpError)(401, 'Authentication required');
    }
    res.json(await issueService.getUserIssues(req.auth.sub));
});
