import { z } from 'zod';
import { query } from '../database/client';
import { analyzeImage, detectIssue, transcribeVoice } from './ai.service';
import { sendPushToActor } from './notification.service';
import { findNearbyWorkers } from './worker.service';

export const createIssueSchema = z.object({
  imageUrl: z.string().optional(),
  videoUrl: z.string().url().optional(),
  voiceUrl: z.string().optional(),
  description: z.string().max(2000).optional(),
  latitude: z.number(),
  longitude: z.number(),
  isEmergency: z.boolean().optional(),
  uploadToken: z.string().optional(), // OTP-verified upload token
});

export async function createIssue(userId: string, input: z.infer<typeof createIssueSchema>) {
  // 1. If image was uploaded, try AI image analysis to auto-fill description
  let aiImageDescription = '';
  if (input.imageUrl) {
    try {
      const imageAnalysis = await analyzeImage(input.imageUrl);
      if (imageAnalysis.description && imageAnalysis.confidence > 0) {
        aiImageDescription = imageAnalysis.description;
      }
    } catch {
      // Image analysis is non-blocking
    }
  }

  // 2. Merge all description sources
  const descriptionParts: string[] = [];
  if (input.description?.trim()) {
    descriptionParts.push(input.description.trim());
  }
  if (aiImageDescription) {
    descriptionParts.push(`[AI Detected]: ${aiImageDescription}`);
  }
  const mergedDescription = descriptionParts.join('\n\n') || null;

  // 3. Run AI detection (uses merged description + image URL)
  const ai = await detectIssue({
    description: mergedDescription ?? undefined,
    imageUrl: input.imageUrl,
    videoUrl: input.videoUrl,
    latitude: input.latitude,
    longitude: input.longitude
  });

  // 4. Resolve category
  const categoryResult = await query<{ id: string }>(
    'SELECT id FROM categories WHERE ai_label = $1 OR LOWER(name) = LOWER($2) LIMIT 1',
    [ai.category, ai.category.replace(/_/g, ' ')]
  );
  const categoryId = categoryResult.rows[0]?.id ?? null;
  const emergency = input.isEmergency === true || ai.urgency === 'critical';

  // 5. Insert issue
  const result = await query(
    `INSERT INTO issues (
      user_id, image_url, video_url, voice_url, issue_type, category_id, ai_confidence,
      urgency_level, description, latitude, longitude, status,
      estimated_price_min, estimated_price_max, is_emergency
    )
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, 'worker_matching', $12, $13, $14)
    RETURNING *`,
    [
      userId,
      input.imageUrl ?? null,
      input.videoUrl ?? null,
      input.voiceUrl ?? null,
      ai.category,
      categoryId,
      ai.confidence * 100,
      ai.urgency,
      mergedDescription,
      input.latitude,
      input.longitude,
      ai.estimatedPriceMin,
      ai.estimatedPriceMax,
      emergency
    ]
  );

  const issue = result.rows[0] as { id: string; issue_type: string; description: string; urgency_level: string; is_emergency: boolean };

  // 6. Notify nearby workers
  void notifyWorkersOfIssue(issue, input.latitude, input.longitude, emergency);

  return { issue, ai, aiImageDescription };
}

async function notifyWorkersOfIssue(
  issue: { id: string; issue_type: string; description: string; urgency_level: string; is_emergency: boolean },
  latitude: number,
  longitude: number,
  emergency: boolean
) {
  try {
    const workers = await findNearbyWorkers({
      issueId: issue.id,
      latitude,
      longitude,
      category: issue.issue_type,
      radiusKm: emergency ? 15 : 5,
    });

    const title = emergency ? '🚨 Emergency Request Nearby!' : '📋 New Service Request';
    const message = `${issue.issue_type?.replace(/_/g, ' ')} — ${issue.urgency_level} urgency. ${issue.description?.slice(0, 100) ?? 'View details in app.'}`;

    for (const worker of workers.slice(0, 20)) {
      void sendPushToActor('worker', worker.id, {
        title,
        message,
        data: {
          issueId: issue.id,
          category: issue.issue_type,
          urgency: issue.urgency_level,
          emergency: String(emergency),
        }
      });
    }
  } catch (error) {
    console.error('Failed to notify workers:', error instanceof Error ? error.message : error);
  }
}

export async function getIssue(issueId: string) {
  const result = await query('SELECT * FROM issues WHERE id = $1', [issueId]);
  return result.rows[0] ?? null;
}

export async function getUserIssues(userId: string) {
  const result = await query(
    'SELECT * FROM issues WHERE user_id = $1 ORDER BY created_at DESC LIMIT 50',
    [userId]
  );
  return result.rows;
}
