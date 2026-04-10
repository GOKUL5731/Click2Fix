import { z } from 'zod';
import { query } from '../database/client';
import { httpError } from '../middleware/error';

export const approveWorkerSchema = z.object({
  workerId: z.string().uuid(),
  approved: z.boolean(),
  notes: z.string().max(1000).optional()
});

export async function getDashboard() {
  const [users, workers, activeBookings, emergencies, revenue, fraudAlerts, pendingWorkers] = await Promise.all([
    query<{ count: string }>('SELECT COUNT(*) FROM users'),
    query<{ count: string }>('SELECT COUNT(*) FROM workers'),
    query<{ count: string }>("SELECT COUNT(*) FROM bookings WHERE booking_status IN ('confirmed', 'worker_on_way', 'arrived', 'work_started')"),
    query<{ count: string }>("SELECT COUNT(*) FROM issues WHERE is_emergency = TRUE AND status NOT IN ('completed', 'cancelled')"),
    query<{ total: string }>("SELECT COALESCE(SUM(amount), 0) AS total FROM payments WHERE status = 'paid'"),
    query<{ count: string }>("SELECT COUNT(*) FROM fraud_alerts WHERE status = 'open'"),
    query<{ count: string }>("SELECT COUNT(*) FROM workers WHERE verification_status = 'pending'")
  ]);

  return {
    totalUsers: Number(users.rows[0].count),
    totalWorkers: Number(workers.rows[0].count),
    activeBookings: Number(activeBookings.rows[0].count),
    emergencyRequests: Number(emergencies.rows[0].count),
    totalRevenue: Number(revenue.rows[0].total),
    fraudAlerts: Number(fraudAlerts.rows[0].count),
    workerApprovalQueue: Number(pendingWorkers.rows[0].count),
    charts: {
      daily: [],
      weekly: [],
      monthly: []
    }
  };
}

export async function getPendingWorkers() {
  const result = await query(
    `SELECT id, name, phone, category, experience, aadhaar_verified, face_verified, trust_score, created_at
     FROM workers
     WHERE verification_status = 'pending'
     ORDER BY created_at ASC
     LIMIT 100`
  );
  return result.rows;
}

export async function approveWorker(input: z.infer<typeof approveWorkerSchema>, adminId?: string) {
  const status = input.approved ? 'approved' : 'rejected';
  const result = await query(
    `UPDATE workers
     SET verification_status = $2,
         aadhaar_verified = CASE WHEN $2 = 'approved' THEN TRUE ELSE aadhaar_verified END,
         face_verified = CASE WHEN $2 = 'approved' THEN TRUE ELSE face_verified END,
         trust_score = CASE WHEN $2 = 'approved' THEN GREATEST(trust_score, 70) ELSE trust_score END
     WHERE id = $1
     RETURNING *`,
    [input.workerId, status]
  );

  if (!result.rows[0]) {
    throw httpError(404, 'Worker not found');
  }

  await query(
    `INSERT INTO audit_logs (actor_role, actor_id, action, entity_type, entity_id, metadata)
     VALUES ('admin', $1, $2, 'worker', $3, $4)`,
    [adminId ?? null, input.approved ? 'approve_worker' : 'reject_worker', input.workerId, JSON.stringify({ notes: input.notes })]
  );

  return result.rows[0];
}

