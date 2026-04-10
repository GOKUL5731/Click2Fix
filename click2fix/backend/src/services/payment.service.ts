import { z } from 'zod';
import { query } from '../database/client';
import { httpError } from '../middleware/error';

export const paySchema = z.object({
  bookingId: z.string().uuid(),
  amount: z.number().nonnegative(),
  provider: z.enum(['razorpay', 'upi', 'stripe']).default('razorpay')
});

export const verifyPaymentSchema = z.object({
  paymentId: z.string().uuid(),
  providerPaymentId: z.string().min(3),
  providerOrderId: z.string().optional(),
  signature: z.string().optional()
});

export async function createPayment(input: z.infer<typeof paySchema>) {
  const booking = await query('SELECT id FROM bookings WHERE id = $1', [input.bookingId]);
  if (!booking.rows[0]) {
    throw httpError(404, 'Booking not found');
  }

  const providerOrderId = `order_${Date.now()}`;
  const result = await query(
    `INSERT INTO payments (booking_id, provider, provider_order_id, amount, status)
     VALUES ($1, $2, $3, $4, 'authorized')
     RETURNING *`,
    [input.bookingId, input.provider, providerOrderId, input.amount]
  );

  return {
    payment: result.rows[0],
    providerOrder: {
      id: providerOrderId,
      amount: input.amount,
      currency: 'INR',
      keyId: process.env.RAZORPAY_KEY_ID ?? 'dev-key'
    }
  };
}

export async function verifyPayment(input: z.infer<typeof verifyPaymentSchema>) {
  const paymentResult = await query<{ booking_id: string; amount: string }>(
    `UPDATE payments
     SET provider_payment_id = $2,
         provider_order_id = COALESCE($3, provider_order_id),
         status = 'paid',
         signature_verified = $4,
         raw_response = $5
     WHERE id = $1
     RETURNING booking_id, amount`,
    [
      input.paymentId,
      input.providerPaymentId,
      input.providerOrderId ?? null,
      Boolean(input.signature),
      JSON.stringify({ providerPaymentId: input.providerPaymentId, providerOrderId: input.providerOrderId })
    ]
  );

  const payment = paymentResult.rows[0];
  if (!payment) {
    throw httpError(404, 'Payment not found');
  }

  await query("UPDATE bookings SET payment_status = 'paid' WHERE id = $1", [payment.booking_id]);

  await query(
    `INSERT INTO invoices (booking_id, invoice_number, subtotal, platform_fee, tax_amount, total)
     VALUES ($1, $2, $3, $4, $5, $6)
     ON CONFLICT (invoice_number) DO NOTHING`,
    [
      payment.booking_id,
      `C2F-${Date.now()}`,
      payment.amount,
      Math.round(Number(payment.amount) * 0.05),
      0,
      payment.amount
    ]
  );

  return { bookingId: payment.booking_id, status: 'paid' };
}

