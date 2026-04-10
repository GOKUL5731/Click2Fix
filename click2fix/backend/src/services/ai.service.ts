import axios from 'axios';
import { z } from 'zod';
import { config } from '../config';
import type { AiDetectionResult } from '../models/types';

export const detectIssueSchema = z.object({
  description: z.string().max(2000).optional(),
  imageUrl: z.string().url().optional(),
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

export async function detectIssue(input: z.infer<typeof detectIssueSchema>): Promise<AiDetectionResult> {
  try {
    const response = await axios.post(`${config.aiServiceUrl}/ai/detect-issue`, input, { timeout: 5000 });
    return response.data;
  } catch {
    return fallbackDetection(input.description ?? '');
  }
}

export async function predictPrice(input: z.infer<typeof predictPriceSchema>) {
  try {
    const response = await axios.post(`${config.aiServiceUrl}/ai/predict-price`, input, { timeout: 5000 });
    return response.data;
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

  if (normalized.includes('fan') || normalized.includes('switch') || normalized.includes('electrical')) {
    return result('electrical', 0.78, 'medium', 350, 1000, ['Detected electrical repair keywords']);
  }

  if (normalized.includes('paint')) {
    return result('painting', 0.75, 'low', 800, 5000, ['Detected painting keyword']);
  }

  return result('cleaning', 0.55, 'medium', 500, 1500, ['Used fallback category']);
}

function result(
  category: string,
  confidence: number,
  urgency: AiDetectionResult['urgency'],
  estimatedPriceMin: number,
  estimatedPriceMax: number,
  explanation: string[]
): AiDetectionResult {
  return {
    category,
    confidence,
    urgency,
    estimatedPriceMin,
    estimatedPriceMax,
    explanation,
    modelVersion: 'backend-fallback-v1'
  };
}

