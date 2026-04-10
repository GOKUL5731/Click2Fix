import { z } from 'zod';
import { query } from '../database/client';
import { detectIssue } from './ai.service';

export const createIssueSchema = z.object({
  imageUrl: z.string().url().optional(),
  videoUrl: z.string().url().optional(),
  description: z.string().max(2000).optional(),
  latitude: z.number(),
  longitude: z.number(),
  isEmergency: z.boolean().optional()
});

export async function createIssue(userId: string, input: z.infer<typeof createIssueSchema>) {
  const ai = await detectIssue({
    description: input.description,
    imageUrl: input.imageUrl,
    videoUrl: input.videoUrl,
    latitude: input.latitude,
    longitude: input.longitude
  });

  const categoryResult = await query<{ id: string }>(
    'SELECT id FROM categories WHERE ai_label = $1 OR LOWER(name) = LOWER($2) LIMIT 1',
    [ai.category, ai.category.replace(/_/g, ' ')]
  );
  const categoryId = categoryResult.rows[0]?.id ?? null;
  const emergency = input.isEmergency === true || ai.urgency === 'critical';

  const result = await query(
    `INSERT INTO issues (
      user_id, image_url, video_url, issue_type, category_id, ai_confidence,
      urgency_level, description, latitude, longitude, status,
      estimated_price_min, estimated_price_max, is_emergency
    )
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, 'worker_matching', $11, $12, $13)
    RETURNING *`,
    [
      userId,
      input.imageUrl ?? null,
      input.videoUrl ?? null,
      ai.category,
      categoryId,
      ai.confidence * 100,
      ai.urgency,
      input.description ?? null,
      input.latitude,
      input.longitude,
      ai.estimatedPriceMin,
      ai.estimatedPriceMax,
      emergency
    ]
  );

  return { issue: result.rows[0], ai };
}

export async function getIssue(issueId: string) {
  const result = await query('SELECT * FROM issues WHERE id = $1', [issueId]);
  return result.rows[0] ?? null;
}

