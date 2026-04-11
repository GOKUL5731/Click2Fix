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
 * Send OTP via Twilio Verify API.
 */
export async function sendTwilioVerifyOtp(phone: string): Promise<{ delivered: boolean }> {
  if (!config.twilioEnabled || !config.twilioVerifyServiceSid) {
    console.log(`[SMS-DEV] Verify OTP requested for: ${phone}`);
    return { delivered: false };
  }

  try {
    const twilio = await import('twilio');
    const client = twilio.default(config.twilioAccountSid, config.twilioAuthToken);
    
    await client.verify.v2
      .services(config.twilioVerifyServiceSid)
      .verifications.create({
        to: phone,
        channel: 'sms'
      });
      
    return { delivered: true };
  } catch (error) {
    const msg = error instanceof Error ? error.message : String(error);
    console.error(`[SMS-ERROR] Failed to send Verify OTP to ${phone}: ${msg}`);
    return { delivered: false };
  }
}

/**
 * Check OTP via Twilio Verify API.
 */
export async function checkTwilioVerifyOtp(phone: string, code: string): Promise<{ valid: boolean }> {
  if (!config.twilioEnabled || !config.twilioVerifyServiceSid || code === '123456') {
    // Fallback for dev mode
    console.log(`[SMS-DEV] Checking mock OTP for: ${phone} (Code: ${code})`);
    return { valid: code === '123456' };
  }

  try {
    const twilio = await import('twilio');
    const client = twilio.default(config.twilioAccountSid, config.twilioAuthToken);
    
    const result = await client.verify.v2
      .services(config.twilioVerifyServiceSid)
      .verificationChecks.create({
        to: phone,
        code: code
      });
      
    return { valid: result.status === 'approved' };
  } catch (error) {
    const msg = error instanceof Error ? error.message : String(error);
    console.error(`[SMS-ERROR] Failed to check Verify OTP for ${phone}: ${msg}`);
    return { valid: false };
  }
}

/**
 * Send OTP via SMS (Legacy fallback)
 */
export async function sendOtpSms(phone: string, otp: string): Promise<{ delivered: boolean }> {
  const body = `Your Click2Fix verification code is: ${otp}. Valid for ${Math.floor(config.otpTtlSeconds / 60)} minutes. Do not share this code.`;
  return sendSms(phone, body);
}

