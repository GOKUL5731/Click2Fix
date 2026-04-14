import { Pool, QueryResult, QueryResultRow } from 'pg';
import Redis from 'ioredis';
import { config } from '../config';

export const pool = new Pool({
  connectionString: config.databaseUrl,
  ssl: config.nodeEnv === 'production' ? { rejectUnauthorized: false } : undefined,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
});

pool.on('connect', () => {
  if (config.nodeEnv !== 'test') {
    console.log('Database pool connected successfully');
  }
});

pool.on('error', (err) => {
  console.error('Unexpected error on idle database client', err);
});

export const redis = new Redis(config.redisUrl, {
  lazyConnect: true,
  maxRetriesPerRequest: 2,
  enableOfflineQueue: false,
  retryStrategy: (times) => Math.min(times * 50, 2000),
});

redis.on('error', (error) => {
  if (config.nodeEnv !== 'test') {
    console.warn(`Redis unavailable: ${error.message}`);
  }
});

export async function query<T extends QueryResultRow = QueryResultRow>(
  text: string,
  params: unknown[] = []
): Promise<QueryResult<T>> {
  return pool.query<T>(text, params);
}

export async function healthCheck() {
  const db = await query<{ ok: number }>('SELECT 1 AS ok');
  return { database: db.rows[0]?.ok === 1 };
}
