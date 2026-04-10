"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.addReviewSchema = void 0;
exports.addReview = addReview;
const zod_1 = require("zod");
const client_1 = require("../database/client");
const error_1 = require("../middleware/error");
exports.addReviewSchema = zod_1.z.object({
    bookingId: zod_1.z.string().uuid(),
    workerId: zod_1.z.string().uuid(),
    rating: zod_1.z.number().int().min(1).max(5),
    comment: zod_1.z.string().max(1000).optional()
});
async function addReview(userId, input) {
    const booking = await (0, client_1.query)(`SELECT id FROM bookings
     WHERE id = $1 AND user_id = $2 AND worker_id = $3 AND booking_status = 'completed'`, [input.bookingId, userId, input.workerId]);
    if (!booking.rows[0]) {
        throw (0, error_1.httpError)(400, 'Booking must be completed before review');
    }
    const review = await (0, client_1.query)(`INSERT INTO reviews (booking_id, user_id, worker_id, rating, comment)
     VALUES ($1, $2, $3, $4, $5)
     ON CONFLICT (booking_id, user_id) DO UPDATE
     SET rating = EXCLUDED.rating,
         comment = EXCLUDED.comment
     RETURNING *`, [input.bookingId, userId, input.workerId, input.rating, input.comment ?? null]);
    await (0, client_1.query)(`UPDATE workers
     SET rating = sub.avg_rating,
         rating_count = sub.review_count,
         trust_score = LEAST(100, GREATEST(0, trust_score + (($2 - 3) * 2)))
     FROM (
       SELECT worker_id, AVG(rating)::numeric(3,2) AS avg_rating, COUNT(*)::int AS review_count
       FROM reviews
       WHERE worker_id = $1
       GROUP BY worker_id
     ) sub
     WHERE workers.id = sub.worker_id`, [input.workerId, input.rating]);
    return review.rows[0];
}
