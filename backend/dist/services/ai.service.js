"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.predictPriceSchema = exports.detectIssueSchema = void 0;
exports.detectIssue = detectIssue;
exports.analyzeImage = analyzeImage;
exports.analyzeImageFile = analyzeImageFile;
exports.transcribeVoice = transcribeVoice;
exports.predictPrice = predictPrice;
const axios_1 = __importDefault(require("axios"));
const zod_1 = require("zod");
const config_1 = require("../config");
exports.detectIssueSchema = zod_1.z.object({
    description: zod_1.z.string().max(2000).optional(),
    imageUrl: zod_1.z.string().optional(),
    videoUrl: zod_1.z.string().url().optional(),
    latitude: zod_1.z.number().optional(),
    longitude: zod_1.z.number().optional()
});
exports.predictPriceSchema = zod_1.z.object({
    category: zod_1.z.string().min(2),
    city: zod_1.z.string().optional(),
    urgency: zod_1.z.enum(['low', 'medium', 'high', 'critical']).default('medium'),
    workerHistoryCount: zod_1.z.number().int().min(0).optional()
});
const AI_TIMEOUT_MS = 30000; // 30s for image/voice analysis
const AI_RETRY_COUNT = 2;
const AI_RETRY_DELAY_MS = 1000;
async function aiPost(path, data, timeoutMs = AI_TIMEOUT_MS) {
    let lastError;
    for (let attempt = 0; attempt <= AI_RETRY_COUNT; attempt++) {
        try {
            const response = await axios_1.default.post(`${config_1.config.aiServiceUrl}${path}`, data, { timeout: timeoutMs });
            return response.data;
        }
        catch (error) {
            lastError = error;
            if (attempt < AI_RETRY_COUNT) {
                await new Promise((resolve) => setTimeout(resolve, AI_RETRY_DELAY_MS * (attempt + 1)));
            }
        }
    }
    throw lastError;
}
async function detectIssue(input) {
    try {
        return (await aiPost('/ai/detect-issue', input));
    }
    catch {
        return fallbackDetection(input.description ?? '');
    }
}
/**
 * Analyze an image and return a description of the detected problem.
 */
async function analyzeImage(imageUrl) {
    try {
        const result = await aiPost('/ai/analyze-image', { imageUrl });
        return result;
    }
    catch {
        return {
            description: 'Unable to analyze image automatically. Please describe the problem manually.',
            category: 'unknown',
            confidence: 0,
            details: ['AI image analysis unavailable - fallback mode'],
        };
    }
}
/**
 * Analyze an image file (multipart) and return a description.
 */
async function analyzeImageFile(fileBuffer, mimetype, filename) {
    try {
        const base64 = fileBuffer.toString('base64');
        const response = await axios_1.default.post(`${config_1.config.aiServiceUrl}/ai/analyze-image-file`, {
            file_base64: base64,
            mimetype,
            filename,
        }, { timeout: AI_TIMEOUT_MS });
        return response.data;
    }
    catch {
        return analyzeImage(''); // fallback
    }
}
/**
 * Transcribe a voice recording to text.
 */
async function transcribeVoice(fileBuffer, mimetype, filename) {
    try {
        const base64 = fileBuffer.toString('base64');
        const response = await axios_1.default.post(`${config_1.config.aiServiceUrl}/ai/transcribe-voice`, {
            file_base64: base64,
            mimetype,
            filename,
        }, { timeout: AI_TIMEOUT_MS });
        return response.data;
    }
    catch {
        return {
            text: '',
            language: 'en',
            confidence: 0,
        };
    }
}
async function predictPrice(input) {
    try {
        return await aiPost('/ai/predict-price', input, 5000);
    }
    catch {
        const base = input.category.toLowerCase().includes('paint') ? [800, 5000] : [300, 1000];
        const multiplier = input.urgency === 'critical' ? 1.75 : input.urgency === 'high' ? 1.35 : 1;
        return {
            category: input.category,
            minPrice: Math.round(base[0] * multiplier),
            maxPrice: Math.round(base[1] * multiplier),
            currency: 'INR',
            modelVersion: 'backend-fallback-v1'
        };
    }
}
function fallbackDetection(description) {
    const normalized = description.toLowerCase();
    if (normalized.includes('gas')) {
        return result('gas_leakage', 0.88, 'critical', 500, 1500, ['Detected gas leakage keyword']);
    }
    if (normalized.includes('leak') || normalized.includes('pipe') || normalized.includes('tap')) {
        return result('plumbing', 0.82, 'high', 300, 800, ['Detected plumbing leakage keywords']);
    }
    if (normalized.includes('fan') || normalized.includes('switch') || normalized.includes('electrical') || normalized.includes('wire') || normalized.includes('spark')) {
        return result('electrical', 0.78, 'medium', 350, 1000, ['Detected electrical repair keywords']);
    }
    if (normalized.includes('door') || normalized.includes('wood') || normalized.includes('hinge') || normalized.includes('lock')) {
        return result('carpentry', 0.75, 'medium', 400, 1200, ['Detected carpentry keywords']);
    }
    if (normalized.includes('paint') || normalized.includes('wall') || normalized.includes('crack')) {
        return result('painting', 0.75, 'low', 800, 5000, ['Detected painting keyword']);
    }
    if (normalized.includes('fridge') || normalized.includes('washing') || normalized.includes('ac') || normalized.includes('oven')) {
        return result('appliance_repair', 0.76, 'medium', 500, 2500, ['Detected appliance repair keywords']);
    }
    if (normalized.includes('clean') || normalized.includes('dust')) {
        return result('cleaning', 0.72, 'low', 500, 1500, ['Detected cleaning keywords']);
    }
    return result('cleaning', 0.55, 'medium', 500, 1500, ['Used fallback category']);
}
function result(category, confidence, urgency, estimatedPriceMin, estimatedPriceMax, explanation) {
    return { category, confidence, urgency, estimatedPriceMin, estimatedPriceMax, explanation, modelVersion: 'backend-fallback-v1' };
}
