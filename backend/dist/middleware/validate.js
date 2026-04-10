"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.validateBody = validateBody;
exports.validateQuery = validateQuery;
const error_1 = require("./error");
function validateBody(schema) {
    return (req, _res, next) => {
        const parsed = schema.safeParse(req.body);
        if (!parsed.success) {
            next((0, error_1.httpError)(400, 'Invalid request body', parsed.error.flatten()));
            return;
        }
        req.body = parsed.data;
        next();
    };
}
function validateQuery(schema) {
    return (req, _res, next) => {
        const parsed = schema.safeParse(req.query);
        if (!parsed.success) {
            next((0, error_1.httpError)(400, 'Invalid query parameters', parsed.error.flatten()));
            return;
        }
        req.query = parsed.data;
        next();
    };
}
