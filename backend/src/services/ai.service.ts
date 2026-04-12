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

// ── Gemini Vision helper ────────────────────────────────────────────

const GEMINI_MODELS = {
  text: 'gemini-1.5-flash',
  vision: 'gemini-1.5-flash',
};

async function callGemini(prompt: string, imageBase64?: string, mimeType = 'image/jpeg') {
  const apiKey = config.googleGeminiApiKey;
  if (!apiKey) throw new Error('GOOGLE_GEMINI_API_KEY not configured');

  const parts: unknown[] = [{ text: prompt }];
  if (imageBase64) {
    parts.push({
      inlineData: {
        mimeType,
        data: imageBase64,
      }
    });
  }

  const model = imageBase64 ? GEMINI_MODELS.vision : GEMINI_MODELS.text;
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      contents: [{ parts }],
      generationConfig: { temperature: 0.1, maxOutputTokens: 512 }
    }),
    signal: AbortSignal.timeout(30000),
  });

  if (!response.ok) {
    const err = await response.text();
    throw new Error(`Gemini API error ${response.status}: ${err.slice(0, 300)}`);
  }

  const data = await response.json() as { candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }> };
  return data.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
}

// ── Image analysis ──────────────────────────────────────────────────

export async function analyzeImage(imageUrl: string): Promise<{
  description: string;
  category: string;
  confidence: number;
  details: string[];
}> {
  if (!config.googleGeminiApiKey) {
    return { description: '', category: 'unknown', confidence: 0, details: [] };
  }

  try {
    // Fetch the image and convert to base64
    const imgResponse = await fetch(imageUrl, { signal: AbortSignal.timeout(15000) });
    if (!imgResponse.ok) throw new Error('Failed to fetch image');
    
    const buffer = await imgResponse.arrayBuffer();
    const base64 = Buffer.from(buffer).toString('base64');
    const mimeType = imgResponse.headers.get('content-type') ?? 'image/jpeg';

    const prompt = `You are a home repair expert. Analyze this image and identify the problem.
Respond in this exact JSON format (no markdown, just JSON):
{
  "category": "one of: plumbing, electrical, carpentry, painting, appliance_repair, cleaning, gas_leakage, other",
  "description": "brief 1-2 sentence description of the problem",
  "confidence": 0.85,
  "urgency": "one of: low, medium, high, critical",
  "details": ["detail1", "detail2"]
}`;

    const text = await callGemini(prompt, base64, mimeType);
    const cleaned = text.replace(/```json|```/g, '').trim();
    const parsed = JSON.parse(cleaned);

    return {
      description: parsed.description ?? '',
      category: parsed.category ?? 'other',
      confidence: Number(parsed.confidence ?? 0.6),
      details: parsed.details ?? [],
    };
  } catch (err) {
    console.error('[AI] analyzeImage error:', err instanceof Error ? err.message : err);
    return { description: '', category: 'unknown', confidence: 0, details: [] };
  }
}

// ── Image file analysis (from upload buffer) ────────────────────────

export async function analyzeImageFile(fileBuffer: Buffer, mimetype: string, _filename: string): Promise<{
  description: string;
  category: string;
  confidence: number;
  details: string[];
}> {
  if (!config.googleGeminiApiKey) {
    return { description: '', category: 'unknown', confidence: 0, details: [] };
  }

  try {
    const base64 = fileBuffer.toString('base64');
    const prompt = `You are a home repair expert. Analyze this image and identify the problem.
Respond in this exact JSON format (no markdown, just JSON):
{
  "category": "one of: plumbing, electrical, carpentry, painting, appliance_repair, cleaning, gas_leakage, other",
  "description": "brief 1-2 sentence description of the problem",
  "confidence": 0.85,
  "urgency": "one of: low, medium, high, critical",
  "details": ["detail1", "detail2"]
}`;

    const text = await callGemini(prompt, base64, mimetype);
    const cleaned = text.replace(/```json|```/g, '').trim();
    const parsed = JSON.parse(cleaned);

    return {
      description: parsed.description ?? '',
      category: parsed.category ?? 'other',
      confidence: Number(parsed.confidence ?? 0.6),
      details: parsed.details ?? [],
    };
  } catch (err) {
    console.error('[AI] analyzeImageFile error:', err instanceof Error ? err.message : err);
    return { description: '', category: 'unknown', confidence: 0, details: [] };
  }
}

// ── Voice transcription (Gemini as fallback; real impl uses Whisper) ─

export async function transcribeVoice(_fileBuffer: Buffer, _mimetype: string, _filename: string): Promise<{
  text: string;
  language: string;
  confidence: number;
}> {
  // Gemini does not yet support audio transcription via REST API reliably.
  // Return an empty transcript — the user's typed description is used as fallback.
  return { text: '', language: 'en', confidence: 0 };
}

// ── Text-based issue detection ──────────────────────────────────────

export async function detectIssue(input: z.infer<typeof detectIssueSchema>): Promise<AiDetectionResult> {
  const description = input.description ?? '';

  if (config.googleGeminiApiKey && (description || input.imageUrl)) {
    try {
      const prompt = `You are a home repair expert. Based on this description, classify the home repair issue.
Description: "${description}"
${input.imageUrl ? `Image URL: ${input.imageUrl}` : ''}

Respond in this exact JSON format (no markdown, just JSON):
{
  "category": "one of: plumbing, electrical, carpentry, painting, appliance_repair, cleaning, gas_leakage",
  "confidence": 0.85,
  "urgency": "one of: low, medium, high, critical",
  "estimatedPriceMin": 300,
  "estimatedPriceMax": 800,
  "explanation": ["reason1", "reason2"]
}`;

      const text = await callGemini(prompt);
      const cleaned = text.replace(/```json|```/g, '').trim();
      const parsed = JSON.parse(cleaned);
      return {
        category: parsed.category ?? 'other',
        confidence: Number(parsed.confidence ?? 0.6),
        urgency: parsed.urgency ?? 'medium',
        estimatedPriceMin: Number(parsed.estimatedPriceMin ?? 300),
        estimatedPriceMax: Number(parsed.estimatedPriceMax ?? 1000),
        explanation: parsed.explanation ?? [],
        modelVersion: 'gemini-1.5-flash',
      };
    } catch (err) {
      console.error('[AI] detectIssue Gemini error:', err instanceof Error ? err.message : err);
    }
  }

  return fallbackDetection(description);
}

// ── Price prediction ────────────────────────────────────────────────

export async function predictPrice(input: z.infer<typeof predictPriceSchema>) {
  const base = input.category.toLowerCase().includes('paint') ? [800, 5000] : [300, 1000];
  const multiplier = input.urgency === 'critical' ? 1.75 : input.urgency === 'high' ? 1.35 : 1;
  return {
    category: input.category,
    minPrice: Math.round(base[0] * multiplier),
    maxPrice: Math.round(base[1] * multiplier),
    currency: 'INR',
    modelVersion: 'rule-based-v2'
  };
}

// ── Fallback keyword detection ──────────────────────────────────────

function fallbackDetection(description: string): AiDetectionResult {
  const normalized = description.toLowerCase();

  if (normalized.includes('gas')) {
    return result('gas_leakage', 0.88, 'critical', 500, 1500, ['Detected gas leakage keyword']);
  }
  if (normalized.includes('leak') || normalized.includes('pipe') || normalized.includes('tap')) {
    return result('plumbing', 0.82, 'high', 300, 800, ['Detected plumbing keywords']);
  }
  if (normalized.includes('fan') || normalized.includes('switch') || normalized.includes('electrical') || normalized.includes('wire')) {
    return result('electrical', 0.78, 'medium', 350, 1000, ['Detected electrical keywords']);
  }
  if (normalized.includes('door') || normalized.includes('wood') || normalized.includes('hinge') || normalized.includes('lock')) {
    return result('carpentry', 0.75, 'medium', 400, 1200, ['Detected carpentry keywords']);
  }
  if (normalized.includes('paint') || normalized.includes('wall') || normalized.includes('crack')) {
    return result('painting', 0.75, 'low', 800, 5000, ['Detected painting keywords']);
  }
  if (normalized.includes('fridge') || normalized.includes('ac') || normalized.includes('washing') || normalized.includes('oven')) {
    return result('appliance_repair', 0.76, 'medium', 500, 2500, ['Detected appliance keywords']);
  }
  if (normalized.includes('clean') || normalized.includes('dust')) {
    return result('cleaning', 0.72, 'low', 500, 1500, ['Detected cleaning keywords']);
  }

  return result('other', 0.50, 'medium', 300, 1000, ['General repair issue']);
}

function result(
  category: string, confidence: number, urgency: AiDetectionResult['urgency'],
  estimatedPriceMin: number, estimatedPriceMax: number, explanation: string[]
): AiDetectionResult {
  return { category, confidence, urgency, estimatedPriceMin, estimatedPriceMax, explanation, modelVersion: 'keyword-fallback-v2' };
}
