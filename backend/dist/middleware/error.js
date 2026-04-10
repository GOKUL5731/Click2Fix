"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.HttpError = void 0;
exports.httpError = httpError;
exports.asyncHandler = asyncHandler;
exports.notFoundHandler = notFoundHandler;
exports.errorHandler = errorHandler;
class HttpError extends Error {
    statusCode;
    details;
    constructor(statusCode, message, details) {
        super(message);
        this.statusCode = statusCode;
        this.details = details;
    }
}
exports.HttpError = HttpError;
function httpError(statusCode, message, details) {
    return new HttpError(statusCode, message, details);
}
function asyncHandler(handler) {
    return (req, res, next) => {
        Promise.resolve(handler(req, res, next)).catch(next);
    };
}
function notFoundHandler(req, _res, next) {
    next(httpError(404, `Route not found: ${req.method} ${req.originalUrl}`));
}
function errorHandler(error, _req, res, _next) {
    if (error instanceof HttpError) {
        res.status(error.statusCode).json({
            error: {
                message: error.message,
                details: error.details
            }
        });
        return;
    }
    const message = error instanceof Error ? error.message : 'Unexpected server error';
    res.status(500).json({ error: { message } });
}
