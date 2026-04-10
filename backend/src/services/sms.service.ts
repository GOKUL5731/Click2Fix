import { config } from '../config';

/**
 * Send an SMS message. Uses Twilio when configured, otherwise logs to console
 * for development/demo mode.
 */
export async function sendSms(to: string, body: string): Promise<{ delivered: boolean; sid?: string }> {
  if (!config.twilioEnabled) {
    console.log(`[SMS-DEV] To: ${to} | Body: ${body}`);
    return { delivered: false };
  }

  try {
    // Dynamic import so the app doesn't crash if twilio package isn't installed
    const twilio = await import('twilio');
    const client = twilio.default(config.twilioAccountSid, config.twilioAuthToken);

    const message = await client.messages.create({
      body,
      from: config.twilioPhoneNumber,
      to,
    });

    return { delivered: true, sid: message.sid };
  } catch (error) {
    const msg = error instanceof Error ? error.message : String(error);
    console.error(`[SMS-ERROR] Failed to send SMS to ${to}: ${msg}`);
    return { delivered: false };
  }
}

/**
 * Send OTP via SMS.
 */
export async function sendOtpSms(phone: string, otp: string): Promise<{ delivered: boolean }> {
  const body = `Your Click2Fix verification code is: ${otp}. Valid for ${Math.floor(config.otpTtlSeconds / 60)} minutes. Do not share this code.`;
  return sendSms(phone, body);
}
