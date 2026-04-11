import { Pool, QueryResult, QueryResultRow } from 'pg';
import Redis from 'ioredis';
import { config } from '../config';

export const pool = new Pool({
  connectionString: config.databaseUrl.replace('sslmode=require', ''),
  ssl: config.nodeEnv === 'production' ? { rejectUnauthorized: false } : { rejectUnauthorized: false },
  max: 20,
  idleTimeoutMillis: 30000
});

export const redis = new Redis(config.redisUrl, {
  lazyConnect: true,
  maxRetriesPerRequest: 2,
  enableOfflineQueue: false
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
