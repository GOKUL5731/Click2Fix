"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.createApp = createApp;
const cors_1 = __importDefault(require("cors"));
const express_1 = __importDefault(require("express"));
const helmet_1 = __importDefault(require("helmet"));
const morgan_1 = __importDefault(require("morgan"));
const config_1 = require("./config");
const error_1 = require("./middleware/error");
const rateLimit_1 = require("./middleware/rateLimit");
const routes_1 = require("./routes");
const fs_1 = __importDefault(require("fs"));
function createApp() {
    const app = (0, express_1.default)();
    app.use((0, helmet_1.default)({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
    app.use((0, cors_1.default)({ origin: config_1.config.corsOrigins, credentials: true }));
    app.use(express_1.default.json({ limit: '2mb' }));
    app.use(express_1.default.urlencoded({ extended: true }));
    app.use((0, morgan_1.default)(config_1.config.nodeEnv === 'production' ? 'combined' : 'dev'));
    app.use(rateLimit_1.apiLimiter);
    // Ensure uploads directory exists and serve it statically
    fs_1.default.mkdirSync(config_1.config.uploadDir, { recursive: true });
    app.use('/uploads', express_1.default.static(config_1.config.uploadDir));
    app.get('/health', (_req, res) => {
        res.json({ status: 'ok', service: 'click2fix-backend' });
    });
    app.use('/api', routes_1.routes);
    app.use('/', routes_1.routes);
    app.use(error_1.notFoundHandler);
    app.use(error_1.errorHandler);
    return app;
}
