"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendSms = sendSms;
exports.sendOtpSms = sendOtpSms;
const config_1 = require("../config");
/**
 * Send an SMS message. Uses Twilio when configured, otherwise logs to console
 * for development/demo mode.
 */
async function sendSms(to, body) {
    if (!config_1.config.twilioEnabled) {
        console.log(`[SMS-DEV] To: ${to} | Body: ${body}`);
        return { delivered: false };
    }
    try {
        // Dynamic import so the app doesn't crash if twilio package isn't installed
        const twilio = await Promise.resolve().then(() => __importStar(require('twilio')));
        const client = twilio.default(config_1.config.twilioAccountSid, config_1.config.twilioAuthToken);
        const message = await client.messages.create({
            body,
            from: config_1.config.twilioPhoneNumber,
            to,
        });
        return { delivered: true, sid: message.sid };
    }
    catch (error) {
        const msg = error instanceof Error ? error.message : String(error);
        console.error(`[SMS-ERROR] Failed to send SMS to ${to}: ${msg}`);
        return { delivered: false };
    }
}
/**
 * Send OTP via SMS.
 */
async function sendOtpSms(phone, otp) {
    const body = `Your Click2Fix verification code is: ${otp}. Valid for ${Math.floor(config_1.config.otpTtlSeconds / 60)} minutes. Do not share this code.`;
    return sendSms(phone, body);
}
