"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.reviewDocumentSchema = exports.approveWorkerSchema = void 0;
exports.getDashboard = getDashboard;
exports.getPendingWorkers = getPendingWorkers;
exports.approveWorker = approveWorker;
exports.reviewDocument = reviewDocument;
exports.getSystemActivity = getSystemActivity;
exports.getAllBookings = getAllBookings;
const zod_1 = require("zod");
const client_1 = require("../database/client");
const error_1 = require("../middleware/error");
exports.approveWorkerSchema = zod_1.z.object({
    workerId: zod_1.z.string().uuid(),
    approved: zod_1.z.boolean(),
    notes: zod_1.z.string().max(1000).optional()
});
exports.reviewDocumentSchema = zod_1.z.object({
    documentId: zod_1.z.string().uuid(),
    approved: zod_1.z.boolean(),
    notes: zod_1.z.string().max(1000).optional()
});
async function getDashboard() {
    const [users, workers, activeBookings, emergencies, revenue, fraudAlerts, pendingWorkers, completedJobs] = await Promise.all([
        (0, client_1.query)('SELECT COUNT(*) FROM users'),
        (0, client_1.query)('SELECT COUNT(*) FROM workers'),
        (0, client_1.query)("SELECT COUNT(*) FROM bookings WHERE booking_status IN ('confirmed', 'worker_on_way', 'arrived', 'work_started')"),
        (0, client_1.query)("SELECT COUNT(*) FROM issues WHERE is_emergency = TRUE AND status NOT IN ('completed', 'cancelled')"),
        (0, client_1.query)("SELECT COALESCE(SUM(amount), 0) AS total FROM payments WHERE status = 'paid'"),
        (0, client_1.query)("SELECT COUNT(*) FROM fraud_alerts WHERE status = 'open'"),
        (0, client_1.query)("SELECT COUNT(*) FROM workers WHERE verification_status = 'pending'"),
        (0, client_1.query)("SELECT COUNT(*) FROM bookings WHERE booking_status = 'completed'"),
    ]);
    // Recent activity for charts
    const dailyBookings = await (0, client_1.query)(`SELECT DATE(created_at) AS day, COUNT(*) AS count 
     FROM bookings WHERE created_at > NOW() - INTERVAL '30 days'
     GROUP BY DATE(created_at) ORDER BY day`);
    const categoryBreakdown = await (0, client_1.query)(`SELECT issue_type, COUNT(*) AS count FROM issues 
     WHERE created_at > NOW() - INTERVAL '30 days' AND issue_type IS NOT NULL
     GROUP BY issue_type ORDER BY count DESC LIMIT 10`);
    return {
        totalUsers: Number(users.rows[0].count),
        totalWorkers: Number(workers.rows[0].count),
        activeBookings: Number(activeBookings.rows[0].count),
        completedJobs: Number(completedJobs.rows[0].count),
        emergencyRequests: Number(emergencies.rows[0].count),
        totalRevenue: Number(revenue.rows[0].total),
        fraudAlerts: Number(fraudAlerts.rows[0].count),
        workerApprovalQueue: Number(pendingWorkers.rows[0].count),
        charts: {
            dailyBookings: dailyBookings.rows.map(r => ({ day: r.day, count: Number(r.count) })),
            categoryBreakdown: categoryBreakdown.rows.map(r => ({ category: r.issue_type, count: Number(r.count) })),
        }
    };
}
async function getPendingWorkers() {
    const result = await (0, client_1.query)(`SELECT w.id, w.name, w.phone, w.category, w.experience, w.aadhaar_verified, w.face_verified, w.trust_score, w.created_at,
       (SELECT json_agg(json_build_object('id', wd.id, 'document_type', wd.document_type, 'file_url', wd.file_url, 'status', wd.status))
        FROM worker_documents wd WHERE wd.worker_id = w.id) AS documents
     FROM workers w
     WHERE w.verification_status = 'pending'
     ORDER BY w.created_at ASC
     LIMIT 100`);
    return result.rows;
}
async function approveWorker(input, adminId) {
    const status = input.approved ? 'approved' : 'rejected';
    const result = await (0, client_1.query)(`UPDATE workers
     SET verification_status = $2,
         aadhaar_verified = CASE WHEN $2 = 'approved' THEN TRUE ELSE aadhaar_verified END,
         face_verified = CASE WHEN $2 = 'approved' THEN TRUE ELSE face_verified END,
         trust_score = CASE WHEN $2 = 'approved' THEN GREATEST(trust_score, 70) ELSE trust_score END
     WHERE id = $1
     RETURNING *`, [input.workerId, status]);
    if (!result.rows[0]) {
        throw (0, error_1.httpError)(404, 'Worker not found');
    }
    await (0, client_1.query)(`INSERT INTO audit_logs (actor_role, actor_id, action, entity_type, entity_id, metadata)
     VALUES ('admin', $1, $2, 'worker', $3, $4)`, [adminId ?? null, input.approved ? 'approve_worker' : 'reject_worker', input.workerId, JSON.stringify({ notes: input.notes })]);
    return result.rows[0];
}
async function reviewDocument(input, adminId) {
    const status = input.approved ? 'approved' : 'rejected';
    const result = await (0, client_1.query)(`UPDATE worker_documents 
     SET status = $2, review_notes = $3, reviewed_by = $4, reviewed_at = NOW()
     WHERE id = $1
     RETURNING *`, [input.documentId, status, input.notes ?? null, adminId ?? null]);
    if (!result.rows[0]) {
        throw (0, error_1.httpError)(404, 'Document not found');
    }
    await (0, client_1.query)(`INSERT INTO audit_logs (actor_role, actor_id, action, entity_type, entity_id, metadata)
     VALUES ('admin', $1, $2, 'worker_document', $3, $4)`, [adminId ?? null, input.approved ? 'approve_document' : 'reject_document', input.documentId, JSON.stringify({ notes: input.notes })]);
    return result.rows[0];
}
async function getSystemActivity(limit = 50) {
    const result = await (0, client_1.query)(`SELECT * FROM audit_logs ORDER BY created_at DESC LIMIT $1`, [limit]);
    return result.rows;
}
async function getAllBookings(limit = 100) {
    const result = await (0, client_1.query)(`SELECT b.*, i.issue_type, i.description, i.urgency_level, i.is_emergency,
            u.name AS user_name, u.phone AS user_phone,
            w.name AS worker_name, w.phone AS worker_phone
     FROM bookings b
     JOIN issues i ON i.id = b.issue_id
     JOIN users u ON u.id = b.user_id
     JOIN workers w ON w.id = b.worker_id
     ORDER BY b.created_at DESC
     LIMIT $1`, [limit]);
    return result.rows;
}
