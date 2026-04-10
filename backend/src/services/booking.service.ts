import bcrypt from 'bcryptjs';
import { z } from 'zod';
import { query, redis } from '../database/client';
import { httpError } from '../middleware/error';
import { sendPushToActor } from './notification.service';

export const createBookingSchema = z.object({
  issueId: z.string().uuid(),
  workerId: z.string().uuid(),
  quotationId: z.string().uuid().optional()
});

export const completeBookingSchema = z.object({
  bookingId: z.string().uuid(),
  completionOtp: z.string().length(6).optional()
});

export async function createBooking(userId: string, input: z.infer<typeof createBookingSchema>) {
  const completionOtp = process.env.NODE_ENV === 'production' ? Math.floor(100000 + Math.random() * 900000).toString() : '432198';
  const completionOtpHash = await bcrypt.hash(completionOtp, 12);

  const result = await query(
    `INSERT INTO bookings (issue_id, quotation_id, worker_id, user_id, booking_status, payment_status, completion_otp_hash)
     VALUES ($1, $2, $3, $4, 'confirmed', 'pending', $5)
     RETURNING *`,
    [input.issueId, input.quotationId ?? null, input.workerId, userId, completionOtpHash]
  );

  if (input.quotationId) {
    await query('UPDATE quotations SET is_selected = TRUE WHERE id = $1 AND issue_id = $2', [input.quotationId, input.issueId]);
  }

  await query("UPDATE issues SET status = 'booked' WHERE id = $1", [input.issueId]);

  void sendPushToActor('worker', input.workerId, {
    title: 'New booking confirmed',
    message: 'A user confirmed your quote. Open the app to start navigation.',
    data: { bookingId: result.rows[0].id as string, issueId: input.issueId }
  });

  void sendPushToActor('user', userId, {
    title: 'Booking confirmed',
    message: 'Your worker has been assigned. You can track live location now.',
    data: { bookingId: result.rows[0].id as string, workerId: input.workerId }
  });

  return {
    booking: result.rows[0],
    devCompletionOtp: process.env.NODE_ENV === 'production' ? undefined : completionOtp
  };
}

export async function getBookingHistory(actorId: string, role: 'user' | 'worker') {
  const column = role === 'worker' ? 'worker_id' : 'user_id';
  const result = await query(
    `SELECT b.*, i.issue_type, i.description, i.urgency_level
     FROM bookings b
     JOIN issues i ON i.id = b.issue_id
     WHERE b.${column} = $1
     ORDER BY b.created_at DESC
     LIMIT 100`,
    [actorId]
  );
  return result.rows;
}

export async function getLiveLocation(bookingId: string) {
  const booking = await query<{ worker_id: string }>('SELECT worker_id FROM bookings WHERE id = $1', [bookingId]);
  const workerId = booking.rows[0]?.worker_id;

  if (!workerId) {
    throw httpError(404, 'Booking not found');
  }

  try {
    const live = await redis.get(`worker-location:${workerId}`);
    if (live) return JSON.parse(live);
  } catch {
    // Fall through to database snapshot.
  }

  const worker = await query('SELECT current_latitude AS latitude, current_longitude AS longitude FROM workers WHERE id = $1', [
    workerId
  ]);

  return worker.rows[0] ?? null;
}

export async function completeBooking(input: z.infer<typeof completeBookingSchema>) {
  const booking = await query<{ completion_otp_hash: string }>(
    'SELECT completion_otp_hash FROM bookings WHERE id = $1',
    [input.bookingId]
  );

  if (!booking.rows[0]) {
    throw httpError(404, 'Booking not found');
  }

  if (input.completionOtp) {
    const valid = await bcrypt.compare(input.completionOtp, booking.rows[0].completion_otp_hash);
    if (!valid) {
      throw httpError(401, 'Invalid completion OTP');
    }
  }

  const result = await query(
    `UPDATE bookings
     SET booking_status = 'completed', completed_at = NOW()
     WHERE id = $1
     RETURNING *`,
    [input.bookingId]
  );

  await query(
    `UPDATE issues
     SET status = 'completed'
     WHERE id = (SELECT issue_id FROM bookings WHERE id = $1)`,
    [input.bookingId]
  );

  const completedBooking = result.rows[0] as { id: string; user_id: string; worker_id: string };

  void sendPushToActor('user', completedBooking.user_id, {
    title: 'Booking completed',
    message: 'Your service has been marked as completed. Please add a review.',
    data: { bookingId: completedBooking.id }
  });

  void sendPushToActor('worker', completedBooking.worker_id, {
    title: 'Job completed',
    message: 'Booking completed successfully. Check wallet and payout details.',
    data: { bookingId: completedBooking.id }
  });

  return completedBooking;
}

