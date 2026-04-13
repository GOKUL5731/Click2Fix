import { Request, Response } from 'express';
import { query } from '../database/client';

export const updateLocation = async (req: Request, res: Response) => {
  try {
    const { bookingId, lat, lng } = req.body;
    const role = (req as any).auth?.role;

    if (!bookingId || lat === undefined || lng === undefined) {
      res.status(400).json({ success: false, error: 'Missing required fields' });
      return;
    }

    // Upsert logic for booking_locations
    if (role === 'user') {
      await query(`
        INSERT INTO booking_locations (booking_id, user_lat, user_lng) 
        VALUES ($1, $2, $3)
        ON CONFLICT (booking_id) 
        DO UPDATE SET user_lat = EXCLUDED.user_lat, user_lng = EXCLUDED.user_lng, updated_at = NOW()
      `, [bookingId, lat, lng]);
    } else if (role === 'worker') {
      await query(`
        INSERT INTO booking_locations (booking_id, worker_lat, worker_lng) 
        VALUES ($1, $2, $3)
        ON CONFLICT (booking_id) 
        DO UPDATE SET worker_lat = EXCLUDED.worker_lat, worker_lng = EXCLUDED.worker_lng, updated_at = NOW()
      `, [bookingId, lat, lng]);

      // also update worker's general location
      const workerId = (req as any).auth?.sub;
      if (workerId) {
         await query(`UPDATE workers SET current_latitude = $1, current_longitude = $2 WHERE id = $3`, [lat, lng, workerId]);
      }
    }

    res.status(200).json({ success: true });
  } catch (error) {
    console.error('updateLocation error:', error);
    res.status(500).json({ success: false, error: 'Failed to update location' });
  }
};

export const getBookingLocation = async (req: Request, res: Response) => {
  try {
    const { bookingId } = req.params;
    const { rows } = await query(
      `SELECT * FROM booking_locations WHERE booking_id = $1`,
      [bookingId]
    );

    if (rows.length === 0) {
      res.status(404).json({ success: false, error: 'Location data not found' });
      return;
    }

    res.status(200).json({ success: true, data: rows[0] });
  } catch (error) {
    console.error('getBookingLocation error:', error);
    res.status(500).json({ success: false, error: 'Failed to retrieve location' });
  }
};
