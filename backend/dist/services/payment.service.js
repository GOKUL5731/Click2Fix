"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.verifyPaymentSchema = exports.paySchema = void 0;
exports.createPayment = createPayment;
exports.verifyPayment = verifyPayment;
const zod_1 = require("zod");
const client_1 = require("../database/client");
const error_1 = require("../middleware/error");
exports.paySchema = zod_1.z.object({
    bookingId: zod_1.z.string().uuid(),
    amount: zod_1.z.number().nonnegative(),
    provider: zod_1.z.enum(['razorpay', 'upi', 'stripe']).default('razorpay')
});
exports.verifyPaymentSchema = zod_1.z.object({
    paymentId: zod_1.z.string().uuid(),
    providerPaymentId: zod_1.z.string().min(3),
    providerOrderId: zod_1.z.string().optional(),
    signature: zod_1.z.string().optional()
});
async function createPayment(input) {
    const booking = await (0, client_1.query)('SELECT id FROM bookings WHERE id = $1', [input.bookingId]);
    if (!booking.rows[0]) {
        throw (0, error_1.httpError)(404, 'Booking not found');
    }
    const providerOrderId = `order_${Date.now()}`;
    const result = await (0, client_1.query)(`INSERT INTO payments (booking_id, provider, provider_order_id, amount, status)
     VALUES ($1, $2, $3, $4, 'authorized')
     RETURNING *`, [input.bookingId, input.provider, providerOrderId, input.amount]);
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
async function verifyPayment(input) {
    const paymentResult = await (0, client_1.query)(`UPDATE payments
     SET provider_payment_id = $2,
         provider_order_id = COALESCE($3, provider_order_id),
         status = 'paid',
         signature_verified = $4,
         raw_response = $5
     WHERE id = $1
     RETURNING booking_id, amount`, [
        input.paymentId,
        input.providerPaymentId,
        input.providerOrderId ?? null,
        Boolean(input.signature),
        JSON.stringify({ providerPaymentId: input.providerPaymentId, providerOrderId: input.providerOrderId })
    ]);
    const payment = paymentResult.rows[0];
    if (!payment) {
        throw (0, error_1.httpError)(404, 'Payment not found');
    }
    await (0, client_1.query)("UPDATE bookings SET payment_status = 'paid' WHERE id = $1", [payment.booking_id]);
    await (0, client_1.query)(`INSERT INTO invoices (booking_id, invoice_number, subtotal, platform_fee, tax_amount, total)
     VALUES ($1, $2, $3, $4, $5, $6)
     ON CONFLICT (invoice_number) DO NOTHING`, [
        payment.booking_id,
        `C2F-${Date.now()}`,
        payment.amount,
        Math.round(Number(payment.amount) * 0.05),
        0,
        payment.amount
    ]);
    return { bookingId: payment.booking_id, status: 'paid' };
}
