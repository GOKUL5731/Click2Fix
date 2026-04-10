"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.saveUploadedFile = saveUploadedFile;
exports.saveUploadedFiles = saveUploadedFiles;
exports.deleteUploadedFile = deleteUploadedFile;
const fs_1 = __importDefault(require("fs"));
const path_1 = __importDefault(require("path"));
const crypto_1 = __importDefault(require("crypto"));
const config_1 = require("../config");
const ALLOWED_IMAGE = new Set(['image/jpeg', 'image/png', 'image/webp']);
const ALLOWED_VIDEO = new Set(['video/mp4', 'video/quicktime']);
const ALLOWED_AUDIO = new Set(['audio/mpeg', 'audio/wav', 'audio/webm', 'audio/ogg', 'audio/mp4']);
const ALLOWED_DOC = new Set(['application/pdf']);
function ensureUploadDir(subdir) {
    const dir = path_1.default.join(config_1.config.uploadDir, subdir);
    fs_1.default.mkdirSync(dir, { recursive: true });
    return dir;
}
function getCategory(mimetype) {
    if (ALLOWED_IMAGE.has(mimetype))
        return 'images';
    if (ALLOWED_VIDEO.has(mimetype))
        return 'videos';
    if (ALLOWED_AUDIO.has(mimetype))
        return 'audio';
    if (ALLOWED_DOC.has(mimetype))
        return 'documents';
    return 'other';
}
function sanitizeFilename(original) {
    const ext = path_1.default.extname(original).toLowerCase();
    const hash = crypto_1.default.randomBytes(16).toString('hex');
    return `${Date.now()}_${hash}${ext}`;
}
/**
 * Save an uploaded file (from multer memory storage) to local disk.
 * Returns a URL path that the backend serves statically.
 */
function saveUploadedFile(file) {
    const category = getCategory(file.mimetype);
    const dir = ensureUploadDir(category);
    const filename = sanitizeFilename(file.originalname);
    const filePath = path_1.default.join(dir, filename);
    fs_1.default.writeFileSync(filePath, file.buffer);
    return {
        url: `/uploads/${category}/${filename}`,
        filename,
        mimetype: file.mimetype,
        size: file.size,
        category,
    };
}
/**
 * Save multiple uploaded files.
 */
function saveUploadedFiles(files) {
    return files.map(saveUploadedFile);
}
/**
 * Delete a previously uploaded file by its URL path.
 */
function deleteUploadedFile(urlPath) {
    try {
        const relative = urlPath.replace(/^\/uploads\//, '');
        const filePath = path_1.default.join(config_1.config.uploadDir, relative);
        if (fs_1.default.existsSync(filePath)) {
            fs_1.default.unlinkSync(filePath);
            return true;
        }
        return false;
    }
    catch {
        return false;
    }
}
