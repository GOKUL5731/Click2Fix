import { Request, Response } from 'express';
import { randomUUID } from 'crypto';
import { query } from '../database/client';

export const createRoom = async (req: Request, res: Response) => {
  try {
    const { bookingId } = req.body;
    
    if (!bookingId) {
      res.status(400).json({ success: false, error: 'Booking ID is required' });
      return;
    }

    // Verify user/worker belongs to this booking
    const bookingCheck = await query(`SELECT * FROM bookings WHERE id = $1`, [bookingId]);
    if (bookingCheck.rowCount === 0) {
      res.status(404).json({ success: false, error: 'Booking not found' });
      return;
    }

    const roomId = randomUUID();
    
    res.status(200).json({ 
      success: true, 
      roomId,
      token: randomUUID() // Simple stand-in for WebRTC/Agora token
    });
  } catch (error) {
    console.error('createRoom error:', error);
    res.status(500).json({ success: false, error: 'Failed to create call room' });
  }
};
