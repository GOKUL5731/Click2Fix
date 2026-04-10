import { query } from '../database/client';

export async function createUserNotification(userId: string, title: string, message: string) {
  const result = await query(
    `INSERT INTO notifications (user_id, title, message)
     VALUES ($1, $2, $3)
     RETURNING *`,
    [userId, title, message]
  );
  return result.rows[0];
}

export async function createWorkerNotification(workerId: string, title: string, message: string) {
  const result = await query(
    `INSERT INTO notifications (worker_id, title, message)
     VALUES ($1, $2, $3)
     RETURNING *`,
    [workerId, title, message]
  );
  return result.rows[0];
}

