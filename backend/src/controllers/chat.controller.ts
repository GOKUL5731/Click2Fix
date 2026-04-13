import { Request, Response } from 'express';
import { query } from '../database/client';

export const getMessages = async (req: Request, res: Response) => {
  try {
    const { bookingId } = req.params;
    const result = await query(
      `SELECT * FROM chat_messages WHERE booking_id = $1 ORDER BY created_at ASC`,
      [bookingId]
    );

    res.status(200).json({ success: true, messages: result.rows });
  } catch (error) {
    console.error('getMessages error:', error);
    res.status(500).json({ success: false, error: 'Failed to retrieve messages' });
  }
};

export const sendMessage = async (req: Request, res: Response) => {
  try {
    const { bookingId, message, type = 'text' } = req.body;
    const senderId = (req as any).auth?.sub;
    const senderRole = (req as any).auth?.role;

    if (!senderId || !bookingId || !message) {
      res.status(400).json({ success: false, error: 'Missing required fields' });
      return;
    }

    // Verify booking exists
    const bookingCheck = await query(`SELECT id FROM bookings WHERE id = $1`, [bookingId]);
    if (bookingCheck.rowCount === 0) {
      res.status(404).json({ success: false, error: 'Booking not found' });
      return;
    }

    const { rows } = await query(
      `INSERT INTO chat_messages (booking_id, sender_id, sender_role, message) 
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [bookingId, senderId, senderRole, message]
    );

    res.status(201).json({ success: true, message: rows[0] });
  } catch (error) {
    console.error('sendMessage error:', error);
    res.status(500).json({ success: false, error: 'Failed to send message' });
  }
};
