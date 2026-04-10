import fs from 'fs';
import path from 'path';
import crypto from 'crypto';
import { config } from '../config';

const ALLOWED_IMAGE = new Set(['image/jpeg', 'image/png', 'image/webp']);
const ALLOWED_VIDEO = new Set(['video/mp4', 'video/quicktime']);
const ALLOWED_AUDIO = new Set(['audio/mpeg', 'audio/wav', 'audio/webm', 'audio/ogg', 'audio/mp4']);
const ALLOWED_DOC = new Set(['application/pdf']);

function ensureUploadDir(subdir: string) {
  const dir = path.join(config.uploadDir, subdir);
  fs.mkdirSync(dir, { recursive: true });
  return dir;
}

function getCategory(mimetype: string): string {
  if (ALLOWED_IMAGE.has(mimetype)) return 'images';
  if (ALLOWED_VIDEO.has(mimetype)) return 'videos';
  if (ALLOWED_AUDIO.has(mimetype)) return 'audio';
  if (ALLOWED_DOC.has(mimetype)) return 'documents';
  return 'other';
}

function sanitizeFilename(original: string): string {
  const ext = path.extname(original).toLowerCase();
  const hash = crypto.randomBytes(16).toString('hex');
  return `${Date.now()}_${hash}${ext}`;
}

export interface UploadResult {
  url: string;
  filename: string;
  mimetype: string;
  size: number;
  category: string;
}

/**
 * Save an uploaded file (from multer memory storage) to local disk.
 * Returns a URL path that the backend serves statically.
 */
export function saveUploadedFile(
  file: Express.Multer.File
): UploadResult {
  const category = getCategory(file.mimetype);
  const dir = ensureUploadDir(category);
  const filename = sanitizeFilename(file.originalname);
  const filePath = path.join(dir, filename);

  fs.writeFileSync(filePath, file.buffer);

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
export function saveUploadedFiles(files: Express.Multer.File[]): UploadResult[] {
  return files.map(saveUploadedFile);
}

/**
 * Delete a previously uploaded file by its URL path.
 */
export function deleteUploadedFile(urlPath: string): boolean {
  try {
    const relative = urlPath.replace(/^\/uploads\//, '');
    const filePath = path.join(config.uploadDir, relative);
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
      return true;
    }
    return false;
  } catch {
    return false;
  }
}
