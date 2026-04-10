"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.redis = exports.pool = void 0;
exports.query = query;
exports.healthCheck = healthCheck;
const pg_1 = require("pg");
const ioredis_1 = __importDefault(require("ioredis"));
const config_1 = require("../config");
exports.pool = new pg_1.Pool({
    connectionString: config_1.config.databaseUrl,
    max: 20,
    idleTimeoutMillis: 30000
});
exports.redis = new ioredis_1.default(config_1.config.redisUrl, {
    lazyConnect: true,
    maxRetriesPerRequest: 2
});
exports.redis.on('error', (error) => {
    if (config_1.config.nodeEnv !== 'test') {
        console.warn(`Redis unavailable: ${error.message}`);
    }
});
async function query(text, params = []) {
    return exports.pool.query(text, params);
}
async function healthCheck() {
    const db = await query('SELECT 1 AS ok');
    return { database: db.rows[0]?.ok === 1 };
}
