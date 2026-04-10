"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.uploadDocumentSchema = exports.setAvailabilitySchema = exports.updateLocationSchema = exports.sendQuoteSchema = exports.nearbyWorkerQuerySchema = void 0;
exports.findNearbyWorkers = findNearbyWorkers;
exports.sendQuote = sendQuote;
exports.updateWorkerLocation = updateWorkerLocation;
exports.setWorkerAvailability = setWorkerAvailability;
exports.uploadWorkerDocument = uploadWorkerDocument;
exports.getWorkerProfile = getWorkerProfile;
exports.getQuotationsForIssue = getQuotationsForIssue;
const zod_1 = require("zod");
const client_1 = require("../database/client");
const error_1 = require("../middleware/error");
const notification_service_1 = require("./notification.service");
const config_1 = require("../config");
exports.nearbyWorkerQuerySchema = zod_1.z.object({
    issueId: zod_1.z.string().uuid().optional(),
    latitude: zod_1.z.coerce.number().optional(),
    longitude: zod_1.z.coerce.number().optional(),
    category: zod_1.z.string().optional(),
    radiusKm: zod_1.z.coerce.number().min(1).max(25).default(5)
});
exports.sendQuoteSchema = zod_1.z.object({
    issueId: zod_1.z.string().uuid(),
    price: zod_1.z.number().nonnegative(),
    estimatedTime: zod_1.z.number().int().positive().optional(),
    arrivalTime: zod_1.z.string().datetime().optional(),
    message: zod_1.z.string().max(500).optional()
});
exports.updateLocationSchema = zod_1.z.object({
    latitude: zod_1.z.number(),
    longitude: zod_1.z.number()
});
exports.setAvailabilitySchema = zod_1.z.object({
    availability: zod_1.z.boolean()
});
exports.uploadDocumentSchema = zod_1.z.object({
    documentType: zod_1.z.enum(['certificate', 'aadhaar', 'license', 'identity']),
    fileUrl: zod_1.z.string(),
});
async function findNearbyWorkers(input) {
    let latitude = input.latitude;
    let longitude = input.longitude;
    let category = input.category;
    if (input.issueId) {
        const issue = await (0, client_1.query)('SELECT latitude, longitude, issue_type FROM issues WHERE id = $1', [input.issueId]);
        if (!issue.rows[0]) {
            throw (0, error_1.httpError)(404, 'Issue not found');
        }
        latitude = Number(issue.rows[0].latitude);
        longitude = Number(issue.rows[0].longitude);
        category = category ?? issue.rows[0].issue_type ?? undefined;
    }
    if (latitude === undefined || longitude === undefined) {
        throw (0, error_1.httpError)(400, 'Latitude and longitude are required');
    }
    const result = await (0, client_1.query)(`SELECT *
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
     LIMIT 50`, [latitude, longitude, input.radiusKm, category ?? null]);
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
async function sendQuote(workerId, input) {
    const issue = await (0, client_1.query)('SELECT id, status, user_id, is_emergency FROM issues WHERE id = $1', [input.issueId]);
    if (!issue.rows[0]) {
        throw (0, error_1.httpError)(404, 'Issue not found');
    }
    // For emergency issues, apply dynamic pricing multiplier as suggestion
    let adjustedPrice = input.price;
    if (issue.rows[0].is_emergency && adjustedPrice > 0) {
        const minEmergencyPrice = adjustedPrice * config_1.config.emergencyPriceMultiplier;
        if (adjustedPrice < minEmergencyPrice) {
            adjustedPrice = Math.round(minEmergencyPrice);
        }
    }
    const result = await (0, client_1.query)(`INSERT INTO quotations (issue_id, worker_id, price, estimated_time, arrival_time, message)
     VALUES ($1, $2, $3, $4, $5, $6)
     ON CONFLICT (issue_id, worker_id) DO UPDATE
     SET price = EXCLUDED.price,
         estimated_time = EXCLUDED.estimated_time,
         arrival_time = EXCLUDED.arrival_time,
         message = EXCLUDED.message
     RETURNING *`, [input.issueId, workerId, adjustedPrice, input.estimatedTime ?? null, input.arrivalTime ?? null, input.message ?? null]);
    await (0, client_1.query)("UPDATE issues SET status = 'quoted' WHERE id = $1", [input.issueId]);
    void (0, notification_service_1.sendPushToActor)('user', issue.rows[0].user_id, {
        title: 'New worker quote received',
        message: `A worker has sent a quote of ₹${adjustedPrice} for your issue. Compare and confirm booking.`,
        data: { issueId: input.issueId, workerId }
    });
    return result.rows[0];
}
async function updateWorkerLocation(workerId, input) {
    await (0, client_1.query)('UPDATE workers SET current_latitude = $1, current_longitude = $2 WHERE id = $3', [
        input.latitude,
        input.longitude,
        workerId
    ]);
    try {
        await client_1.redis.set(`worker-location:${workerId}`, JSON.stringify({ latitude: input.latitude, longitude: input.longitude, updatedAt: new Date().toISOString() }), 'EX', 120);
    }
    catch {
        // Database update already persisted the latest known location.
    }
    return { workerId, ...input };
}
async function setWorkerAvailability(workerId, input) {
    const result = await (0, client_1.query)('UPDATE workers SET availability = $1 WHERE id = $2 RETURNING id, availability', [
        input.availability,
        workerId
    ]);
    return result.rows[0];
}
async function uploadWorkerDocument(workerId, input) {
    const result = await (0, client_1.query)(`INSERT INTO worker_documents (worker_id, document_type, file_url, status)
     VALUES ($1, $2, $3, 'pending')
     RETURNING *`, [workerId, input.documentType, input.fileUrl]);
    return result.rows[0];
}
async function getWorkerProfile(workerId) {
    const worker = await (0, client_1.query)(`SELECT w.*, 
       (SELECT json_agg(json_build_object('id', wd.id, 'document_type', wd.document_type, 'file_url', wd.file_url, 'status', wd.status))
        FROM worker_documents wd WHERE wd.worker_id = w.id) AS documents,
       (SELECT json_agg(json_build_object('category_id', ws.category_id, 'name', c.name))
        FROM worker_skills ws JOIN categories c ON c.id = ws.category_id WHERE ws.worker_id = w.id) AS skills
     FROM workers w WHERE w.id = $1`, [workerId]);
    return worker.rows[0] ?? null;
}
async function getQuotationsForIssue(issueId) {
    const result = await (0, client_1.query)(`SELECT q.*, w.name AS worker_name, w.rating AS worker_rating, w.trust_score AS worker_trust_score,
            w.current_latitude, w.current_longitude
     FROM quotations q
     JOIN workers w ON w.id = q.worker_id
     WHERE q.issue_id = $1
     ORDER BY q.price ASC`, [issueId]);
    return result.rows;
}
