import axios from 'axios';
import { z } from 'zod';
import { config } from '../config';
import type { AiDetectionResult } from '../models/types';

export const detectIssueSchema = z.object({
  description: z.string().max(2000).optional(),
  imageUrl: z.string().optional(),
  videoUrl: z.string().url().optional(),
  latitude: z.number().optional(),
  longitude: z.number().optional()
});

export const predictPriceSchema = z.object({
  category: z.string().min(2),
  city: z.string().optional(),
  urgency: z.enum(['low', 'medium', 'high', 'critical']).default('medium'),
  workerHistoryCount: z.number().int().min(0).optional()
});

const AI_TIMEOUT_MS = 30000; // 30s for image/voice analysis
const AI_RETRY_COUNT = 2;
const AI_RETRY_DELAY_MS = 1000;

async function aiPost(path: string, data: unknown, timeoutMs = AI_TIMEOUT_MS): Promise<unknown> {
  let lastError: unknown;
  for (let attempt = 0; attempt <= AI_RETRY_COUNT; attempt++) {
    try {
      const response = await axios.post(`${config.aiServiceUrl}${path}`, data, { timeout: timeoutMs });
      return response.data;
    } catch (error) {
      lastError = error;
      if (attempt < AI_RETRY_COUNT) {
        await new Promise((resolve) => setTimeout(resolve, AI_RETRY_DELAY_MS * (attempt + 1)));
      }
    }
  }
  throw lastError;
}

export async function detectIssue(input: z.infer<typeof detectIssueSchema>): Promise<AiDetectionResult> {
  try {
    return (await aiPost('/ai/detect-issue', input)) as AiDetectionResult;
  } catch {
    return fallbackDetection(input.description ?? '');
  }
}

/**
 * Analyze an image and return a description of the detected problem.
 */
export async function analyzeImage(imageUrl: string): Promise<{
  description: string;
  category: string;
  confidence: number;
  details: string[];
}> {
  try {
    const result = await aiPost('/ai/analyze-image', { imageUrl }) as {
      description: string;
      category: string;
      confidence: number;
      details: string[];
    };
    return result;
  } catch {
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
export async function analyzeImageFile(fileBuffer: Buffer, mimetype: string, filename: string): Promise<{
  description: string;
  category: string;
  confidence: number;
  details: string[];
}> {
  try {
    const base64 = fileBuffer.toString('base64');
    const response = await axios.post(`${config.aiServiceUrl}/ai/analyze-image-file`, {
      file_base64: base64,
      mimetype,
      filename,
    }, { timeout: AI_TIMEOUT_MS });
    return response.data;
  } catch {
    return analyzeImage(''); // fallback
  }
}

/**
 * Transcribe a voice recording to text.
 */
export async function transcribeVoice(fileBuffer: Buffer, mimetype: string, filename: string): Promise<{
  text: string;
  language: string;
  confidence: number;
}> {
  try {
    const base64 = fileBuffer.toString('base64');
    const response = await axios.post(`${config.aiServiceUrl}/ai/transcribe-voice`, {
      file_base64: base64,
      mimetype,
      filename,
    }, { timeout: AI_TIMEOUT_MS });
    return response.data;
  } catch {
    return {
      text: '',
      language: 'en',
      confidence: 0,
    };
  }
}

export async function predictPrice(input: z.infer<typeof predictPriceSchema>) {
  try {
    return await aiPost('/ai/predict-price', input, 5000);
  } catch {
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

function fallbackDetection(description: string): AiDetectionResult {
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

function result(
  category: string, confidence: number, urgency: AiDetectionResult['urgency'],
  estimatedPriceMin: number, estimatedPriceMax: number, explanation: string[]
): AiDetectionResult {
  return { category, confidence, urgency, estimatedPriceMin, estimatedPriceMax, explanation, modelVersion: 'backend-fallback-v1' };
}
