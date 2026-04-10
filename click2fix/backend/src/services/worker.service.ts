import { z } from 'zod';
import { query, redis } from '../database/client';
import type { NearbyWorker } from '../models/types';
import { httpError } from '../middleware/error';
import { sendPushToActor } from './notification.service';

export const nearbyWorkerQuerySchema = z.object({
  issueId: z.string().uuid().optional(),
  latitude: z.coerce.number().optional(),
  longitude: z.coerce.number().optional(),
  category: z.string().optional(),
  radiusKm: z.coerce.number().min(1).max(25).default(5)
});

export const sendQuoteSchema = z.object({
  issueId: z.string().uuid(),
  price: z.number().nonnegative(),
  estimatedTime: z.number().int().positive().optional(),
  arrivalTime: z.string().datetime().optional(),
  message: z.string().max(500).optional()
});

export const updateLocationSchema = z.object({
  latitude: z.number(),
  longitude: z.number()
});

export const setAvailabilitySchema = z.object({
  availability: z.boolean()
});

export async function findNearbyWorkers(input: z.infer<typeof nearbyWorkerQuerySchema>): Promise<NearbyWorker[]> {
  let latitude = input.latitude;
  let longitude = input.longitude;
  let category = input.category;

  if (input.issueId) {
    const issue = await query<{
      latitude: number;
      longitude: number;
      issue_type: string | null;
    }>('SELECT latitude, longitude, issue_type FROM issues WHERE id = $1', [input.issueId]);

    if (!issue.rows[0]) {
      throw httpError(404, 'Issue not found');
    }

    latitude = Number(issue.rows[0].latitude);
    longitude = Number(issue.rows[0].longitude);
    category = category ?? issue.rows[0].issue_type ?? undefined;
  }

  if (latitude === undefined || longitude === undefined) {
    throw httpError(400, 'Latitude and longitude are required');
  }

  const result = await query<NearbyWorker>(
    `SELECT *
     FROM (
       SELECT
         id,
         name,
         phone,
         category,
         rating,
         trust_score,
         current_latitude,
         current_longitude,
         service_radius_km,
         availability,
         6371 * acos(
           LEAST(1, GREATEST(-1,
             cos(radians($1)) * cos(radians(current_latitude::float)) *
             cos(radians(current_longitude::float) - radians($2)) +
             sin(radians($1)) * sin(radians(current_latitude::float))
           ))
         ) AS distance_km
       FROM workers
       WHERE availability = TRUE
         AND verification_status = 'approved'
         AND is_blacklisted = FALSE
         AND current_latitude IS NOT NULL
         AND current_longitude IS NOT NULL
         AND ($4::text IS NULL OR LOWER(category) = LOWER($4))
     ) ranked
     WHERE distance_km <= $3 AND distance_km <= service_radius_km
     ORDER BY
       (trust_score * 0.2 + rating * 20 * 0.2 - distance_km * 3) DESC,
       distance_km ASC
     LIMIT 50`,
    [latitude, longitude, input.radiusKm, category ?? null]
  );

  return result.rows.map((worker) => ({
    ...worker,
    rating: Number(worker.rating),
    trust_score: Number(worker.trust_score),
    current_latitude: worker.current_latitude === null ? null : Number(worker.current_latitude),
    current_longitude: worker.current_longitude === null ? null : Number(worker.current_longitude),
    distance_km: Number(worker.distance_km),
    service_radius_km: Number(worker.service_radius_km)
  }));
}

export async function sendQuote(workerId: string, input: z.infer<typeof sendQuoteSchema>) {
  const issue = await query<{ id: string; status: string; user_id: string }>('SELECT id, status, user_id FROM issues WHERE id = $1', [
    input.issueId
  ]);
  if (!issue.rows[0]) {
    throw httpError(404, 'Issue not found');
  }

  const result = await query(
    `INSERT INTO quotations (issue_id, worker_id, price, estimated_time, arrival_time, message)
     VALUES ($1, $2, $3, $4, $5, $6)
     ON CONFLICT (issue_id, worker_id) DO UPDATE
     SET price = EXCLUDED.price,
         estimated_time = EXCLUDED.estimated_time,
         arrival_time = EXCLUDED.arrival_time,
         message = EXCLUDED.message
     RETURNING *`,
    [input.issueId, workerId, input.price, input.estimatedTime ?? null, input.arrivalTime ?? null, input.message ?? null]
  );

  await query("UPDATE issues SET status = 'quoted' WHERE id = $1", [input.issueId]);

  void sendPushToActor('user', issue.rows[0].user_id, {
    title: 'New worker quote received',
    message: 'A worker has sent a quote for your issue. Compare and confirm booking.',
    data: { issueId: input.issueId, workerId }
  });

  return result.rows[0];
}

export async function updateWorkerLocation(workerId: string, input: z.infer<typeof updateLocationSchema>) {
  await query('UPDATE workers SET current_latitude = $1, current_longitude = $2 WHERE id = $3', [
    input.latitude,
    input.longitude,
    workerId
  ]);

  try {
    await redis.set(
      `worker-location:${workerId}`,
      JSON.stringify({ latitude: input.latitude, longitude: input.longitude, updatedAt: new Date().toISOString() }),
      'EX',
      120
    );
  } catch {
    // Database update already persisted the latest known location.
  }

  return { workerId, ...input };
}

export async function setWorkerAvailability(workerId: string, input: z.infer<typeof setAvailabilitySchema>) {
  const result = await query('UPDATE workers SET availability = $1 WHERE id = $2 RETURNING id, availability', [
    input.availability,
    workerId
  ]);
  return result.rows[0];
}

