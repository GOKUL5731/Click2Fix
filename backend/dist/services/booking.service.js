"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.completeBookingSchema = exports.createBookingSchema = void 0;
exports.createBooking = createBooking;
exports.getBookingHistory = getBookingHistory;
exports.getLiveLocation = getLiveLocation;
exports.completeBooking = completeBooking;
const bcryptjs_1 = __importDefault(require("bcryptjs"));
const zod_1 = require("zod");
const client_1 = require("../database/client");
const error_1 = require("../middleware/error");
const notification_service_1 = require("./notification.service");
exports.createBookingSchema = zod_1.z.object({
    issueId: zod_1.z.string().uuid(),
    workerId: zod_1.z.string().uuid(),
    quotationId: zod_1.z.string().uuid().optional()
});
exports.completeBookingSchema = zod_1.z.object({
    bookingId: zod_1.z.string().uuid(),
    completionOtp: zod_1.z.string().length(6).optional()
});
async function createBooking(userId, input) {
    const completionOtp = process.env.NODE_ENV === 'production' ? Math.floor(100000 + Math.random() * 900000).toString() : '432198';
    const completionOtpHash = await bcryptjs_1.default.hash(completionOtp, 12);
    const result = await (0, client_1.query)(`INSERT INTO bookings (issue_id, quotation_id, worker_id, user_id, booking_status, payment_status, completion_otp_hash)
     VALUES ($1, $2, $3, $4, 'confirmed', 'pending', $5)
     RETURNING *`, [input.issueId, input.quotationId ?? null, input.workerId, userId, completionOtpHash]);
    if (input.quotationId) {
        await (0, client_1.query)('UPDATE quotations SET is_selected = TRUE WHERE id = $1 AND issue_id = $2', [input.quotationId, input.issueId]);
    }
    await (0, client_1.query)("UPDATE issues SET status = 'booked' WHERE id = $1", [input.issueId]);
    void (0, notification_service_1.sendPushToActor)('worker', input.workerId, {
        title: 'New booking confirmed',
        message: 'A user confirmed your quote. Open the app to start navigation.',
        data: { bookingId: result.rows[0].id, issueId: input.issueId }
    });
    void (0, notification_service_1.sendPushToActor)('user', userId, {
        title: 'Booking confirmed',
        message: 'Your worker has been assigned. You can track live location now.',
        data: { bookingId: result.rows[0].id, workerId: input.workerId }
    });
    return {
        booking: result.rows[0],
        devCompletionOtp: process.env.NODE_ENV === 'production' ? undefined : completionOtp
    };
}
async function getBookingHistory(actorId, role) {
    const column = role === 'worker' ? 'worker_id' : 'user_id';
    const result = await (0, client_1.query)(`SELECT b.*, i.issue_type, i.description, i.urgency_level
     FROM bookings b
     JOIN issues i ON i.id = b.issue_id
     WHERE b.${column} = $1
     ORDER BY b.created_at DESC
     LIMIT 100`, [actorId]);
    return result.rows;
}
async function getLiveLocation(bookingId) {
    const booking = await (0, client_1.query)('SELECT worker_id FROM bookings WHERE id = $1', [bookingId]);
    const workerId = booking.rows[0]?.worker_id;
    if (!workerId) {
        throw (0, error_1.httpError)(404, 'Booking not found');
    }
    try {
        const live = await client_1.redis.get(`worker-location:${workerId}`);
        if (live)
            return JSON.parse(live);
    }
    catch {
        // Fall through to database snapshot.
    }
    const worker = await (0, client_1.query)('SELECT current_latitude AS latitude, current_longitude AS longitude FROM workers WHERE id = $1', [
        workerId
    ]);
    return worker.rows[0] ?? null;
}
async function completeBooking(input) {
    const booking = await (0, client_1.query)('SELECT completion_otp_hash FROM bookings WHERE id = $1', [input.bookingId]);
    if (!booking.rows[0]) {
        throw (0, error_1.httpError)(404, 'Booking not found');
    }
    if (input.completionOtp) {
        const valid = await bcryptjs_1.default.compare(input.completionOtp, booking.rows[0].completion_otp_hash);
        if (!valid) {
            throw (0, error_1.httpError)(401, 'Invalid completion OTP');
        }
    }
    const result = await (0, client_1.query)(`UPDATE bookings
     SET booking_status = 'completed', completed_at = NOW()
     WHERE id = $1
     RETURNING *`, [input.bookingId]);
    await (0, client_1.query)(`UPDATE issues
     SET status = 'completed'
     WHERE id = (SELECT issue_id FROM bookings WHERE id = $1)`, [input.bookingId]);
    const completedBooking = result.rows[0];
    void (0, notification_service_1.sendPushToActor)('user', completedBooking.user_id, {
        title: 'Booking completed',
        message: 'Your service has been marked as completed. Please add a review.',
        data: { bookingId: completedBooking.id }
    });
    void (0, notification_service_1.sendPushToActor)('worker', completedBooking.worker_id, {
        title: 'Job completed',
        message: 'Booking completed successfully. Check wallet and payout details.',
        data: { bookingId: completedBooking.id }
    });
    return completedBooking;
}
